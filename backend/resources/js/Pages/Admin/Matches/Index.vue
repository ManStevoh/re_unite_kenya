<script setup lang="ts">
import AdminLayout from '../../../Layouts/AdminLayout.vue';
import Pager from '../../../Components/Pager.vue';
import { router } from '@inertiajs/vue3';
import type { Paginator } from '../../../types';

defineOptions({ layout: AdminLayout });
defineProps<{ matches: Paginator<any> }>();
function setStatus(id: number, status: string) {
    router.post(`/admin/matches/${id}`, { status });
}
</script>

<template>
    <div>
        <h1 class="text-2xl font-semibold">Matches</h1>
        <div class="mt-6 overflow-x-auto rounded-xl bg-paper">
            <table class="w-full text-left text-sm">
                <thead class="text-ink/50"><tr><th class="px-4 py-3">Lost</th><th>Found</th><th>Score</th><th>Status</th><th></th></tr></thead>
                <tbody>
                    <tr v-for="row in matches.data" :key="row.id" class="border-t border-mist">
                        <td class="px-4 py-3">{{ row.lost?.title }}</td>
                        <td>{{ row.found?.title }}</td>
                        <td>{{ row.score }}</td>
                        <td>{{ row.status }}</td>
                        <td class="space-x-2">
                            <button class="btn btn-ghost" @click="setStatus(row.id, 'notified')">Notify</button>
                            <button class="btn btn-ghost" @click="setStatus(row.id, 'dismissed')">Dismiss</button>
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>
        <Pager :pager="matches" />
    </div>
</template>
