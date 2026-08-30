<?php

namespace App\Http\Controllers\Api\V1;

use App\Domain\Audit\Auditor;
use App\Domain\Geo\GeoHash;
use App\Domain\Search\SearchEngine;
use App\Http\Controllers\Controller;
use App\Jobs\ComputeMatchesJob;
use App\Models\ItemReport;
use App\Models\MediaAsset;
use App\Models\Setting;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Rule;

class ReportController extends Controller
{
    public function index(Request $request, SearchEngine $search): JsonResponse
    {
        $paginator = $search->search($request->only(['q', 'type', 'category_id', 'status', 'lat', 'lng', 'radius']));

        return response()->json([
            'data' => $paginator->getCollection()->map->toTeaserDto()->values(),
            'meta' => [
                'current_page' => $paginator->currentPage(),
                'last_page' => $paginator->lastPage(),
                'total' => $paginator->total(),
            ],
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $this->authorize('create', ItemReport::class);
        $data = $this->validated($request);
        $user = $request->user();

        if (! empty($data['lat']) && ! empty($data['lng'])) {
            $data['geohash'] = GeoHash::encode((float) $data['lat'], (float) $data['lng']);
        }

        $data['user_id'] = $user->id;
        $data['attributes_json'] = $data['attributes'] ?? [];
        unset($data['attributes']);
        $data['status'] = 'draft';
        $data['area'] = $data['area'] ?? $this->coarseArea($data['place_name'] ?? null);

        $report = ItemReport::query()->create($data);

        return response()->json(['data' => $report->fresh(['category', 'hub', 'media'])->toFullDto($user)], 201);
    }

    public function show(Request $request, ItemReport $report): JsonResponse
    {
        $this->authorize('view', $report);
        $report->load(['category', 'hub', 'media', 'user']);
        $user = $request->user();
        $full = $user && (
            $user->id === $report->user_id
            || $user->canAccessHiddenFields()
            || $report->hasApprovedClaimant($user)
            || $report->viewerIsHubStaff($user)
        );

        return response()->json([
            'data' => $full ? $report->toFullDto($user) : $report->toTeaserDto(),
        ]);
    }

    public function update(Request $request, ItemReport $report): JsonResponse
    {
        $this->authorize('update', $report);
        $data = $this->validated($request, true);
        if (! empty($data['lat']) && ! empty($data['lng'])) {
            $data['geohash'] = GeoHash::encode((float) $data['lat'], (float) $data['lng']);
        }
        if (isset($data['attributes'])) {
            $data['attributes_json'] = $data['attributes'];
            unset($data['attributes']);
        }
        $report->update($data);

        return response()->json(['data' => $report->fresh(['category', 'hub', 'media'])->toFullDto($request->user())]);
    }

    public function submit(Request $request, ItemReport $report): JsonResponse
    {
        $this->authorize('submit', $report);
        $sensitive = $report->category?->sensitivity === 'highly_sensitive';
        $report->update(['status' => $sensitive ? 'under_review' : 'published']);
        Auditor::record('report.submit', $report, ['status' => $report->status], $request->user());
        ComputeMatchesJob::dispatch($report->id);

        return response()->json(['data' => $report->fresh(['category', 'hub', 'media'])->toFullDto($request->user())]);
    }

    public function close(Request $request, ItemReport $report): JsonResponse
    {
        $this->authorize('close', $report);
        $report->update(['status' => 'closed', 'moderation_reason' => $request->input('reason')]);
        Auditor::record('report.close', $report, [], $request->user());

        return response()->json(['data' => $report->fresh()->toFullDto($request->user())]);
    }

    public function matches(Request $request, ItemReport $report): JsonResponse
    {
        $this->authorize('viewMatches', $report);
        $matches = $report->isLost() ? $report->lostMatches() : $report->foundMatches();
        $rows = $matches->with(['lost.category', 'found.category', 'lost.hub', 'found.hub', 'lost.media', 'found.media'])->orderByDesc('score')->get();

        return response()->json([
            'data' => $rows->map(fn ($m) => [
                'id' => $m->id,
                'score' => $m->score,
                'status' => $m->status,
                'reasons' => $m->reasons_json,
                'lost' => $m->lost?->toTeaserDto(),
                'found' => $m->found?->toTeaserDto(),
            ]),
        ]);
    }

    public function media(Request $request, ItemReport $report): JsonResponse
    {
        $this->authorize('uploadMedia', $report);
        $request->validate([
            'file' => ['required', 'image', 'max:8192'],
            'visibility' => ['nullable', Rule::in(['public', 'private'])],
        ]);

        $count = $report->media()->count();
        abort_if($count >= 6, 422, 'Maximum 6 photos per report.');

        $path = $request->file('file')->store('reports/'.$report->id, 'public');
        $asset = MediaAsset::query()->create([
            'report_id' => $report->id,
            'path' => $path,
            'variant' => 'original',
            'visibility' => $request->input('visibility', 'public'),
            'mime' => $request->file('file')->getMimeType(),
            'size' => $request->file('file')->getSize() ?? 0,
        ]);

        return response()->json(['data' => [
            'id' => $asset->id,
            'url' => $asset->publicUrl(),
            'visibility' => $asset->visibility,
        ]], 201);
    }

    /**
     * @return array<string, mixed>
     */
    private function validated(Request $request, bool $partial = false): array
    {
        $required = $partial ? 'sometimes' : 'required';

        return $request->validate([
            'type' => [$required, Rule::in(['lost', 'found'])],
            'title' => [$required, 'string', 'max:160'],
            'category_id' => [$required, 'exists:categories,id'],
            'description' => ['nullable', 'string'],
            'hidden_notes' => ['nullable', 'string'],
            'serial' => ['nullable', 'string', 'max:120'],
            'attributes' => ['nullable', 'array'],
            'lat' => ['nullable', 'numeric'],
            'lng' => ['nullable', 'numeric'],
            'place_name' => ['nullable', 'string', 'max:190'],
            'area' => ['nullable', 'string', 'max:190'],
            'occurred_at' => ['nullable', 'date'],
            'custody' => ['nullable', Rule::in(['with_finder', 'at_hub', 'with_staff'])],
            'hub_id' => ['nullable', 'exists:hubs,id'],
            'storage_code' => ['nullable', 'string', 'max:40'],
            'condition' => ['nullable', 'string', 'max:80'],
            'reward_note' => ['nullable', 'string', 'max:190'],
            'visibility' => ['nullable', Rule::in(['public_teaser', 'private_match_only'])],
        ]);
    }

    private function coarseArea(?string $place): ?string
    {
        if (! $place) {
            return null;
        }

        $parts = array_map('trim', explode(',', $place));

        return $parts[0] ?? $place;
    }
}
