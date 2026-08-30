<script setup lang="ts">
import AdminLayout from '../../../Layouts/AdminLayout.vue';
import Pager from '../../../Components/Pager.vue';
defineOptions({ layout: AdminLayout });
defineProps<{ handovers: any }>();
</script>

<template>
    <div>
        <h1 class="text-2xl font-semibold">Handovers</h1>
        <div class="mt-6 overflow-x-auto rounded-xl bg-paper">
            <table class="w-full text-left text-sm">
                <thead class="text-ink/50"><tr><th class="px-4 py-3">Item</th><th>Type</th><th>When</th><th>Place</th><th>Status</th></tr></thead>
                <tbody>
                    <tr v-for="row in handovers.data" :key="row.id" class="border-t border-mist">
                        <td class="px-4 py-3">{{ row.title }}</td>
                        <td>{{ row.type }}</td>
                        <td>{{ row.scheduled_at }}</td>
                        <td>{{ row.place }}</td>
                        <td>{{ row.status }}</td>
                    </tr>
                </tbody>
            </table>
        </div>
        <Pager :pager="handovers" />
    </div>
</template>
