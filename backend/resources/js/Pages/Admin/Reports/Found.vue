<script setup lang="ts">
import AdminLayout from '../../../Layouts/AdminLayout.vue';
import Pager from '../../../Components/Pager.vue';
import { Link, router } from '@inertiajs/vue3';
import { ref } from 'vue';
import type { Paginator } from '../../../types';

defineOptions({ layout: AdminLayout });
const props = defineProps<{ reports: Paginator<any>; filters: { q?: string } }>();
const q = ref(props.filters.q || '');
</script>

<template>
    <div>
        <h1 class="text-2xl font-semibold">Found reports</h1>
        <form class="mt-4 flex gap-2" @submit.prevent="router.get('/admin/reports/found', { q })">
            <input v-model="q" class="input max-w-sm" placeholder="Search">
            <button class="btn btn-primary">Search</button>
        </form>
        <div class="mt-6 overflow-x-auto rounded-xl bg-paper">
            <table class="w-full text-left text-sm">
                <thead class="text-ink/50"><tr><th class="px-4 py-3">Title</th><th>Status</th><th>Hub</th><th>Custody</th><th>Storage</th></tr></thead>
                <tbody>
                    <tr v-for="row in reports.data" :key="row.id" class="border-t border-mist">
                        <td class="px-4 py-3"><Link :href="`/admin/reports/${row.id}`">{{ row.title }}</Link></td>
                        <td>{{ row.status }}</td>
                        <td>{{ row.hub }}</td>
                        <td>{{ row.custody }}</td>
                        <td>{{ row.storage_code }}</td>
                    </tr>
                </tbody>
            </table>
        </div>
        <Pager :pager="reports" />
    </div>
</template>
