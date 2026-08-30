<?php

namespace App\Http\Controllers\Admin;

use App\Domain\Audit\Auditor;
use App\Domain\Notifications\PlatformNotifier;
use App\Http\Controllers\Controller;
use App\Models\AuditLog;
use App\Models\Claim;
use App\Models\CmsPage;
use App\Models\DeliveryLog;
use App\Models\ItemReport;
use App\Models\MatchCandidate;
use App\Models\Setting;
use App\Models\User;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Inertia\Inertia;
use Inertia\Response;
use Spatie\Permission\Models\Role;
use Symfony\Component\HttpFoundation\StreamedResponse;

class SystemAdminController extends Controller
{
    public function cms(): Response
    {
        return Inertia::render('Admin/Cms/Index', [
            'pages' => CmsPage::query()->orderBy('slug')->get(),
        ]);
    }

    public function storeCms(Request $request): RedirectResponse
    {
        $data = $request->validate([
            'slug' => ['required', 'alpha_dash', 'unique:cms_pages,slug'],
            'title' => ['required', 'string'],
            'body' => ['nullable', 'string'],
            'published' => ['boolean'],
        ]);
        CmsPage::query()->create($data);

        return back()->with('success', 'Page created.');
    }

    public function updateCms(Request $request, CmsPage $page): RedirectResponse
    {
        $data = $request->validate([
            'title' => ['required', 'string'],
            'body' => ['nullable', 'string'],
            'published' => ['boolean'],
        ]);
        $page->update($data);
        Auditor::record('cms.update', $page, [], $request->user());

        return back()->with('success', 'Page updated.');
    }

    public function composer(): Response
    {
        return Inertia::render('Admin/Notifications/Composer', [
            'roles' => Role::query()->pluck('name'),
            'hubs' => \App\Models\Hub::query()->get(['id', 'name']),
        ]);
    }

    public function compose(Request $request, PlatformNotifier $notifier): RedirectResponse
    {
        $data = $request->validate([
            'title' => ['required', 'string'],
            'body' => ['required', 'string'],
            'audience' => ['required', 'in:all,city,hub,role'],
            'city' => ['nullable', 'string'],
            'hub_id' => ['nullable', 'exists:hubs,id'],
            'role' => ['nullable', 'string'],
        ]);

        $users = User::query()->where('status', 'active');
        if ($data['audience'] === 'city' && $data['city']) {
            $users->where('city', $data['city']);
        }
        if ($data['audience'] === 'role' && $data['role']) {
            $users->role($data['role']);
        }
        if ($data['audience'] === 'hub' && $data['hub_id']) {
            $users->whereHas('staffedHubs', fn ($q) => $q->where('hubs.id', $data['hub_id']));
        }

        $count = $notifier->broadcast($users->get(), 'admin_broadcast', $data['title'], $data['body']);
        Auditor::record('notification.compose', null, ['count' => $count, ...$data], $request->user());

        return back()->with('success', "Notification sent to {$count} users.");
    }

    public function deliveryLogs(): Response
    {
        return Inertia::render('Admin/Notifications/Logs', [
            'logs' => DeliveryLog::query()->latest()->paginate(30),
        ]);
    }

    public function analytics(): Response
    {
        return Inertia::render('Admin/Analytics', [
            'counts' => [
                'lost' => ItemReport::query()->where('type', 'lost')->count(),
                'found' => ItemReport::query()->where('type', 'found')->count(),
                'matches' => MatchCandidate::query()->count(),
                'claims_approved' => Claim::query()->where('status', 'approved')->count(),
                'claims_rejected' => Claim::query()->where('status', 'rejected')->count(),
                'returns' => ItemReport::query()->where('status', 'recovered')->count(),
                'users' => User::query()->count(),
            ],
        ]);
    }

    public function exports(): Response
    {
        return Inertia::render('Admin/Exports');
    }

    public function downloadExport(Request $request): StreamedResponse
    {
        Auditor::record('export.reports', null, [], $request->user());
        $filename = 'reports-'.now()->format('Ymd-His').'.csv';

        return response()->streamDownload(function () {
            $out = fopen('php://output', 'w');
            fputcsv($out, ['id', 'type', 'title', 'status', 'category_id', 'area', 'occurred_at', 'user_id']);
            ItemReport::query()->orderBy('id')->chunk(200, function ($rows) use ($out) {
                foreach ($rows as $row) {
                    fputcsv($out, [$row->id, $row->type, $row->title, $row->status, $row->category_id, $row->area, $row->occurred_at, $row->user_id]);
                }
            });
            fclose($out);
        }, $filename, ['Content-Type' => 'text/csv']);
    }

    public function audit(Request $request): Response
    {
        $query = AuditLog::query()->with('actor')->latest();
        if ($request->filled('action')) {
            $query->where('action', 'like', '%'.$request->string('action').'%');
        }

        return Inertia::render('Admin/Audit/Index', [
            'logs' => $query->paginate(40)->through(fn (AuditLog $l) => [
                'id' => $l->id,
                'action' => $l->action,
                'actor' => $l->actor?->display_name,
                'subject_type' => class_basename((string) $l->subject_type),
                'subject_id' => $l->subject_id,
                'ip' => $l->ip_address,
                'created_at' => $l->created_at?->toDateTimeString(),
                'properties' => $l->properties,
            ]),
        ]);
    }

    public function settings(): Response
    {
        return Inertia::render('Admin/Settings', [
            'settings' => Setting::query()->get()->mapWithKeys(fn (Setting $s) => [$s->key => $s->value_json]),
        ]);
    }

    public function updateSettings(Request $request): RedirectResponse
    {
        $data = $request->validate(['settings' => ['required', 'array']]);
        foreach ($data['settings'] as $key => $value) {
            Setting::setValue((string) $key, $value);
        }
        Auditor::record('settings.update', null, array_keys($data['settings']), $request->user());

        return back()->with('success', 'Settings saved.');
    }

    public function flags(): Response
    {
        return Inertia::render('Admin/FeatureFlags', [
            'flags' => Setting::getValue('feature_flags', []),
        ]);
    }

    public function updateFlags(Request $request): RedirectResponse
    {
        $data = $request->validate(['flags' => ['required', 'array']]);
        Setting::setValue('feature_flags', $data['flags']);
        Cache::forget('setting:feature_flags');

        return back()->with('success', 'Feature flags saved.');
    }

    public function maintenance(): Response
    {
        return Inertia::render('Admin/Maintenance', [
            'banner' => Setting::getValue('maintenance_banner'),
            'read_only' => Setting::getValue('read_only', false),
        ]);
    }

    public function updateMaintenance(Request $request): RedirectResponse
    {
        $data = $request->validate([
            'banner' => ['nullable', 'array'],
            'banner.enabled' => ['boolean'],
            'banner.text' => ['nullable', 'string'],
            'read_only' => ['boolean'],
        ]);
        Setting::setValue('maintenance_banner', $data['banner'] ?? null);
        Setting::setValue('read_only', $data['read_only'] ?? false);

        return back()->with('success', 'Maintenance settings saved.');
    }
}
