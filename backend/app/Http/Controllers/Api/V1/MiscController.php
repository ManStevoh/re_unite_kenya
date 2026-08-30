<?php

namespace App\Http\Controllers\Api\V1;

use App\Domain\Search\SearchEngine;
use App\Http\Controllers\Controller;
use App\Models\Flag;
use App\Models\QrTag;
use App\Models\Tip;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class MiscController extends Controller
{
    public function notifications(Request $request): JsonResponse
    {
        $rows = $request->user()->notifications()->latest()->paginate(20);

        return response()->json([
            'data' => $rows->map(fn ($n) => [
                'id' => $n->id,
                'type' => $n->data['event'] ?? $n->type,
                'title' => $n->data['title'] ?? '',
                'body' => $n->data['body'] ?? '',
                'data' => $n->data['data'] ?? [],
                'read_at' => $n->read_at,
                'created_at' => $n->created_at,
            ]),
        ]);
    }

    public function readNotification(Request $request, string $id): JsonResponse
    {
        $notification = $request->user()->notifications()->where('id', $id)->firstOrFail();
        $notification->markAsRead();

        return response()->json(['message' => 'Read.']);
    }

    public function flag(Request $request): JsonResponse
    {
        $data = $request->validate([
            'target_type' => ['required', Rule::in(['item_report', 'message', 'user', 'claim', 'conversation'])],
            'target_id' => ['required', 'integer'],
            'reason' => ['required', 'string', 'max:64'],
            'details' => ['nullable', 'string'],
            'detail' => ['nullable', 'string'],
        ]);
        $data['details'] = $data['details'] ?? $data['detail'] ?? null;
        unset($data['detail']);

        $flag = Flag::query()->create([
            'user_id' => $request->user()->id,
            ...$data,
            'severity' => 'medium',
            'status' => 'open',
        ]);

        return response()->json(['data' => $flag], 201);
    }

    public function search(Request $request, SearchEngine $search): JsonResponse
    {
        $paginator = $search->search($request->only(['q', 'type', 'category_id']));

        return response()->json([
            'data' => $paginator->getCollection()->map->toTeaserDto()->values(),
            'meta' => ['total' => $paginator->total(), 'current_page' => $paginator->currentPage()],
        ]);
    }

    public function tag(string $code): JsonResponse
    {
        $tag = QrTag::query()->with('user')->where('code', $code)->where('status', 'active')->firstOrFail();

        return response()->json(['data' => $tag->toFoundFlowDto()]);
    }

    public function tip(Request $request): JsonResponse
    {
        $data = $request->validate([
            'to_user' => ['nullable', 'exists:users,id'],
            'claim_id' => ['nullable', 'exists:claims,id'],
            'amount' => ['nullable', 'integer', 'min:1'],
            'note' => ['nullable', 'string', 'max:500'],
        ]);
        $data['amount'] = $data['amount'] ?? 0;
        if (empty($data['to_user']) && ! empty($data['claim_id'])) {
            $tipClaim = \App\Models\Claim::query()->with('itemReport')->find($data['claim_id']);
            $data['to_user'] = $tipClaim?->itemReport?->user_id;
        }
        abort_unless(! empty($data['to_user']), 422, 'A recipient is required.');

        $tip = Tip::query()->create([
            'from_user' => $request->user()->id,
            'to_user' => $data['to_user'],
            'claim_id' => $data['claim_id'] ?? null,
            'amount' => $data['amount'],
            'status' => 'pending',
        ]);

        return response()->json(['data' => $tip, 'message' => 'Tip recorded (payments stub).'], 201);
    }
}
