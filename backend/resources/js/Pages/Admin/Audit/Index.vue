<script setup lang="ts">
import AdminLayout from '../../../Layouts/AdminLayout.vue';
import Pager from '../../../Components/Pager.vue';
defineOptions({ layout: AdminLayout });
defineProps<{ logs: any }>();
</script>

<template>
    <div>
        <h1 class="text-2xl font-semibold">Audit log</h1>
        <div class="mt-6 overflow-x-auto rounded-xl bg-paper">
            <table class="w-full text-left text-sm">
                <thead class="text-ink/50"><tr><th class="px-4 py-3">When</th><th>Actor</th><th>Action</th><th>Subject</th></tr></thead>
                <tbody>
                    <tr v-for="row in logs.data" :key="row.id" class="border-t border-mist">
                        <td class="px-4 py-3">{{ row.created_at }}</td>
                        <td>{{ row.actor }}</td>
                        <td>{{ row.action }}</td>
                        <td>{{ row.subject_type }} {{ row.subject_id }}</td>
                    </tr>
                </tbody>
            </table>
        </div>
        <Pager :pager="logs" />
    </div>
</template>
