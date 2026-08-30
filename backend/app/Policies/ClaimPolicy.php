<?php

namespace App\Policies;

use App\Models\Claim;
use App\Models\User;

class ClaimPolicy
{
    public function view(User $user, Claim $claim): bool
    {
        return $user->id === $claim->claimant_id
            || $user->id === $claim->itemReport?->user_id
            || $user->can('claims.view')
            || $user->canAccessHiddenFields()
            || ($claim->itemReport && $claim->itemReport->viewerIsHubStaff($user));
    }

    public function create(User $user): bool
    {
        return $user->status === 'active'
            && $user->verification_level >= 3
            && $user->phone_verified_at !== null;
    }

    public function answer(User $user, Claim $claim): bool
    {
        return $user->id === $claim->claimant_id && $claim->isOpen();
    }

    public function evidence(User $user, Claim $claim): bool
    {
        return $this->answer($user, $claim);
    }

    public function withdraw(User $user, Claim $claim): bool
    {
        return $user->id === $claim->claimant_id && $claim->isOpen();
    }

    public function decide(User $user, Claim $claim): bool
    {
        return $user->can('claims.decide')
            || $user->id === $claim->itemReport?->user_id
            || ($claim->itemReport && $claim->itemReport->viewerIsHubStaff($user));
    }
}
