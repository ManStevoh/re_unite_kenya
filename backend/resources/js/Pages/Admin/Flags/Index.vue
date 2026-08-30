<script setup lang="ts">
import AdminLayout from '../../../Layouts/AdminLayout.vue';
import Pager from '../../../Components/Pager.vue';
import { router } from '@inertiajs/vue3';
defineOptions({ layout: AdminLayout });
defineProps<{ flags: any }>();
</script>

<template>
    <div>
        <h1 class="text-2xl font-semibold">Abuse flags</h1>
        <div class="mt-6 overflow-x-auto rounded-xl bg-paper">
            <table class="w-full text-left text-sm">
                <thead class="text-ink/50"><tr><th class="px-4 py-3">Reason</th><th>Target</th><th>Reporter</th><th>Severity</th><th>Status</th><th></th></tr></thead>
                <tbody>
                    <tr v-for="row in flags.data" :key="row.id" class="border-t border-mist">
                        <td class="px-4 py-3">{{ row.reason }}</td>
                        <td>{{ row.target_type }} #{{ row.target_id }}</td>
                        <td>{{ row.reporter }}</td>
                        <td>{{ row.severity }}</td>
                        <td>{{ row.status }}</td>
                        <td><button class="btn btn-ghost" @click="router.post(`/admin/flags/${row.id}`, { status: 'reviewed' })">Review</button></td>
                    </tr>
                </tbody>
            </table>
        </div>
        <Pager :pager="flags" />
    </div>
</template>
