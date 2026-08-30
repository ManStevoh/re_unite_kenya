<script setup lang="ts">
import AdminLayout from '../../../Layouts/AdminLayout.vue';
defineOptions({ layout: AdminLayout });
defineProps<{ logs: any }>();
</script>

<template>
    <div>
        <h1 class="text-2xl font-semibold">Delivery logs</h1>
        <div class="mt-6 overflow-x-auto rounded-xl bg-paper">
            <table class="w-full text-left text-sm">
                <thead class="text-ink/50"><tr><th class="px-4 py-3">Channel</th><th>Event</th><th>Recipient</th><th>Status</th><th>When</th></tr></thead>
                <tbody>
                    <tr v-for="row in logs.data" :key="row.id" class="border-t border-mist">
                        <td class="px-4 py-3">{{ row.channel }}</td>
                        <td>{{ row.event }}</td>
                        <td>{{ row.recipient_masked }}</td>
                        <td>{{ row.status }}</td>
                        <td>{{ row.created_at }}</td>
                    </tr>
                </tbody>
            </table>
        </div>
    </div>
</template>
