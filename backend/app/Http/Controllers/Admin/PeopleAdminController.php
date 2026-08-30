<?php

namespace App\Http\Controllers\Admin;

use App\Domain\Audit\Auditor;
use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;
use Inertia\Inertia;
use Inertia\Response;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\Models\Role;

class PeopleAdminController extends Controller
{
    public function users(Request $request): Response
    {
        $query = User::query()->with('roles');
        if ($request->filled('q')) {
            $q = '%'.$request->string('q').'%';
            $query->where(fn ($b) => $b->where('email', 'like', $q)->orWhere('name', 'like', $q)->orWhere('phone', 'like', $q)->orWhere('display_name', 'like', $q));
        }
        if ($request->filled('status')) {
            $query->where('status', $request->string('status'));
        }

        return Inertia::render('Admin/Users/Index', [
            'users' => $query->latest()->paginate(20)->through(fn (User $u) => [
                'id' => $u->id,
                'name' => $u->name,
                'display_name' => $u->display_name,
                'email' => $this->maskEmail($u->email),
                'phone' => $u->phone ? '***'.substr($u->phone, -4) : null,
                'status' => $u->status,
                'trust_score' => $u->trust_score,
                'roles' => $u->getRoleNames(),
                'city' => $u->city,
            ]),
        ]);
    }

    public function showUser(User $user): Response
    {
        $user->load(['roles', 'devices', 'reports', 'claims']);

        return Inertia::render('Admin/Users/Show', [
            'user' => $user->toPrivateDto() + [
                'devices' => $user->devices,
                'reports' => $user->reports->map->toTeaserDto(),
                'claims' => $user->claims,
                'roles' => $user->getRoleNames(),
                'available_roles' => Role::query()->pluck('name'),
            ],
        ]);
    }

    public function updateUser(Request $request, User $user): RedirectResponse
    {
        $data = $request->validate([
            'status' => ['sometimes', Rule::in(['pending_verification', 'active', 'restricted', 'suspended', 'banned', 'deactivated'])],
            'verification_level' => ['sometimes', 'integer', 'min:0', 'max:4'],
            'id_verification_status' => ['sometimes', 'string'],
            'roles' => ['sometimes', 'array'],
            'roles.*' => ['string'],
        ]);

        if (isset($data['status'])) {
            $user->status = $data['status'];
        }
        if (isset($data['verification_level'])) {
            $user->verification_level = $data['verification_level'];
        }
        if (isset($data['id_verification_status'])) {
            $user->id_verification_status = $data['id_verification_status'];
        }
        $user->save();

        if (isset($data['roles']) && $request->user()->can('users.assign_roles')) {
            $user->syncRoles($data['roles']);
        }

        if ($request->boolean('verify_phone')) {
            $user->forceFill(['phone_verified_at' => now(), 'verification_level' => max($user->verification_level, 3)])->save();
        }

        Auditor::record('user.update', $user, $data, $request->user());

        return back()->with('success', 'User updated.');
    }

    public function roles(): Response
    {
        $roles = Role::query()->with('permissions')->get();
        $permissions = Permission::query()->orderBy('name')->pluck('name');

        return Inertia::render('Admin/Roles/Index', [
            'roles' => $roles->map(fn (Role $r) => [
                'id' => $r->id,
                'name' => $r->name,
                'permissions' => $r->permissions->pluck('name'),
            ]),
            'permissions' => $permissions,
        ]);
    }

    public function updateRole(Request $request, Role $role): RedirectResponse
    {
        abort_unless($request->user()->hasRole('super_admin'), 403);
        $data = $request->validate(['permissions' => ['required', 'array']]);
        $role->syncPermissions($data['permissions']);
        Auditor::record('role.update', null, ['role' => $role->name, 'permissions' => $data['permissions']], $request->user());

        return back()->with('success', 'Role updated.');
    }

    public function inviteForm(): Response
    {
        return Inertia::render('Admin/Staff/Invite', [
            'roles' => Role::query()->whereIn('name', ['hub_staff', 'hub_manager', 'moderator', 'support', 'admin', 'super_admin'])->pluck('name'),
            'hubs' => \App\Models\Hub::query()->get(['id', 'name']),
        ]);
    }

    public function invite(Request $request): RedirectResponse
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:120'],
            'email' => ['required', 'email', 'unique:users,email'],
            'role' => ['required', 'string'],
            'hub_id' => ['nullable', 'exists:hubs,id'],
            'password' => ['required', 'string', 'min:8'],
        ]);

        $user = User::query()->create([
            'name' => $data['name'],
            'display_name' => $data['name'],
            'email' => $data['email'],
            'password' => $data['password'],
            'status' => 'active',
            'verification_level' => 3,
            'email_verified_at' => now(),
        ]);
        $user->assignRole($data['role']);
        if (! empty($data['hub_id'])) {
            $user->staffedHubs()->attach($data['hub_id'], ['role' => $data['role']]);
        }
        Auditor::record('staff.invite', $user, ['role' => $data['role']], $request->user());

        return redirect('/admin/users/'.$user->id)->with('success', 'Staff account created.');
    }

    public function account(): Response
    {
        return Inertia::render('Admin/Account', [
            'user' => request()->user()->toPrivateDto(),
        ]);
    }

    public function updateAccount(Request $request): RedirectResponse
    {
        $data = $request->validate([
            'display_name' => ['required', 'string', 'max:80'],
            'locale' => ['nullable', 'string', 'max:8'],
            'current_password' => ['nullable', 'required_with:password', 'current_password'],
            'password' => ['nullable', 'confirmed', 'min:8'],
        ]);
        $user = $request->user();
        $user->display_name = $data['display_name'];
        if (! empty($data['locale'])) {
            $user->locale = $data['locale'];
        }
        if (! empty($data['password'])) {
            $user->password = $data['password'];
        }
        $user->save();

        return back()->with('success', 'Account updated. 2FA can be enabled later.');
    }

    private function maskEmail(string $email): string
    {
        [$name, $domain] = explode('@', $email, 2);

        return substr($name, 0, 1).'***@'.$domain;
    }
}
