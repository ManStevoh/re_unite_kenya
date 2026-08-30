<script setup lang="ts">
import AdminLayout from '../../../Layouts/AdminLayout.vue';
import Pager from '../../../Components/Pager.vue';
import { Link, router } from '@inertiajs/vue3';
import { ref } from 'vue';
defineOptions({ layout: AdminLayout });
const props = defineProps<{ users: any }>();
const q = ref('');
</script>

<template>
    <div>
        <h1 class="text-2xl font-semibold">Users</h1>
        <form class="mt-4 flex gap-2" @submit.prevent="router.get('/admin/users', { q: q })">
            <input v-model="q" class="input max-w-sm" placeholder="Email, phone, name">
            <button class="btn btn-primary">Search</button>
        </form>
        <div class="mt-6 overflow-x-auto rounded-xl bg-paper">
            <table class="w-full text-left text-sm">
                <thead class="text-ink/50"><tr><th class="px-4 py-3">Name</th><th>Email</th><th>Status</th><th>Trust</th><th>Roles</th></tr></thead>
                <tbody>
                    <tr v-for="row in users.data" :key="row.id" class="border-t border-mist">
                        <td class="px-4 py-3"><Link :href="`/admin/users/${row.id}`">{{ row.display_name }}</Link></td>
                        <td>{{ row.email }}</td>
                        <td>{{ row.status }}</td>
                        <td>{{ row.trust_score }}</td>
                        <td>{{ row.roles?.join(', ') }}</td>
                    </tr>
                </tbody>
            </table>
        </div>
        <Pager :pager="users" />
    </div>
</template>
