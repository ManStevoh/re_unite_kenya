<script setup lang="ts">
import AdminLayout from '../../../Layouts/AdminLayout.vue';
defineOptions({ layout: AdminLayout });
defineProps<{ conversation: any; messages: any[] }>();
</script>

<template>
    <div>
        <div class="rounded-lg bg-coral/15 px-4 py-3 text-sm text-coral-dark">Access is audited. Do not share chat contents outside the case.</div>
        <h1 class="mt-6 text-2xl font-semibold">Conversation #{{ conversation.id }}</h1>
        <div class="mt-6 space-y-3">
            <article v-for="m in messages" :key="m.id" class="rounded-xl bg-paper p-4 text-sm">
                <p class="text-xs text-ink/50">{{ m.user?.display_name || m.user?.name }} · {{ m.created_at }}</p>
                <p class="mt-1">{{ m.body }}</p>
            </article>
        </div>
    </div>
</template>
