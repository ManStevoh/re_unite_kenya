<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['item_report_id', 'type', 'notes', 'status', 'resolved_by', 'resolution'])]
class Dispute extends Model
{
    public function itemReport(): BelongsTo
    {
        return $this->belongsTo(ItemReport::class);
    }

    public function resolvedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'resolved_by');
    }
}
