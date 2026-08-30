<?php

namespace App\Domain\Trust;

use App\Models\Claim;
use App\Models\ItemReport;
use App\Models\User;

class ReputationStats
{
    public static function for(User $user): array
    {
        return [
            'reports_filed' => ItemReport::query()->where('user_id', $user->id)->count(),
            'items_returned' => ItemReport::query()->where('user_id', $user->id)->where('status', 'recovered')->count(),
            'claims_completed' => Claim::query()->where('claimant_id', $user->id)->whereIn('status', ['approved', 'completed'])->count(),
            'reputation_points' => $user->reputation_points,
        ];
    }
}
