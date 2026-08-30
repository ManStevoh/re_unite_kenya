<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;

#[Fillable(['slug', 'title', 'body', 'published'])]
class CmsPage extends Model
{
    protected function casts(): array
    {
        return [
            'published' => 'boolean',
        ];
    }

    public function toPublicDto(): array
    {
        return [
            'slug' => $this->slug,
            'title' => $this->title,
            'body' => $this->body,
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
