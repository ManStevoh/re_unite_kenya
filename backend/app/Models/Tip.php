<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['from_user', 'to_user', 'claim_id', 'amount', 'status'])]
class Tip extends Model
{
    public function fromUser(): BelongsTo
    {
        return $this->belongsTo(User::class, 'from_user');
    }

    public function toUser(): BelongsTo
    {
        return $this->belongsTo(User::class, 'to_user');
    }

    public function claim(): BelongsTo
    {
        return $this->belongsTo(Claim::class);
    }
}
