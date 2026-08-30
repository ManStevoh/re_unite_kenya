<?php

namespace App\Http\Controllers\Api\V1;

use App\Domain\Audit\Auditor;
use App\Http\Controllers\Controller;
use App\Models\Claim;
use App\Models\Handover;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class HandoverController extends Controller
{
    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'claim_id' => ['required', 'exists:claims,id'],
            'type' => ['required', 'string'],
            'scheduled_at' => ['nullable', 'date'],
            'when' => ['nullable', 'date'],
            'place' => ['nullable', 'string', 'max:190'],
        ]);

        $type = match ($data['type']) {
            'hub_pickup', 'hubPickup' => 'hub_pickup',
            'staff_delivery', 'courier' => 'staff_delivery',
            'meetup', 'inPerson', 'in_person' => 'meetup',
            default => null,
        };
        abort_unless($type, 422, 'Invalid handover type.');
        $data['type'] = $type;
        $data['scheduled_at'] = $data['scheduled_at'] ?? $data['when'] ?? null;

        $claim = Claim::query()->findOrFail($data['claim_id']);
        abort_unless($claim->status === 'approved' || $request->user()->can('handovers.manage'), 422, 'Claim must be approved.');
        $this->authorize('view', $claim);

        $plain = (string) random_int(100000, 999999);
        $handover = Handover::query()->create([
            'claim_id' => $claim->id,
            'type' => $data['type'],
            'scheduled_at' => $data['scheduled_at'] ?? now()->addDay(),
            'place' => $data['place'] ?? null,
            'code_hash' => Hash::make($plain),
            'status' => 'scheduled',
        ]);

        Auditor::record('handover.create', $handover, [], $request->user());

        return response()->json([
            'data' => [
                'id' => $handover->id,
                'type' => $handover->type,
                'scheduled_at' => $handover->scheduled_at,
                'place' => $handover->place,
                'status' => $handover->status,
                'code' => $plain,
            ],
        ], 201);
    }

    public function show(Request $request, Handover $handover): JsonResponse
    {
        $this->authorize('view', $handover);
        $handover->load('claim.itemReport');

        return response()->json(['data' => [
            'id' => $handover->id,
            'claim_id' => $handover->claim_id,
            'type' => $handover->type,
            'scheduled_at' => $handover->scheduled_at,
            'place' => $handover->place,
            'status' => $handover->status,
        ]]);
    }

    public function confirm(Request $request, Handover $handover): JsonResponse
    {
        $this->authorize('confirm', $handover);
        $data = $request->validate([
            'code' => ['nullable', 'string'],
            'as_owner' => ['nullable', 'boolean'],
        ]);

        if (! empty($data['code']) && $handover->code_hash && ! Hash::check($data['code'], $handover->code_hash)) {
            throw ValidationException::withMessages(['code' => 'Invalid handover code.']);
        }

        $handover->update([
            'status' => 'completed',
            'confirmed_at' => now(),
            'confirmed_by' => $request->user()->id,
        ]);
        $handover->claim?->update(['status' => 'completed']);
        $handover->claim?->itemReport?->update(['status' => 'recovered']);
        $finder = $handover->claim?->itemReport?->user;
        if ($finder) {
            $finder->increment('reputation_points', 10);
        }
        Auditor::record('handover.confirm', $handover, [], $request->user());

        return response()->json(['data' => ['id' => $handover->id, 'status' => $handover->status]]);
    }
}
