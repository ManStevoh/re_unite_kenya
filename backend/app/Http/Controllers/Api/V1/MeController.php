<?php

namespace App\Http\Controllers\Api\V1;

use App\Domain\Audit\Auditor;
use App\Domain\Auth\TokenService;
use App\Http\Controllers\Controller;
use App\Models\Device;
use App\Models\User;
use App\Models\UserBlock;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MeController extends Controller
{
    public function show(Request $request): JsonResponse
    {
        return response()->json(['user' => $request->user()->toPrivateDto()]);
    }

    public function update(Request $request): JsonResponse
    {
        $user = $request->user();
        $data = $request->validate([
            'display_name' => ['sometimes', 'string', 'max:80'],
            'city' => ['sometimes', 'nullable', 'string', 'max:120'],
            'locale' => ['sometimes', 'string', 'max:8'],
            'avatar_path' => ['sometimes', 'nullable', 'string', 'max:255'],
            'current_password' => ['sometimes', 'required_with:password', 'current_password'],
            'password' => ['sometimes', 'confirmed', 'min:8'],
        ]);

        $user->fill(collect($data)->only(['display_name', 'city', 'locale', 'avatar_path'])->all());
        if (! empty($data['password'])) {
            $user->password = $data['password'];
        }
        $user->save();

        return response()->json(['user' => $user->fresh()->toPrivateDto()]);
    }

    public function devices(Request $request): JsonResponse
    {
        return response()->json([
            'data' => $request->user()->devices()->latest('last_seen_at')->get(),
        ]);
    }

    public function destroyDevice(Request $request, Device $device): JsonResponse
    {
        abort_unless($device->user_id === $request->user()->id, 403);
        if ($device->token_id) {
            $request->user()->tokens()->where('id', $device->token_id)->delete();
        }
        $device->delete();

        return response()->json(['message' => 'Device revoked.']);
    }

    public function notificationPreferences(Request $request): JsonResponse
    {
        return response()->json(['preferences' => $request->user()->notificationPreferences()]);
    }

    public function updateNotificationPreferences(Request $request): JsonResponse
    {
        $data = $request->validate([
            'preferences' => ['required', 'array'],
        ]);

        $user = $request->user();
        $user->notification_preferences = array_replace_recursive($user->notificationPreferences(), $data['preferences']);
        $user->save();

        return response()->json(['preferences' => $user->notificationPreferences()]);
    }

    public function dataExport(Request $request): JsonResponse
    {
        $user = $request->user();
        Auditor::record('user.data_export', $user, [], $user);

        return response()->json([
            'user' => $user->toPrivateDto(),
            'reports' => $user->reports()->get()->map->toFullDto($user),
            'claims' => $user->claims()->with('itemReport')->get(),
        ]);
    }

    public function deactivate(Request $request): JsonResponse
    {
        $user = $request->user();
        $user->update(['status' => 'deactivated']);
        Auditor::record('user.deactivate', $user, [], $user);
        app(TokenService::class)->revokeAll($user);

        return response()->json(['message' => 'Account deactivated.']);
    }

    public function destroy(Request $request): JsonResponse
    {
        $user = $request->user();
        $user->update(['status' => 'deactivated']);
        $user->delete();
        Auditor::record('user.delete', $user, [], $user);
        app(TokenService::class)->revokeAll($user);

        return response()->json(['message' => 'Account scheduled for deletion.']);
    }

    public function password(Request $request): JsonResponse
    {
        $data = $request->validate([
            'current_password' => ['required', 'current_password'],
            'password' => ['required', 'confirmed', 'min:8'],
        ]);
        $request->user()->update(['password' => $data['password']]);

        return response()->json(['message' => 'Password updated.']);
    }

    public function reports(Request $request): JsonResponse
    {
        $rows = $request->user()->reports()->with(['category', 'hub', 'media'])->latest()->get();

        return response()->json([
            'data' => $rows->map(fn ($r) => $r->toFullDto($request->user()))->values(),
        ]);
    }

    public function drafts(Request $request): JsonResponse
    {
        $rows = $request->user()->reports()->with(['category', 'hub', 'media'])->where('status', 'draft')->latest()->get();

        return response()->json([
            'data' => $rows->map(fn ($r) => $r->toFullDto($request->user()))->values(),
        ]);
    }

    public function activity(Request $request): JsonResponse
    {
        $notes = $request->user()->notifications()->latest()->limit(40)->get();

        return response()->json([
            'data' => $notes->map(fn ($n) => [
                'id' => $n->id,
                'kind' => $n->data['event'] ?? 'system',
                'title' => $n->data['title'] ?? 'Update',
                'subtitle' => $n->data['body'] ?? '',
                'at' => $n->created_at?->toIso8601String(),
                'route' => $this->activityRoute($n->data ?? []),
            ])->values(),
        ]);
    }

    public function block(Request $request): JsonResponse
    {
        $data = $request->validate([
            'user_id' => ['required', 'exists:users,id'],
        ]);
        abort_if((int) $data['user_id'] === $request->user()->id, 422, 'You cannot block yourself.');
        UserBlock::query()->firstOrCreate([
            'user_id' => $request->user()->id,
            'blocked_user_id' => $data['user_id'],
        ]);
        Auditor::record('user.block', User::query()->find($data['user_id']), [], $request->user());

        return response()->json(['message' => 'User blocked.']);
    }

    public function support(Request $request): JsonResponse
    {
        $data = $request->validate([
            'subject' => ['required', 'string', 'max:160'],
            'body' => ['required', 'string', 'max:4000'],
        ]);
        Auditor::record('support.contact', $request->user(), $data, $request->user());

        return response()->json(['message' => 'Received. A support agent will reply in-app.']);
    }

    /**
     * @param  array<string, mixed>  $data
     */
    private function activityRoute(array $data): ?string
    {
        $payload = $data['data'] ?? [];
        if (! empty($payload['claim_id'])) {
            return '/claims/'.$payload['claim_id'];
        }
        if (! empty($payload['report_id'])) {
            return '/reports/'.$payload['report_id'];
        }
        if (! empty($payload['conversation_id'])) {
            return '/inbox/'.$payload['conversation_id'];
        }

        return null;
    }
}
