<script setup lang="ts">
import { Link } from '@inertiajs/vue3';
import type { Paginator } from '../types';

defineProps<{ pager: Paginator<unknown> }>();
</script>

<template>
    <div v-if="pager.last_page > 1" class="mt-4 flex flex-wrap gap-2">
        <Link
            v-for="link in pager.links"
            :key="link.label"
            :href="link.url || '#'"
            class="rounded-md px-3 py-1 text-sm"
            :class="link.active ? 'bg-ink text-white' : 'bg-white text-ink'"
            v-html="link.label"
        />
    </div>
</template>
