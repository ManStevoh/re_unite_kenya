<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable([
    'organization_id', 'name', 'type', 'address', 'lat', 'lng',
    'hours_json', 'is_public', 'retention_days', 'capacity', 'contact_internal',
])]
class Hub extends Model
{
    protected function casts(): array
    {
        return [
            'lat' => 'float',
            'lng' => 'float',
            'hours_json' => 'array',
            'is_public' => 'boolean',
        ];
    }

    public function organization(): BelongsTo
    {
        return $this->belongsTo(Organization::class);
    }

    public function staff(): BelongsToMany
    {
        return $this->belongsToMany(User::class, 'hub_staff')->withPivot('role')->withTimestamps();
    }

    public function storageLocations(): HasMany
    {
        return $this->hasMany(StorageLocation::class);
    }

    public function reports(): HasMany
    {
        return $this->hasMany(ItemReport::class);
    }

    public function occupancy(): int
    {
        return $this->reports()->whereIn('status', ['published', 'matched', 'claim_in_progress', 'under_review'])->where('custody', 'at_hub')->count();
    }

    public function toPublicDto(): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'type' => $this->type,
            'address' => $this->address,
            'lat' => $this->is_public ? $this->lat : null,
            'lng' => $this->is_public ? $this->lng : null,
            'hours' => $this->hours_json,
            'is_public' => $this->is_public,
            'retention_days' => $this->retention_days,
            'capacity' => $this->capacity,
            'organization_id' => $this->organization_id,
        ];
    }
}
