<?php

namespace App\Http\Controllers\Admin;

use App\Domain\Audit\Auditor;
use App\Http\Controllers\Controller;
use App\Models\Category;
use App\Models\CategoryAttribute;
use App\Models\Hub;
use App\Models\StorageLocation;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Str;
use Inertia\Inertia;
use Inertia\Response;

class NetworkAdminController extends Controller
{
    public function hubs(): Response
    {
        return Inertia::render('Admin/Hubs/Index', [
            'hubs' => Hub::query()->with('organization')->get()->map(fn (Hub $h) => [
                ...$h->toPublicDto(),
                'occupancy' => $h->occupancy(),
                'organization' => $h->organization?->name,
            ]),
        ]);
    }

    public function createHub(): Response
    {
        return Inertia::render('Admin/Hubs/Form', [
            'hub' => null,
            'organizations' => \App\Models\Organization::query()->get(['id', 'name']),
        ]);
    }

    public function storeHub(Request $request): RedirectResponse
    {
        $hub = Hub::query()->create($this->hubData($request));
        Cache::forget('catalog.hubs');
        Auditor::record('hub.create', $hub, [], $request->user());

        return redirect('/admin/hubs/'.$hub->id)->with('success', 'Hub created.');
    }

    public function showHub(Hub $hub): Response
    {
        $hub->load(['staff', 'storageLocations', 'organization', 'reports']);

        return Inertia::render('Admin/Hubs/Show', [
            'hub' => $hub->toPublicDto() + [
                'contact_internal' => $hub->contact_internal,
                'occupancy' => $hub->occupancy(),
                'staff' => $hub->staff->map(fn ($u) => ['id' => $u->id, 'name' => $u->display_name ?: $u->name, 'role' => $u->pivot->role]),
                'storage' => $hub->storageLocations,
                'inventory' => $hub->reports()->where('custody', 'at_hub')->whereNotIn('status', ['recovered', 'closed'])->get()->map->toTeaserDto(),
            ],
        ]);
    }

    public function editHub(Hub $hub): Response
    {
        return Inertia::render('Admin/Hubs/Form', [
            'hub' => $hub,
            'organizations' => \App\Models\Organization::query()->get(['id', 'name']),
        ]);
    }

    public function updateHub(Request $request, Hub $hub): RedirectResponse
    {
        $hub->update($this->hubData($request));
        Cache::forget('catalog.hubs');
        Auditor::record('hub.update', $hub, [], $request->user());

        return back()->with('success', 'Hub updated.');
    }

    public function storeStorage(Request $request, Hub $hub): RedirectResponse
    {
        $data = $request->validate(['code' => ['required', 'string', 'max:20'], 'name' => ['required', 'string', 'max:80']]);
        StorageLocation::query()->create(['hub_id' => $hub->id, ...$data]);

        return back()->with('success', 'Storage location added.');
    }

    public function categories(): Response
    {
        return Inertia::render('Admin/Categories/Index', [
            'categories' => Category::query()->with('categoryAttributes')->orderBy('sort_order')->get(),
        ]);
    }

    public function storeCategory(Request $request): RedirectResponse
    {
        $data = $request->validate([
            'name' => ['required', 'string'],
            'sensitivity' => ['required', 'in:public,restricted,highly_sensitive'],
            'photo_guidance' => ['nullable', 'string'],
            'retention_days' => ['required', 'integer', 'min:1'],
            'parent_id' => ['nullable', 'exists:categories,id'],
            'icon' => ['nullable', 'string', 'max:40'],
        ]);
        $icon = $data['icon'] ?? 'category';
        unset($data['icon']);
        $slug = Str::slug($data['name']) ?: 'category';
        $base = $slug;
        $i = 2;
        while (Category::query()->where('slug', $slug)->exists()) {
            $slug = $base.'-'.$i++;
        }
        $data['slug'] = $slug;
        $data['sort_order'] = (int) Category::query()->max('sort_order') + 1;
        $data['schema_json'] = ['icon' => $icon];
        Category::query()->create($data);
        Cache::forget('catalog.categories');

        return back()->with('success', 'Category created.');
    }

    public function updateCategory(Request $request, Category $category): RedirectResponse
    {
        $data = $request->validate([
            'name' => ['sometimes', 'string'],
            'sensitivity' => ['sometimes', 'in:public,restricted,highly_sensitive'],
            'photo_guidance' => ['nullable', 'string'],
            'retention_days' => ['sometimes', 'integer'],
            'sort_order' => ['sometimes', 'integer'],
            'icon' => ['nullable', 'string', 'max:40'],
        ]);
        if (array_key_exists('icon', $data)) {
            $schema = $category->schema_json ?? [];
            $schema['icon'] = $data['icon'] ?: 'category';
            $data['schema_json'] = $schema;
            unset($data['icon']);
        }
        $category->update($data);
        Cache::forget('catalog.categories');

        return back()->with('success', 'Category updated.');
    }

    public function storeAttribute(Request $request, Category $category): RedirectResponse
    {
        $data = $request->validate([
            'key' => ['required', 'string'],
            'label' => ['required', 'string'],
            'type' => ['required', 'in:text,color,enum,number'],
            'visibility' => ['required', 'in:public,hidden_challenge,admin_only'],
            'required' => ['boolean'],
            'options_json' => ['nullable', 'array'],
        ]);
        CategoryAttribute::query()->create(['category_id' => $category->id, ...$data]);
        Cache::forget('catalog.categories');

        return back()->with('success', 'Attribute added.');
    }

    /**
     * @return array<string, mixed>
     */
    private function hubData(Request $request): array
    {
        return $request->validate([
            'name' => ['required', 'string', 'max:160'],
            'type' => ['required', 'in:campus,mall,airport,station,office,municipal'],
            'address' => ['nullable', 'string'],
            'lat' => ['nullable', 'numeric'],
            'lng' => ['nullable', 'numeric'],
            'hours_json' => ['nullable', 'array'],
            'is_public' => ['boolean'],
            'retention_days' => ['integer', 'min:1'],
            'capacity' => ['integer', 'min:1'],
            'organization_id' => ['nullable', 'exists:organizations,id'],
            'contact_internal' => ['nullable', 'string'],
        ]);
    }
}
