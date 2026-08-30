<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\Models\Role;
use Spatie\Permission\PermissionRegistrar;

class RolePermissionSeeder extends Seeder
{
    public function run(): void
    {
        app()[PermissionRegistrar::class]->forgetCachedPermissions();

        $permissions = [
            'users.view', 'users.update_status', 'users.assign_roles',
            'reports.view', 'reports.view_hidden', 'reports.moderate', 'reports.force_status',
            'matches.view', 'matches.force',
            'claims.view', 'claims.view_answers', 'claims.decide',
            'handovers.view', 'handovers.manage',
            'chat.read_flagged',
            'flags.manage', 'disputes.manage',
            'hubs.manage', 'categories.manage', 'cms.manage',
            'notifications.compose', 'analytics.view', 'exports.create',
            'audit.view', 'settings.manage',
        ];

        foreach ($permissions as $name) {
            Permission::findOrCreate($name, 'web');
        }

        $matrix = [
            'user' => [],
            'hub_staff' => ['reports.view', 'reports.view_hidden', 'claims.view', 'claims.view_answers', 'handovers.view', 'handovers.manage'],
            'hub_manager' => ['reports.view', 'reports.view_hidden', 'claims.view', 'claims.view_answers', 'claims.decide', 'handovers.view', 'handovers.manage', 'hubs.manage', 'analytics.view'],
            'moderator' => ['users.view', 'reports.view', 'reports.view_hidden', 'reports.moderate', 'matches.view', 'matches.force', 'claims.view', 'claims.view_answers', 'claims.decide', 'handovers.view', 'chat.read_flagged', 'flags.manage', 'disputes.manage'],
            'support' => ['users.view', 'users.update_status', 'reports.view', 'reports.view_hidden', 'claims.view', 'claims.view_answers', 'handovers.view', 'chat.read_flagged'],
            'admin' => $permissions,
            'super_admin' => $permissions,
        ];

        foreach ($matrix as $role => $perms) {
            $model = Role::findOrCreate($role, 'web');
            $model->syncPermissions($perms);
        }
    }
}
