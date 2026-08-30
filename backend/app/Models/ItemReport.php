<?php

namespace App\Models;

use Database\Factories\ItemReportFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable([
    'user_id', 'type', 'title', 'category_id', 'description', 'hidden_notes', 'serial',
    'attributes_json', 'lat', 'lng', 'geohash', 'place_name', 'area', 'occurred_at',
    'status', 'visibility', 'custody', 'hub_id', 'storage_code', 'condition',
    'reward_note', 'moderation_reason',
])]
#[Hidden(['hidden_notes', 'serial'])]
class ItemReport extends Model
{
    /** @use HasFactory<ItemReportFactory> */
    use HasFactory;

    protected function casts(): array
    {
        return [
            'attributes_json' => 'array',
            'lat' => 'float',
            'lng' => 'float',
            'occurred_at' => 'datetime',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function category(): BelongsTo
    {
        return $this->belongsTo(Category::class);
    }

    public function hub(): BelongsTo
    {
        return $this->belongsTo(Hub::class);
    }

    public function media(): HasMany
    {
        return $this->hasMany(MediaAsset::class, 'report_id');
    }

    public function claims(): HasMany
    {
        return $this->hasMany(Claim::class);
    }

    public function lostMatches(): HasMany
    {
        return $this->hasMany(MatchCandidate::class, 'lost_id');
    }

    public function foundMatches(): HasMany
    {
        return $this->hasMany(MatchCandidate::class, 'found_id');
    }

    public function isLost(): bool
    {
        return $this->type === 'lost';
    }

    public function isOpen(): bool
    {
        return ! in_array($this->status, ['recovered', 'closed', 'expired', 'rejected'], true);
    }

    public function publicPhotos(): array
    {
        $media = $this->relationLoaded('media')
            ? $this->media->where('visibility', 'public')
            : $this->media()->where('visibility', 'public')->get();

        return $media->map->publicUrl()->filter()->values()->all();
    }

    public function publicThumbnail(): ?string
    {
        $photos = $this->publicPhotos();
        if ($photos !== []) {
            return $photos[0];
        }

        $asset = $this->relationLoaded('media')
            ? $this->media->first()
            : $this->media()->first();

        return $asset?->publicUrl();
    }

    public function publicColor(): ?string
    {
        $attrs = $this->attributes_json ?? [];

        return $attrs['color'] ?? $attrs['colour'] ?? null;
    }

    public function toTeaserDto(): array
    {
        return [
            'id' => $this->id,
            'type' => $this->type,
            'title' => $this->title,
            'category' => $this->category?->name,
            'category_id' => $this->category_id,
            'color' => $this->publicColor(),
            'area' => $this->area ?: $this->place_name,
            'occurred_on' => $this->occurred_at?->toDateString(),
            'thumbnail' => $this->publicThumbnail(),
            'photos' => $this->publicPhotos(),
            'hub_name' => $this->hub?->name,
            'status' => $this->visibility === 'public_teaser' ? $this->status : 'published',
            'visibility' => $this->visibility,
        ];
    }

    public function toFullDto(?User $viewer = null): array
    {
        $canSeeHidden = $viewer && (
            $viewer->id === $this->user_id
            || $viewer->canAccessHiddenFields()
            || $this->hasApprovedClaimant($viewer)
            || $this->viewerIsHubStaff($viewer)
        );

        $dto = array_merge($this->toTeaserDto(), [
            'description' => $this->description,
            'place_name' => $this->place_name,
            'attributes' => $this->publicAttributes(),
            'custody' => $this->custody,
            'condition' => $this->condition,
            'reward_note' => $this->reward_note,
            'owner' => $this->user?->toUserDto(),
            'created_at' => $this->created_at?->toIso8601String(),
        ]);

        if ($canSeeHidden) {
            $dto['hidden_notes'] = $this->hidden_notes;
            $dto['serial'] = $this->serial;
            $dto['lat'] = $this->lat;
            $dto['lng'] = $this->lng;
            $dto['storage_code'] = $this->storage_code;
            $dto['attributes'] = $this->attributes_json;
            $dto['moderation_reason'] = $this->moderation_reason;
        }

        return $dto;
    }

    public function publicAttributes(): array
    {
        $attrs = $this->attributes_json ?? [];

        return array_intersect_key($attrs, array_flip(['color', 'colour', 'brand', 'model']));
    }

    public function hasApprovedClaimant(User $user): bool
    {
        return $this->claims()
            ->where('claimant_id', $user->id)
            ->where('status', 'approved')
            ->exists();
    }

    public function viewerIsHubStaff(User $user): bool
    {
        if (! $this->hub_id) {
            return false;
        }

        return $user->staffedHubs()->where('hubs.id', $this->hub_id)->exists();
    }
}
