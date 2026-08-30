<script setup lang="ts">
import AdminLayout from '../../../Layouts/AdminLayout.vue';
import Pager from '../../../Components/Pager.vue';
import { Link } from '@inertiajs/vue3';
import type { Paginator } from '../../../types';

defineOptions({ layout: AdminLayout });
defineProps<{
    reports: Paginator<{ id: number; title: string; type: string; status: string; area?: string; category?: string; reporter?: string; trust?: number; created_at?: string }>;
}>();
</script>

<template>
    <div>
        <h1 class="text-2xl font-semibold">Listings review</h1>
        <div class="mt-6 overflow-x-auto rounded-xl bg-paper">
            <table class="w-full text-left text-sm">
                <thead class="text-ink/50">
                    <tr>
                        <th class="px-4 py-3">Title</th><th>Type</th><th>Category</th><th>Area</th><th>Trust</th><th>Age</th>
                    </tr>
                </thead>
                <tbody>
                    <tr v-for="row in reports.data" :key="row.id" class="border-t border-mist">
                        <td class="px-4 py-3"><Link :href="`/admin/reports/${row.id}`" class="font-medium">{{ row.title }}</Link></td>
                        <td>{{ row.type }}</td>
                        <td>{{ row.category }}</td>
                        <td>{{ row.area }}</td>
                        <td>{{ row.trust }}</td>
                        <td>{{ row.created_at }}</td>
                    </tr>
                </tbody>
            </table>
        </div>
        <Pager :pager="reports" />
    </div>
</template>
