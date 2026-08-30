<?php

namespace App\Http\Controllers\Admin;

use App\Domain\Audit\Auditor;
use App\Http\Controllers\Controller;
use App\Models\Conversation;
use App\Models\Dispute;
use App\Models\Flag;
use App\Models\Handover;
use App\Models\MatchCandidate;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Inertia\Response;

class OperationsAdminController extends Controller
{
    public function matches(Request $request): Response
    {
        $rows = MatchCandidate::query()
            ->with(['lost.category', 'found.category'])
            ->when($request->filled('status'), fn ($q) => $q->where('status', $request->string('status')))
            ->latest()
            ->paginate(20);

        return Inertia::render('Admin/Matches/Index', [
            'matches' => $rows->through(fn (MatchCandidate $m) => [
                'id' => $m->id,
                'score' => $m->score,
                'status' => $m->status,
                'reasons' => $m->reasons_json,
                'lost' => $m->lost?->only(['id', 'title', 'type']),
                'found' => $m->found?->only(['id', 'title', 'type']),
            ]),
        ]);
    }

    public function updateMatch(Request $request, MatchCandidate $match): RedirectResponse
    {
        $data = $request->validate(['status' => ['required', 'in:suggested,notified,accepted,dismissed,admin_forced']]);
        $match->update($data);
        Auditor::record('match.update', $match, $data, $request->user());

        return back()->with('success', 'Match updated.');
    }

    public function handovers(Request $request): Response
    {
        $rows = Handover::query()->with(['claim.itemReport', 'claim.claimant'])
            ->when($request->filled('status'), fn ($q) => $q->where('status', $request->string('status')))
            ->latest('scheduled_at')
            ->paginate(20);

        return Inertia::render('Admin/Handovers/Index', [
            'handovers' => $rows->through(fn (Handover $h) => [
                'id' => $h->id,
                'type' => $h->type,
                'status' => $h->status,
                'place' => $h->place,
                'scheduled_at' => $h->scheduled_at?->toDateTimeString(),
                'claim_id' => $h->claim_id,
                'title' => $h->claim?->itemReport?->title,
            ]),
        ]);
    }

    public function flags(Request $request): Response
    {
        $rows = Flag::query()->with('user')
            ->when($request->filled('status'), fn ($q) => $q->where('status', $request->string('status')))
            ->latest()
            ->paginate(20);

        return Inertia::render('Admin/Flags/Index', [
            'flags' => $rows->through(fn (Flag $f) => [
                'id' => $f->id,
                'reason' => $f->reason,
                'target_type' => $f->target_type,
                'target_id' => $f->target_id,
                'severity' => $f->severity,
                'status' => $f->status,
                'reporter' => $f->user?->display_name,
                'created_at' => $f->created_at?->toDateTimeString(),
            ]),
        ]);
    }

    public function updateFlag(Request $request, Flag $flag): RedirectResponse
    {
        $data = $request->validate(['status' => ['required', 'in:open,reviewed,upheld,dismissed']]);
        $flag->update($data);
        Auditor::record('flag.update', $flag, $data, $request->user());

        return back()->with('success', 'Flag updated.');
    }

    public function disputes(): Response
    {
        $rows = Dispute::query()->with('itemReport')->latest()->paginate(20);

        return Inertia::render('Admin/Disputes/Index', [
            'disputes' => $rows->through(fn (Dispute $d) => [
                'id' => $d->id,
                'type' => $d->type,
                'status' => $d->status,
                'notes' => $d->notes,
                'title' => $d->itemReport?->title,
                'item_report_id' => $d->item_report_id,
            ]),
        ]);
    }

    public function showDispute(Dispute $dispute): Response
    {
        $dispute->load(['itemReport.claims.claimant', 'itemReport.claims.answers']);

        return Inertia::render('Admin/Disputes/Show', [
            'dispute' => $dispute,
            'claims' => $dispute->itemReport?->claims,
        ]);
    }

    public function resolveDispute(Request $request, Dispute $dispute): RedirectResponse
    {
        $data = $request->validate(['resolution' => ['required', 'string'], 'status' => ['required', 'in:open,resolved']]);
        $dispute->update([...$data, 'resolved_by' => $request->user()->id]);
        Auditor::record('dispute.resolve', $dispute, $data, $request->user());

        return back()->with('success', 'Dispute updated.');
    }

    public function chats(): Response
    {
        $rows = Conversation::query()
            ->where('flagged', true)
            ->orWhereNotNull('escalated_at')
            ->with(['itemReport', 'participants'])
            ->latest()
            ->paginate(20);

        return Inertia::render('Admin/Chats/Index', [
            'conversations' => $rows->through(fn (Conversation $c) => [
                'id' => $c->id,
                'status' => $c->status,
                'flagged' => $c->flagged,
                'title' => $c->itemReport?->title,
            ]),
        ]);
    }

    public function showChat(Request $request, Conversation $conversation): Response
    {
        Auditor::record('chat.read_flagged', $conversation, [], $request->user());
        $conversation->load(['messages.user', 'itemReport', 'participants']);

        return Inertia::render('Admin/Chats/Show', [
            'conversation' => $conversation,
            'messages' => $conversation->messages,
        ]);
    }
}
