<script setup lang="ts">
import AdminLayout from '../../Layouts/AdminLayout.vue';
defineOptions({ layout: AdminLayout });
defineProps<{ counts: Record<string, number> }>();
</script>

<template>
    <div>
        <h1 class="text-2xl font-semibold">Analytics</h1>
        <div class="mt-6 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            <div v-for="(value, key) in counts" :key="key" class="rounded-xl bg-paper p-5">
                <p class="text-xs uppercase text-ink/50">{{ key.replace('_', ' ') }}</p>
                <p class="mt-2 text-3xl font-semibold">{{ value }}</p>
                <div class="mt-3 h-2 rounded bg-mist">
                    <div class="h-2 rounded bg-ink" :style="{ width: Math.min(100, Number(value) * 8) + '%' }" />
                </div>
            </div>
        </div>
    </div>
</template>
