<?php

namespace App\Policies;

use App\Models\Conversation;
use App\Models\User;

class ConversationPolicy
{
    public function view(User $user, Conversation $conversation): bool
    {
        if ($conversation->hasParticipant($user)) {
            return true;
        }

        if ($conversation->flagged && $user->can('chat.read_flagged')) {
            return true;
        }

        return $user->canAccessHiddenFields();
    }

    public function message(User $user, Conversation $conversation): bool
    {
        return $conversation->hasParticipant($user) && $conversation->status === 'open';
    }
}
