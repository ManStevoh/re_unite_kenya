<?php

namespace App\Policies;

use App\Models\ItemReport;
use App\Models\User;

class ItemReportPolicy
{
    public function view(?User $user, ItemReport $report): bool
    {
        if (in_array($report->status, ['published', 'matched', 'claim_in_progress'], true) && $report->visibility === 'public_teaser') {
            return true;
        }

        if (! $user) {
            return false;
        }

        return $this->update($user, $report) || $user->canAccessHiddenFields() || $report->hasApprovedClaimant($user) || $report->viewerIsHubStaff($user);
    }

    public function create(User $user): bool
    {
        return in_array($user->status, ['active', 'pending_verification'], true)
            && $user->verification_level >= 2
            && ! in_array($user->status, ['restricted', 'suspended', 'banned', 'deactivated'], true);
    }

    public function update(User $user, ItemReport $report): bool
    {
        if ($user->can('reports.force_status') || $user->canAccessHiddenFields()) {
            return true;
        }

        return $user->id === $report->user_id && $report->isOpen();
    }

    public function delete(User $user, ItemReport $report): bool
    {
        return $user->id === $report->user_id || $user->can('reports.force_status');
    }

    public function submit(User $user, ItemReport $report): bool
    {
        return $this->update($user, $report);
    }

    public function close(User $user, ItemReport $report): bool
    {
        return $this->update($user, $report);
    }

    public function viewMatches(User $user, ItemReport $report): bool
    {
        return $user->id === $report->user_id || $user->can('matches.view') || $user->canAccessHiddenFields();
    }

    public function uploadMedia(User $user, ItemReport $report): bool
    {
        return $this->update($user, $report);
    }
}
