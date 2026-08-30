<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\URL;

#[Fillable(['report_id', 'claim_id', 'path', 'variant', 'visibility', 'mime', 'size'])]
class MediaAsset extends Model
{
    public function report(): BelongsTo
    {
        return $this->belongsTo(ItemReport::class, 'report_id');
    }

    public function claim(): BelongsTo
    {
        return $this->belongsTo(Claim::class);
    }

    public function publicUrl(): ?string
    {
        if ($this->visibility === 'public') {
            return asset('storage/'.$this->path);
        }

        return URL::temporarySignedRoute('media.show', now()->addMinutes(15), ['media' => $this->id]);
    }

    public function diskPath(): string
    {
        return Storage::disk('public')->path($this->path);
    }
}
