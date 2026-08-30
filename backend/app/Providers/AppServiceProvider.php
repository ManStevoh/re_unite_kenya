<?php

namespace App\Providers;

use App\Domain\Matching\DeterministicMatchingEngine;
use App\Domain\Matching\MatchingEngine;
use App\Domain\Search\DatabaseSearchEngine;
use App\Domain\Search\SearchEngine;
use App\Models\Claim;
use App\Models\Conversation;
use App\Models\Handover;
use App\Models\ItemReport;
use App\Models\MediaAsset;
use App\Policies\ClaimPolicy;
use App\Policies\ConversationPolicy;
use App\Policies\HandoverPolicy;
use App\Policies\ItemReportPolicy;
use App\Policies\MediaAssetPolicy;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->bind(MatchingEngine::class, DeterministicMatchingEngine::class);
        $this->app->bind(SearchEngine::class, DatabaseSearchEngine::class);
    }

    public function boot(): void
    {
        Gate::policy(ItemReport::class, ItemReportPolicy::class);
        Gate::policy(Claim::class, ClaimPolicy::class);
        Gate::policy(Conversation::class, ConversationPolicy::class);
        Gate::policy(MediaAsset::class, MediaAssetPolicy::class);
        Gate::policy(Handover::class, HandoverPolicy::class);

        RateLimiter::for('login', fn (Request $request) => Limit::perMinute(8)->by($request->ip()));
        RateLimiter::for('otp', fn (Request $request) => Limit::perMinute(5)->by($request->ip().'|'.$request->input('phone', '')));
        RateLimiter::for('claims', fn (Request $request) => Limit::perMinute(10)->by(optional($request->user())->id ?: $request->ip()));
        RateLimiter::for('search', fn (Request $request) => Limit::perMinute(30)->by(optional($request->user())->id ?: $request->ip()));
    }
}
