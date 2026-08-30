<?php

namespace App\Http\Controllers\Admin;

use App\Domain\Audit\Auditor;
use App\Http\Controllers\Controller;
use App\Jobs\ComputeMatchesJob;
use App\Models\ItemReport;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Inertia\Response;

class ReportAdminController extends Controller
{
    public function review(Request $request): Response
    {
        return $this->index($request, null, 'Admin/Listings/Review', ['submitted', 'under_review']);
    }

    public function lost(Request $request): Response
    {
        return $this->index($request, 'lost', 'Admin/Reports/Lost');
    }

    public function found(Request $request): Response
    {
        return $this->index($request, 'found', 'Admin/Reports/Found');
    }

    public function show(ItemReport $report): Response
    {
        $report->load(['user', 'category', 'hub', 'media', 'claims.claimant', 'lostMatches.found', 'foundMatches.lost']);

        return Inertia::render('Admin/Reports/Show', [
            'report' => $report->toFullDto(request()->user()) + [
                'hidden_notes' => $report->hidden_notes,
                'serial' => $report->serial,
                'lat' => $report->lat,
                'lng' => $report->lng,
                'storage_code' => $report->storage_code,
                'user' => $report->user?->toPrivateDto(),
                'claims' => $report->claims,
                'matches' => $report->isLost() ? $report->lostMatches : $report->foundMatches,
                'media' => $report->media,
            ],
        ]);
    }

    public function decide(Request $request, ItemReport $report): RedirectResponse
    {
        $data = $request->validate([
            'action' => ['required', 'in:approve,reject,request_changes'],
            'reason' => ['required', 'string', 'max:500'],
        ]);

        $status = match ($data['action']) {
            'approve' => 'published',
            'reject' => 'rejected',
            default => 'under_review',
        };

        $report->update(['status' => $status, 'moderation_reason' => $data['reason']]);
        Auditor::record('report.moderate', $report, $data, $request->user());

        if ($status === 'published') {
            ComputeMatchesJob::dispatch($report->id);
        }

        return back()->with('success', 'Listing updated.');
    }

    private function index(Request $request, ?string $type, string $page, ?array $statuses = null): Response
    {
        $query = ItemReport::query()->with(['category', 'user', 'hub']);
        if ($type) {
            $query->where('type', $type);
        }
        if ($statuses) {
            $query->whereIn('status', $statuses);
        }
        if ($request->filled('status')) {
            $query->where('status', $request->string('status'));
        }
        if ($request->filled('category_id')) {
            $query->where('category_id', $request->integer('category_id'));
        }
        if ($request->filled('q')) {
            $q = '%'.$request->string('q').'%';
            $query->where(fn ($b) => $b->where('title', 'like', $q)->orWhere('area', 'like', $q)->orWhere('serial', 'like', $q));
        }

        $rows = $query->latest()->paginate(20)->withQueryString();

        return Inertia::render($page, [
            'filters' => $request->only(['q', 'status', 'category_id']),
            'reports' => $rows->through(fn (ItemReport $r) => [
                'id' => $r->id,
                'title' => $r->title,
                'type' => $r->type,
                'status' => $r->status,
                'area' => $r->area,
                'category' => $r->category?->name,
                'reporter' => $r->user?->display_name,
                'trust' => $r->user?->trust_score,
                'hub' => $r->hub?->name,
                'custody' => $r->custody,
                'storage_code' => $r->storage_code,
                'created_at' => $r->created_at?->toDateTimeString(),
            ]),
        ]);
    }
}
