<?php

namespace App\Http\Controllers\Api\V1;

use App\Domain\Audit\Auditor;
use App\Domain\Notifications\PlatformNotifier;
use App\Http\Controllers\Controller;
use App\Models\Claim;
use App\Models\ClaimAnswer;
use App\Models\ClaimEvidence;
use App\Models\Conversation;
use App\Models\ItemReport;
use App\Models\Setting;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ClaimController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $rows = Claim::query()
            ->with(['itemReport.category', 'claimant'])
            ->where(function ($q) use ($user) {
                $q->where('claimant_id', $user->id)
                    ->orWhereHas('itemReport', fn ($r) => $r->where('user_id', $user->id));
            })
            ->latest()
            ->get();

        return response()->json([
            'data' => $rows->map(fn ($c) => $this->payload($c, $user))->values(),
        ]);
    }

    public function store(Request $request, PlatformNotifier $notifier): JsonResponse
    {
        $this->authorize('create', Claim::class);
        $data = $request->validate([
            'item_report_id' => ['required_without:report_id', 'exists:item_reports,id'],
            'report_id' => ['required_without:item_report_id', 'exists:item_reports,id'],
        ]);

        $report = ItemReport::query()->findOrFail($data['item_report_id'] ?? $data['report_id']);
        abort_if($report->user_id === $request->user()->id, 422, 'You cannot claim your own report.');
        abort_if(! $report->isOpen(), 422, 'This report is not open for claims.');

        $limit = (int) Setting::getValue('claim_attempt_limit', 3);
        $existing = Claim::query()
            ->where('item_report_id', $report->id)
            ->where('claimant_id', $request->user()->id)
            ->first();

        if ($existing && $existing->attempts >= $limit && $existing->isOpen()) {
            return response()->json(['message' => 'Attempt limit reached. A moderator will review.'], 429);
        }

        $claim = $existing ?: Claim::query()->create([
            'item_report_id' => $report->id,
            'claimant_id' => $request->user()->id,
            'status' => 'submitted',
            'attempts' => 0,
        ]);

        $conversation = $claim->conversation ?: Conversation::query()->create([
            'claim_id' => $claim->id,
            'item_report_id' => $report->id,
        ]);
        $conversation->participants()->syncWithoutDetaching([$request->user()->id, $report->user_id]);

        $report->update(['status' => 'claim_in_progress']);
        $notifier->send($report->user, 'claim_received', 'New claim submitted', "Someone claimed {$report->title}.", ['claim_id' => $claim->id]);
        Auditor::record('claim.submit', $claim, [], $request->user());

        return response()->json(['data' => $this->payload($claim->fresh(['itemReport', 'answers', 'evidence']))], 201);
    }

    public function show(Request $request, Claim $claim): JsonResponse
    {
        $this->authorize('view', $claim);
        $claim->load(['itemReport.category', 'claimant', 'answers', 'evidence']);

        return response()->json(['data' => $this->payload($claim, $request->user())]);
    }

    public function answers(Request $request, Claim $claim): JsonResponse
    {
        $this->authorize('answer', $claim);
        $data = $request->validate([
            'answers' => ['required', 'array', 'min:1'],
        ]);

        $rows = $this->normalizeAnswers($data['answers']);
        if ($rows === []) {
            return response()->json(['message' => 'Answers are required.', 'errors' => ['answers' => ['Invalid answers payload.']]], 422);
        }

        $claim->increment('attempts');
        foreach ($rows as $row) {
            ClaimAnswer::query()->create([
                'claim_id' => $claim->id,
                'question_key' => $row['question_key'],
                'question' => $row['question'],
                'answer' => $row['answer'],
            ]);
        }
        $claim->update(['status' => 'in_review']);

        return response()->json(['data' => ['id' => $claim->id, 'status' => $claim->status, 'attempts' => $claim->attempts]]);
    }

    public function evidence(Request $request, Claim $claim): JsonResponse
    {
        $this->authorize('evidence', $claim);
        $request->validate([
            'file' => ['required', 'file', 'max:8192'],
            'note' => ['nullable', 'string', 'max:190'],
        ]);
        $path = $request->file('file')->store('claims/'.$claim->id, 'public');
        $row = ClaimEvidence::query()->create([
            'claim_id' => $claim->id,
            'path' => $path,
            'note' => $request->input('note'),
        ]);

        return response()->json(['data' => $row], 201);
    }

    public function withdraw(Request $request, Claim $claim): JsonResponse
    {
        $this->authorize('withdraw', $claim);
        $claim->update(['status' => 'withdrawn']);
        Auditor::record('claim.withdraw', $claim, [], $request->user());

        return response()->json(['data' => $this->payload($claim)]);
    }

    public function review(Request $request, Claim $claim, PlatformNotifier $notifier): JsonResponse
    {
        $this->authorize('decide', $claim);
        $data = $request->validate([
            'accept' => ['required', 'boolean'],
            'reason' => ['nullable', 'string', 'max:190'],
        ]);
        $claim->update([
            'status' => $data['accept'] ? 'approved' : 'rejected',
            'decision_reason' => $data['reason'] ?? null,
            'decided_by' => $request->user()->id,
            'decided_at' => now(),
        ]);
        if ($data['accept']) {
            $claim->itemReport?->update(['status' => 'matched']);
        }
        if ($claim->claimant) {
            $notifier->send(
                $claim->claimant,
                'claim_decision',
                $data['accept'] ? 'Claim accepted' : 'Claim not verified',
                $data['reason'] ?? ($data['accept'] ? 'The owner accepted your claim.' : 'The owner could not verify this claim.'),
                ['claim_id' => $claim->id],
            );
        }
        Auditor::record('claim.decide', $claim, ['accept' => $data['accept']], $request->user());

        return response()->json(['data' => $this->payload($claim->fresh(['itemReport', 'claimant']), $request->user())]);
    }

    public function requestMoreInfo(Request $request, Claim $claim, PlatformNotifier $notifier): JsonResponse
    {
        $this->authorize('decide', $claim);
        $data = $request->validate([
            'message' => ['required', 'string', 'max:500'],
        ]);
        $claim->update([
            'status' => 'needs_info',
            'decision_reason' => $data['message'],
        ]);
        if ($claim->claimant) {
            $notifier->send(
                $claim->claimant,
                'claim_decision',
                'More information needed',
                $data['message'],
                ['claim_id' => $claim->id],
            );
        }
        Auditor::record('claim.more_info', $claim, [], $request->user());

        return response()->json(['data' => $this->payload($claim->fresh(['itemReport', 'claimant']), $request->user())]);
    }

    /**
     * @return array<string, mixed>
     */
    private function payload(Claim $claim, $user = null): array
    {
        $canSeeAnswers = $user && ($user->can('claims.view_answers') || $user->id === $claim->itemReport?->user_id || $user->id !== $claim->claimant_id && $this->authorizeSilent($user, $claim));

        return [
            'id' => $claim->id,
            'status' => $claim->status,
            'attempts' => $claim->attempts,
            'decision_reason' => $claim->decision_reason,
            'item_report_id' => $claim->item_report_id,
            'report_id' => $claim->item_report_id,
            'claimant_id' => $claim->claimant_id,
            'title' => $claim->itemReport?->title,
            'item_report' => $claim->itemReport?->toTeaserDto(),
            'claimant' => $claim->claimant?->toUserDto(),
            'answers' => $canSeeAnswers ? $claim->answers : [],
            'evidence' => $claim->evidence,
            'conversation_id' => $claim->conversation?->id,
        ];
    }

    /**
     * @param  array<int|string, mixed>  $answers
     * @return list<array{question_key: string, question: string, answer: string}>
     */
    private function normalizeAnswers(array $answers): array
    {
        $rows = [];
        foreach ($answers as $key => $value) {
            if (is_array($value) && isset($value['answer'])) {
                $rows[] = [
                    'question_key' => (string) ($value['question_key'] ?? $value['key'] ?? $key),
                    'question' => (string) ($value['question'] ?? $value['question_key'] ?? $key),
                    'answer' => (string) $value['answer'],
                ];
                continue;
            }
            if (is_string($key) && (is_string($value) || is_numeric($value))) {
                $rows[] = [
                    'question_key' => $key,
                    'question' => $key,
                    'answer' => (string) $value,
                ];
            }
        }

        return $rows;
    }

    private function authorizeSilent($user, Claim $claim): bool
    {
        return $user->canAccessHiddenFields() || ($claim->itemReport && $claim->itemReport->viewerIsHubStaff($user));
    }
}
