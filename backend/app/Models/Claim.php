<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

#[Fillable(['item_report_id', 'claimant_id', 'status', 'attempts', 'decision_reason', 'decided_by', 'decided_at'])]
class Claim extends Model
{
    protected function casts(): array
    {
        return [
            'decided_at' => 'datetime',
        ];
    }

    public function itemReport(): BelongsTo
    {
        return $this->belongsTo(ItemReport::class);
    }

    public function claimant(): BelongsTo
    {
        return $this->belongsTo(User::class, 'claimant_id');
    }

    public function decidedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'decided_by');
    }

    public function answers(): HasMany
    {
        return $this->hasMany(ClaimAnswer::class);
    }

    public function evidence(): HasMany
    {
        return $this->hasMany(ClaimEvidence::class);
    }

    public function conversation(): HasOne
    {
        return $this->hasOne(Conversation::class);
    }

    public function handover(): HasOne
    {
        return $this->hasOne(Handover::class);
    }

    public function isOpen(): bool
    {
        return in_array($this->status, ['draft', 'submitted', 'in_review', 'needs_info'], true);
    }
}
