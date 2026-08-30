<?php

namespace App\Domain\Matching;

use App\Domain\Notifications\PlatformNotifier;
use App\Models\ItemReport;
use App\Models\MatchCandidate;
use App\Models\Setting;
use App\Models\User;

class MatchingService
{
    public function __construct(
        private readonly MatchingEngine $engine,
        private readonly PlatformNotifier $notifier,
    ) {}

    public function computeFor(ItemReport $report): void
    {
        if (! $report->isOpen() || ! in_array($report->status, ['published', 'matched', 'submitted', 'under_review'], true)) {
            return;
        }

        $counterpartType = $report->isLost() ? 'found' : 'lost';

        $candidates = ItemReport::query()
            ->where('type', $counterpartType)
            ->where('id', '!=', $report->id)
            ->whereNotIn('status', ['draft', 'closed', 'expired', 'recovered', 'rejected'])
            ->whereHas('user', fn ($q) => $q->whereNotIn('status', ['banned', 'suspended']))
            ->when($report->category_id, fn ($q) => $q->where('category_id', $report->category_id))
            ->with(['user', 'category'])
            ->limit(200)
            ->get();

        $scored = [];
        foreach ($candidates as $other) {
            $lost = $report->isLost() ? $report : $other;
            $found = $report->isLost() ? $other : $report;
            $result = $this->engine->score($lost, $found);
            if ($result && $result['score'] >= 40) {
                $scored[] = [
                    'lost_id' => $lost->id,
                    'found_id' => $found->id,
                    'score' => $result['score'],
                    'reasons' => $result['reasons'],
                ];
            }
        }

        usort($scored, fn ($a, $b) => $b['score'] <=> $a['score']);
        $top = array_slice($scored, 0, 20);
        $threshold = (int) (Setting::getValue('match_score_threshold', 60));

        foreach ($top as $row) {
            $match = MatchCandidate::query()->updateOrCreate(
                ['lost_id' => $row['lost_id'], 'found_id' => $row['found_id']],
                ['score' => $row['score'], 'reasons_json' => $row['reasons'], 'status' => 'suggested'],
            );

            if ($row['score'] >= $threshold && $match->wasRecentlyCreated) {
                $match->update(['status' => 'notified']);
                $lost = ItemReport::query()->with('user')->find($row['lost_id']);
                $found = ItemReport::query()->with('user')->find($row['found_id']);
                if ($lost?->user) {
                    $this->notifier->send($lost->user, 'new_match', 'Possible match found', "We found a possible match for {$lost->title}.", [
                        'match_id' => $match->id,
                        'report_id' => $lost->id,
                    ]);
                }
                if ($found?->user) {
                    $this->notifier->send($found->user, 'new_match', 'Someone may be looking for this item', "A lost report looks similar to {$found->title}.", [
                        'match_id' => $match->id,
                        'report_id' => $found->id,
                    ]);
                }
            }
        }
    }
}
