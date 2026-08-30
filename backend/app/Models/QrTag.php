<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['code', 'user_id', 'item_label', 'status'])]
class QrTag extends Model
{
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function toFoundFlowDto(): array
    {
        return [
            'code' => $this->code,
            'item_label' => $this->item_label,
            'status' => $this->status,
            'owner' => [
                'display_name' => $this->user?->display_name ?: $this->user?->name,
                'city' => $this->user?->city,
            ],
        ];
    }
}
