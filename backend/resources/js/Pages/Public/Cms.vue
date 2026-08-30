<script setup lang="ts">
import PublicLayout from '../../Layouts/PublicLayout.vue';
defineOptions({ layout: PublicLayout });
defineProps<{ page: { title: string; body: string } }>();
</script>

<template>
    <article class="prose mx-auto max-w-3xl px-6 py-10">
        <h1 class="text-3xl font-semibold">{{ page.title }}</h1>
        <div class="mt-6 whitespace-pre-wrap text-ink/80">{{ page.body }}</div>
    </article>
</template>
