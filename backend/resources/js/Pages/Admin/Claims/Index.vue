<script setup lang="ts">
import AdminLayout from '../../../Layouts/AdminLayout.vue';
import Pager from '../../../Components/Pager.vue';
import { Link } from '@inertiajs/vue3';
import type { Paginator } from '../../../types';

defineOptions({ layout: AdminLayout });
defineProps<{ claims: Paginator<any> }>();
</script>

<template>
    <div>
        <h1 class="text-2xl font-semibold">Claims queue</h1>
        <div class="mt-6 overflow-x-auto rounded-xl bg-paper">
            <table class="w-full text-left text-sm">
                <thead class="text-ink/50"><tr><th class="px-4 py-3">Item</th><th>Claimant</th><th>Status</th><th>Attempts</th></tr></thead>
                <tbody>
                    <tr v-for="row in claims.data" :key="row.id" class="border-t border-mist">
                        <td class="px-4 py-3"><Link :href="`/admin/claims/${row.id}`">{{ row.title }}</Link></td>
                        <td>{{ row.claimant }}</td>
                        <td>{{ row.status }}</td>
                        <td>{{ row.attempts }}</td>
                    </tr>
                </tbody>
            </table>
        </div>
        <Pager :pager="claims" />
    </div>
</template>
