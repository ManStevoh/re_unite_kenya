<?php

namespace App\Http\Controllers;

use App\Domain\Search\SearchEngine;
use App\Models\Category;
use App\Models\CmsPage;
use App\Models\ItemReport;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Inertia\Response;

class PublicWebController extends Controller
{
    public function home(): Response
    {
        return Inertia::render('Public/Home');
    }

    public function search(Request $request, SearchEngine $search): Response
    {
        $results = $search->search($request->only(['q', 'type', 'category_id']));

        return Inertia::render('Public/Search', [
            'filters' => $request->only(['q', 'type', 'category_id']),
            'categories' => Category::query()->orderBy('sort_order')->get(['id', 'name']),
            'results' => $results->through(fn (ItemReport $r) => $r->toTeaserDto()),
        ]);
    }

    public function teaser(ItemReport $report): Response
    {
        abort_unless($report->visibility === 'public_teaser' && in_array($report->status, ['published', 'matched', 'claim_in_progress'], true), 404);
        $report->load(['category', 'hub', 'media']);

        return Inertia::render('Public/Teaser', [
            'item' => $report->toTeaserDto(),
        ]);
    }

    public function cms(string $slug): Response
    {
        $page = CmsPage::query()->where('slug', $slug)->where('published', true)->firstOrFail();

        return Inertia::render('Public/Cms', [
            'page' => $page->toPublicDto(),
        ]);
    }
}
