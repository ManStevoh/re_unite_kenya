<?php

namespace App\Policies;

use App\Models\Handover;
use App\Models\User;

class HandoverPolicy
{
    public function view(User $user, Handover $handover): bool
    {
        $claim = $handover->claim;

        return $user->id === $claim?->claimant_id
            || $user->id === $claim?->itemReport?->user_id
            || $user->can('handovers.view')
            || ($claim?->itemReport && $claim->itemReport->viewerIsHubStaff($user));
    }

    public function confirm(User $user, Handover $handover): bool
    {
        return $this->view($user, $handover);
    }
}
