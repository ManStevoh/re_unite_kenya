<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['claim_id', 'question_key', 'question', 'answer'])]
class ClaimAnswer extends Model
{
    public function claim(): BelongsTo
    {
        return $this->belongsTo(Claim::class);
    }
}
