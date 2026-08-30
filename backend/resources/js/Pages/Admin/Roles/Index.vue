<script setup lang="ts">
import AdminLayout from '../../../Layouts/AdminLayout.vue';
import { router } from '@inertiajs/vue3';
import { reactive } from 'vue';

defineOptions({ layout: AdminLayout });
const props = defineProps<{ roles: { id: number; name: string; permissions: string[] }[]; permissions: string[] }>();
const local = reactive<Record<number, string[]>>(
    Object.fromEntries(props.roles.map((r) => [r.id, [...r.permissions]]))
);

function toggle(roleId: number, perm: string) {
    const set = new Set(local[roleId] || []);
    set.has(perm) ? set.delete(perm) : set.add(perm);
    local[roleId] = [...set];
}

function save(roleId: number) {
    router.post(`/admin/roles/${roleId}`, { permissions: local[roleId] });
}
</script>

<template>
    <div>
        <h1 class="text-2xl font-semibold">Roles & permissions</h1>
        <div class="mt-6 overflow-x-auto rounded-xl bg-paper p-4">
            <table class="w-full text-left text-xs">
                <thead>
                    <tr>
                        <th class="py-2">Permission</th>
                        <th v-for="role in roles" :key="role.id">{{ role.name }}</th>
                    </tr>
                </thead>
                <tbody>
                    <tr v-for="perm in permissions" :key="perm" class="border-t border-mist">
                        <td class="py-2 font-mono">{{ perm }}</td>
                        <td v-for="role in roles" :key="role.id + perm">
                            <input type="checkbox" :checked="local[role.id]?.includes(perm)" @change="toggle(role.id, perm)">
                        </td>
                    </tr>
                </tbody>
            </table>
            <div class="mt-4 flex flex-wrap gap-2">
                <button v-for="role in roles" :key="role.id" class="btn btn-primary" @click="save(role.id)">Save {{ role.name }}</button>
            </div>
        </div>
    </div>
</template>
