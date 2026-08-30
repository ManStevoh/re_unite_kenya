<script setup lang="ts">
import AdminLayout from '../../../Layouts/AdminLayout.vue';
import { Link } from '@inertiajs/vue3';
defineOptions({ layout: AdminLayout });
defineProps<{ disputes: any }>();
</script>

<template>
    <div>
        <h1 class="text-2xl font-semibold">Disputes</h1>
        <div class="mt-6 overflow-x-auto rounded-xl bg-paper">
            <table class="w-full text-left text-sm">
                <thead class="text-ink/50"><tr><th class="px-4 py-3">Item</th><th>Type</th><th>Status</th></tr></thead>
                <tbody>
                    <tr v-for="row in disputes.data" :key="row.id" class="border-t border-mist">
                        <td class="px-4 py-3"><Link :href="`/admin/disputes/${row.id}`">{{ row.title }}</Link></td>
                        <td>{{ row.type }}</td>
                        <td>{{ row.status }}</td>
                    </tr>
                </tbody>
            </table>
        </div>
    </div>
</template>
