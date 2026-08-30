<?php

namespace App\Http\Controllers;

use App\Models\MediaAsset;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class MediaController extends Controller
{
    public function show(Request $request, MediaAsset $media)
    {
        $this->authorize('view', $media);

        abort_unless(Storage::disk('public')->exists($media->path), 404);

        return Storage::disk('public')->response($media->path);
    }
}
