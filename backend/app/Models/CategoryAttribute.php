<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['category_id', 'key', 'label', 'type', 'visibility', 'required', 'options_json', 'sort_order'])]
class CategoryAttribute extends Model
{
    protected function casts(): array
    {
        return [
            'required' => 'boolean',
            'options_json' => 'array',
        ];
    }

    public function category(): BelongsTo
    {
        return $this->belongsTo(Category::class);
    }

    public function toCatalogDto(): array
    {
        return [
            'id' => $this->id,
            'key' => $this->key,
            'label' => $this->label,
            'type' => $this->type,
            'visibility' => $this->visibility,
            'required' => $this->required,
            'options' => $this->options_json,
        ];
    }
}
