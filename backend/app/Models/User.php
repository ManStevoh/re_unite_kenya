<?php

namespace App\Models;

use App\Domain\Trust\ReputationStats;
use Database\Factories\UserFactory;
use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
use Spatie\Permission\Traits\HasRoles;

#[Fillable([
    'name',
    'display_name',
    'email',
    'password',
    'phone',
    'phone_verified_at',
    'city',
    'avatar_path',
    'status',
    'verification_level',
    'trust_score',
    'reputation_points',
    'locale',
    'id_verification_status',
    'notification_preferences',
    'email_verified_at',
])]
#[Hidden(['password', 'remember_token'])]
class User extends Authenticatable implements MustVerifyEmail
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens, HasFactory, HasRoles, Notifiable, SoftDeletes;

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'phone_verified_at' => 'datetime',
            'password' => 'hashed',
            'notification_preferences' => 'array',
            'deleted_at' => 'datetime',
        ];
    }

    public function reports(): HasMany
    {
        return $this->hasMany(ItemReport::class);
    }

    public function devices(): HasMany
    {
        return $this->hasMany(Device::class);
    }

    public function claims(): HasMany
    {
        return $this->hasMany(Claim::class, 'claimant_id');
    }

    public function qrTags(): HasMany
    {
        return $this->hasMany(QrTag::class);
    }

    public function staffedHubs(): BelongsToMany
    {
        return $this->belongsToMany(Hub::class, 'hub_staff')->withPivot('role')->withTimestamps();
    }

    public function isStaff(): bool
    {
        return $this->hasAnyRole(['hub_staff', 'hub_manager', 'moderator', 'support', 'admin', 'super_admin']);
    }

    public function isAdminOperator(): bool
    {
        return $this->hasAnyRole(['moderator', 'admin', 'support', 'super_admin', 'hub_manager']);
    }

    public function canAccessHiddenFields(): bool
    {
        return $this->can('reports.view_hidden') || $this->hasAnyRole(['moderator', 'admin', 'super_admin', 'support', 'hub_manager']);
    }

    public function defaultNotificationPreferences(): array
    {
        return [
            'new_match' => ['in_app' => true, 'push' => true, 'email' => true, 'sms' => false],
            'claim_received' => ['in_app' => true, 'push' => true, 'email' => true, 'sms' => false],
            'claim_decision' => ['in_app' => true, 'push' => true, 'email' => true, 'sms' => true],
            'new_chat_message' => ['in_app' => true, 'push' => true, 'email' => false, 'sms' => false],
            'handover_reminder' => ['in_app' => true, 'push' => true, 'email' => true, 'sms' => false],
            'expiry_warning' => ['in_app' => true, 'push' => true, 'email' => true, 'sms' => false],
            'admin_broadcast' => ['in_app' => true, 'push' => false, 'email' => false, 'sms' => false],
        ];
    }

    public function notificationPreferences(): array
    {
        return array_replace_recursive($this->defaultNotificationPreferences(), $this->notification_preferences ?? []);
    }

    public function toUserDto(): array
    {
        return [
            'id' => $this->id,
            'display_name' => $this->display_name ?: $this->name,
            'avatar_url' => $this->avatar_path ? asset('storage/'.$this->avatar_path) : null,
            'city' => $this->city,
            'email_verified' => (bool) $this->email_verified_at,
            'phone_verified' => (bool) $this->phone_verified_at,
            'verification_level' => $this->verification_level,
            'id_verification_status' => $this->id_verification_status,
            'member_since' => $this->created_at?->toDateString(),
            'stats' => ReputationStats::for($this),
        ];
    }

    public function toPrivateDto(): array
    {
        return array_merge($this->toUserDto(), [
            'name' => $this->name,
            'email' => $this->email,
            'phone' => $this->phone,
            'status' => $this->status,
            'locale' => $this->locale,
            'trust_score' => $this->trust_score,
            'reputation_points' => $this->reputation_points,
            'roles' => $this->getRoleNames()->values(),
            'hub_id' => $this->staffedHubs()->value('hubs.id'),
        ]);
    }
}
