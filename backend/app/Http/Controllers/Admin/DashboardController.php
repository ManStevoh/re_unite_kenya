<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Claim;
use App\Models\Flag;
use App\Models\Hub;
use App\Models\ItemReport;
use App\Models\MatchCandidate;
use Inertia\Inertia;
use Inertia\Response;

class DashboardController extends Controller
{
    public function __invoke(): Response
    {
        $openLost = ItemReport::query()->where('type', 'lost')->whereNotIn('status', ['recovered', 'closed', 'expired', 'rejected'])->count();
        $openFound = ItemReport::query()->where('type', 'found')->whereNotIn('status', ['recovered', 'closed', 'expired', 'rejected'])->count();

        return Inertia::render('Admin/Dashboard', [
            'stats' => [
                'open_lost' => $openLost,
                'open_found' => $openFound,
                'awaiting_review' => ItemReport::query()->whereIn('status', ['submitted', 'under_review'])->count(),
                'claims_awaiting' => Claim::query()->whereIn('status', ['submitted', 'in_review', 'needs_info'])->count(),
                'returns_7' => ItemReport::query()->where('status', 'recovered')->where('updated_at', '>=', now()->subDays(7))->count(),
                'returns_30' => ItemReport::query()->where('status', 'recovered')->where('updated_at', '>=', now()->subDays(30))->count(),
                'flags_open' => Flag::query()->where('status', 'open')->count(),
                'matches' => MatchCandidate::query()->count(),
            ],
            'hubs' => Hub::query()->get()->map(fn (Hub $hub) => [
                'id' => $hub->id,
                'name' => $hub->name,
                'occupancy' => $hub->occupancy(),
                'capacity' => $hub->capacity,
            ]),
            'funnel' => [
                'users' => \App\Models\User::query()->count(),
                'verified' => \App\Models\User::query()->whereNotNull('email_verified_at')->count(),
                'reports' => ItemReport::query()->count(),
                'matches' => MatchCandidate::query()->count(),
                'returns' => ItemReport::query()->where('status', 'recovered')->count(),
            ],
            'queue' => ItemReport::query()
                ->with(['category', 'user'])
                ->whereIn('status', ['submitted', 'under_review'])
                ->latest()
                ->limit(10)
                ->get()
                ->map(fn (ItemReport $r) => [
                    'id' => $r->id,
                    'title' => $r->title,
                    'type' => $r->type,
                    'status' => $r->status,
                    'category' => $r->category?->name,
                    'reporter' => $r->user?->display_name,
                    'created_at' => $r->created_at?->toDateTimeString(),
                ]),
        ]);
    }
}
