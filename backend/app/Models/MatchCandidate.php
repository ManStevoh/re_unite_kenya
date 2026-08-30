<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['lost_id', 'found_id', 'score', 'reasons_json', 'status'])]
class MatchCandidate extends Model
{
    protected function casts(): array
    {
        return [
            'reasons_json' => 'array',
        ];
    }

    public function lost(): BelongsTo
    {
        return $this->belongsTo(ItemReport::class, 'lost_id');
    }

    public function found(): BelongsTo
    {
        return $this->belongsTo(ItemReport::class, 'found_id');
    }
}
