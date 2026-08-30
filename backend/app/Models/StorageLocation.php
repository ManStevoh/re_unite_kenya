<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['hub_id', 'code', 'name'])]
class StorageLocation extends Model
{
    public function hub(): BelongsTo
    {
        return $this->belongsTo(Hub::class);
    }
}
