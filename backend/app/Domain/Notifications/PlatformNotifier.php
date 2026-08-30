<?php

namespace App\Domain\Notifications;

use App\Models\DeliveryLog;
use App\Models\User;
use App\Notifications\GenericPlatformNotification;
use Illuminate\Support\Facades\Log;

class PlatformNotifier
{
    public function send(User $user, string $event, string $title, string $body, array $data = []): void
    {
        $prefs = $user->notificationPreferences()[$event] ?? ['in_app' => true];

        if (($prefs['in_app'] ?? true) !== false) {
            $user->notify(new GenericPlatformNotification($event, $title, $body, $data));
            $this->log($user, 'in_app', $event, $user->email, 'sent');
        }

        if (($prefs['email'] ?? false) && $user->email) {
            Log::info("Reunite email [{$event}] to {$user->email}: {$title}");
            $this->log($user, 'email', $event, $user->email, 'logged');
        }

        if (($prefs['sms'] ?? false) && $user->phone) {
            Log::info("Reunite SMS [{$event}] to {$user->phone}: {$title}");
            $this->log($user, 'sms', $event, $user->phone, 'logged');
        }
    }

    public function broadcast(iterable $users, string $event, string $title, string $body, array $data = []): int
    {
        $count = 0;
        foreach ($users as $user) {
            if ($user instanceof User) {
                $this->send($user, $event, $title, $body, $data);
                $count++;
            }
        }

        return $count;
    }

    private function log(?User $user, string $channel, string $event, ?string $recipient, string $status): void
    {
        DeliveryLog::query()->create([
            'user_id' => $user?->id,
            'channel' => $channel,
            'event' => $event,
            'recipient_masked' => $this->mask($recipient),
            'status' => $status,
        ]);
    }

    private function mask(?string $value): string
    {
        if (! $value) {
            return 'unknown';
        }

        if (str_contains($value, '@')) {
            [$name, $domain] = explode('@', $value, 2);

            return substr($name, 0, 1).'***@'.$domain;
        }

        return str_repeat('*', max(0, strlen($value) - 4)).substr($value, -4);
    }
}
