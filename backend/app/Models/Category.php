<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable(['parent_id', 'slug', 'name', 'sensitivity', 'photo_guidance', 'retention_days', 'sort_order', 'schema_json'])]
class Category extends Model
{
    use HasFactory;

    protected function casts(): array
    {
        return [
            'schema_json' => 'array',
        ];
    }

    public function parent(): BelongsTo
    {
        return $this->belongsTo(self::class, 'parent_id');
    }

    public function children(): HasMany
    {
        return $this->hasMany(self::class, 'parent_id');
    }

    public function categoryAttributes(): HasMany
    {
        return $this->hasMany(CategoryAttribute::class)->orderBy('sort_order');
    }

    public function reports(): HasMany
    {
        return $this->hasMany(ItemReport::class);
    }

    public function toCatalogDto(): array
    {
        return [
            'id' => $this->id,
            'parent_id' => $this->parent_id,
            'slug' => $this->slug,
            'code' => $this->slug,
            'name' => $this->name,
            'icon' => $this->schema_json['icon'] ?? 'category',
            'sensitivity' => $this->sensitivity,
            'photo_guidance' => $this->photo_guidance,
            'retention_days' => $this->retention_days,
            'sort_order' => $this->sort_order,
            'schema' => $this->schema_json,
            'attributes' => $this->relationLoaded('categoryAttributes')
                ? $this->categoryAttributes->map->toCatalogDto()->values()
                : [],
        ];
    }
}
