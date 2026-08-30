<script setup lang="ts">
import PublicLayout from '../../Layouts/PublicLayout.vue';
import type { Teaser } from '../../types';
defineOptions({ layout: PublicLayout });
defineProps<{ item: Teaser }>();
</script>

<template>
    <div class="mx-auto max-w-5xl px-6 py-10">
        <article class="overflow-hidden rounded-3xl bg-paper">
            <img v-if="item.thumbnail" :src="item.thumbnail" :alt="item.title" class="h-64 w-full object-cover">
            <div class="p-8">
                <p class="text-xs uppercase text-coral">{{ item.type }} teaser</p>
                <h1 class="mt-2 text-3xl font-semibold">{{ item.title }}</h1>
                <p class="mt-3 text-ink/70">{{ item.category }} · {{ item.color || 'color hidden' }} · {{ item.area }}</p>
                <p class="mt-1 text-sm text-ink/50">Seen {{ item.occurred_on }} · {{ item.hub_name || 'No hub listed' }}</p>
                <p class="mt-6 rounded-lg bg-sand p-4 text-sm">Exact location, serials, and hidden marks are never shown on this page. Open the Reunite app to claim.</p>
            </div>
        </article>
    </div>
</template>
