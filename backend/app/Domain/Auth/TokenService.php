<?php

namespace App\Domain\Auth;

use App\Models\Device;
use App\Models\RefreshToken;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Laravel\Sanctum\PersonalAccessToken;

class TokenService
{
    /**
     * @return array{token: string, refresh_token: string, user: array<string, mixed>}
     */
    public function issue(User $user, string $deviceName = 'api', ?string $ip = null, ?string $os = null): array
    {
        $access = $user->createToken($deviceName);
        $plainRefresh = Str::random(64);

        RefreshToken::query()->create([
            'user_id' => $user->id,
            'token_hash' => hash('sha256', $plainRefresh),
            'device_name' => $deviceName,
            'expires_at' => now()->addDays(30),
        ]);

        $tokenId = $access->accessToken?->id;

        Device::query()->create([
            'user_id' => $user->id,
            'name' => $deviceName,
            'os' => $os,
            'last_ip' => $ip,
            'last_seen_at' => now(),
            'token_id' => $tokenId,
        ]);

        return [
            'token' => $access->plainTextToken,
            'refresh_token' => $plainRefresh,
            'user' => $user->toPrivateDto(),
        ];
    }

    /**
     * @return array{token: string, refresh_token: string, user: array<string, mixed>}|null
     */
    public function rotate(string $refreshToken): ?array
    {
        $hash = hash('sha256', $refreshToken);
        $row = RefreshToken::query()->where('token_hash', $hash)->first();

        if (! $row || ! $row->isValid()) {
            return null;
        }

        $user = $row->user;
        $row->update(['revoked_at' => now()]);

        return $this->issue($user, $row->device_name ?? 'api');
    }

    public function revokeCurrent(?User $user, ?string $bearer = null): void
    {
        if (! $user) {
            return;
        }

        $token = $user->currentAccessToken();
        if ($token instanceof PersonalAccessToken) {
            Device::query()->where('token_id', $token->id)->delete();
            $token->delete();
        }
    }

    public function revokeAll(User $user): void
    {
        $user->tokens()->delete();
        RefreshToken::query()->where('user_id', $user->id)->update(['revoked_at' => now()]);
        Device::query()->where('user_id', $user->id)->delete();
    }
}
