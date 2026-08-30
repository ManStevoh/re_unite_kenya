<?php

namespace App\Domain\Matching;

use App\Models\ItemReport;

interface MatchingEngine
{
    /**
     * @return array{score: int, reasons: list<string>}|null
     */
    public function score(ItemReport $lost, ItemReport $found): ?array;
}
