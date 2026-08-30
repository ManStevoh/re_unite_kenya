<?php

namespace App\Jobs;

use App\Domain\Matching\MatchingService;
use App\Models\ItemReport;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;

class ComputeMatchesJob implements ShouldQueue
{
    use Queueable;

    public function __construct(public int $reportId) {}

    public function handle(MatchingService $matching): void
    {
        $report = ItemReport::query()->with(['user', 'category'])->find($this->reportId);
        if (! $report) {
            return;
        }

        $matching->computeFor($report);
    }
}
