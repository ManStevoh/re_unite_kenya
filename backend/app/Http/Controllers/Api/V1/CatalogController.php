<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Category;
use App\Models\CmsPage;
use App\Models\Hub;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Cache;

class CatalogController extends Controller
{
    public function categories(): JsonResponse
    {
        $data = Cache::remember('catalog.categories', 120, function () {
            return Category::query()->with('categoryAttributes')->orderBy('sort_order')->get()->map->toCatalogDto()->values()->all();
        });

        return response()->json(['data' => $data]);
    }

    public function hubs(): JsonResponse
    {
        $data = Cache::remember('catalog.hubs', 120, function () {
            return Hub::query()->where('is_public', true)->orderBy('name')->get()->map->toPublicDto()->values()->all();
        });

        return response()->json(['data' => $data]);
    }

    public function hub(Hub $hub): JsonResponse
    {
        abort_unless($hub->is_public, 404);

        return response()->json(['data' => array_merge($hub->toPublicDto(), [
            'storage_locations' => $hub->storageLocations()->get(['id', 'code', 'name']),
        ])]);
    }

    public function cmsIndex(): JsonResponse
    {
        $rows = CmsPage::query()->where('published', true)->orderBy('title')->get();

        return response()->json([
            'data' => $rows->map->toPublicDto()->values(),
        ]);
    }

    public function cms(string $slug): JsonResponse
    {
        $page = CmsPage::query()->where('slug', $slug)->where('published', true)->firstOrFail();

        return response()->json(['data' => $page->toPublicDto()]);
    }
}
