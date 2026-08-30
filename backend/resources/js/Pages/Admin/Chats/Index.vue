<script setup lang="ts">
import AdminLayout from '../../../Layouts/AdminLayout.vue';
import { Link } from '@inertiajs/vue3';
defineOptions({ layout: AdminLayout });
defineProps<{ conversations: any }>();
</script>

<template>
    <div>
        <h1 class="text-2xl font-semibold">Chat escalations</h1>
        <p class="mt-1 text-sm text-coral">Access is audited.</p>
        <div class="mt-6 overflow-x-auto rounded-xl bg-paper">
            <table class="w-full text-left text-sm">
                <thead class="text-ink/50"><tr><th class="px-4 py-3">Conversation</th><th>Status</th></tr></thead>
                <tbody>
                    <tr v-for="row in conversations.data" :key="row.id" class="border-t border-mist">
                        <td class="px-4 py-3"><Link :href="`/admin/chats/${row.id}`">{{ row.title || 'Thread #' + row.id }}</Link></td>
                        <td>{{ row.status }}</td>
                    </tr>
                </tbody>
            </table>
        </div>
    </div>
</template>
