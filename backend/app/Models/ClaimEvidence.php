<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['claim_id', 'path', 'note'])]
class ClaimEvidence extends Model
{
    public function claim(): BelongsTo
    {
        return $this->belongsTo(Claim::class);
    }
}
