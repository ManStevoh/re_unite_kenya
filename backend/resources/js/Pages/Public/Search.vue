<script setup lang="ts">
import PublicLayout from '../../Layouts/PublicLayout.vue';
import { Link, router } from '@inertiajs/vue3';
import { ref } from 'vue';
defineOptions({ layout: PublicLayout });
const props = defineProps<{ results: any; filters: any; categories: { id: number; name: string }[] }>();
const q = ref(props.filters.q || '');
const type = ref(props.filters.type || '');
const category_id = ref(props.filters.category_id || '');
</script>

<template>
    <div class="mx-auto max-w-5xl px-6 py-10">
        <h1 class="text-2xl font-semibold">Public teaser search</h1>
        <form class="mt-4 flex flex-wrap gap-2" @submit.prevent="router.get('/search', { q, type, category_id })">
            <input v-model="q" class="input max-w-sm" placeholder="Wallet, keys, phone…">
            <select v-model="type" class="input max-w-40">
                <option value="">Any type</option>
                <option value="lost">Lost</option>
                <option value="found">Found</option>
            </select>
            <select v-model="category_id" class="input max-w-52">
                <option value="">Any category</option>
                <option v-for="c in categories" :key="c.id" :value="c.id">{{ c.name }}</option>
            </select>
            <button class="btn btn-primary">Search</button>
        </form>
        <div class="mt-6 grid gap-4">
            <Link v-for="item in results.data" :key="item.id" :href="`/items/${item.id}`" class="flex gap-4 overflow-hidden rounded-xl bg-paper">
                <img v-if="item.thumbnail" :src="item.thumbnail" :alt="item.title" class="h-24 w-28 shrink-0 object-cover">
                <div class="p-5">
                    <p class="text-xs uppercase text-coral">{{ item.type }}</p>
                    <p class="font-semibold">{{ item.title }}</p>
                    <p class="text-sm text-ink/60">{{ item.category }} · {{ item.area }}</p>
                </div>
            </Link>
        </div>
    </div>
</template>
