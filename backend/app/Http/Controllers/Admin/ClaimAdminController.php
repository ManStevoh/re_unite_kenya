<?php

namespace App\Http\Controllers\Admin;

use App\Domain\Audit\Auditor;
use App\Domain\Notifications\PlatformNotifier;
use App\Http\Controllers\Controller;
use App\Models\Claim;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Inertia\Response;

class ClaimAdminController extends Controller
{
    public function index(Request $request): Response
    {
        $query = Claim::query()->with(['itemReport', 'claimant']);
        if ($request->filled('status')) {
            $query->where('status', $request->string('status'));
        } else {
            $query->whereIn('status', ['submitted', 'in_review', 'needs_info']);
        }

        return Inertia::render('Admin/Claims/Index', [
            'claims' => $query->latest()->paginate(20)->through(fn (Claim $c) => [
                'id' => $c->id,
                'status' => $c->status,
                'attempts' => $c->attempts,
                'title' => $c->itemReport?->title,
                'claimant' => $c->claimant?->display_name,
                'created_at' => $c->created_at?->toDateTimeString(),
            ]),
        ]);
    }

    public function show(Claim $claim): Response
    {
        $claim->load(['itemReport.user', 'claimant', 'answers', 'evidence', 'conversation.messages.user']);

        return Inertia::render('Admin/Claims/Show', [
            'claim' => [
                'id' => $claim->id,
                'status' => $claim->status,
                'attempts' => $claim->attempts,
                'decision_reason' => $claim->decision_reason,
                'claimant' => $claim->claimant?->toPrivateDto(),
                'report' => $claim->itemReport?->toFullDto(request()->user()),
                'hidden_truth' => [
                    'serial' => $claim->itemReport?->serial,
                    'hidden_notes' => $claim->itemReport?->hidden_notes,
                    'attributes' => $claim->itemReport?->attributes_json,
                ],
                'answers' => $claim->answers,
                'evidence' => $claim->evidence,
                'conversation_id' => $claim->conversation?->id,
            ],
        ]);
    }

    public function decide(Request $request, Claim $claim, PlatformNotifier $notifier): RedirectResponse
    {
        $data = $request->validate([
            'action' => ['required', 'in:approve,reject,needs_info'],
            'reason' => ['required', 'string'],
        ]);

        $status = match ($data['action']) {
            'approve' => 'approved',
            'reject' => 'rejected',
            default => 'needs_info',
        };

        $claim->update([
            'status' => $status,
            'decision_reason' => $data['reason'],
            'decided_by' => $request->user()->id,
            'decided_at' => now(),
        ]);

        if ($status === 'approved' && $claim->itemReport) {
            $claim->itemReport->update(['status' => 'matched']);
        }

        $notifier->send($claim->claimant, 'claim_decision', 'Claim '.$status, $data['reason'], ['claim_id' => $claim->id]);
        Auditor::record('claim.decide', $claim, $data, $request->user());

        return back()->with('success', 'Claim updated.');
    }
}
