<?php

namespace App\Policies;

use App\Models\MediaAsset;
use App\Models\User;

class MediaAssetPolicy
{
    public function view(?User $user, MediaAsset $media): bool
    {
        if ($media->visibility === 'public') {
            return true;
        }

        if (! $user) {
            return false;
        }

        if ($user->canAccessHiddenFields()) {
            return true;
        }

        if ($media->report && $user->id === $media->report->user_id) {
            return true;
        }

        if ($media->claim && ($user->id === $media->claim->claimant_id || $user->id === $media->claim->itemReport?->user_id)) {
            return true;
        }

        return false;
    }
}
