<script setup lang="ts">
import AdminLayout from '../../Layouts/AdminLayout.vue';
import { Link } from '@inertiajs/vue3';

defineOptions({ layout: AdminLayout });

defineProps<{
    stats: Record<string, number>;
    hubs: { id: number; name: string; occupancy: number; capacity: number }[];
    funnel: Record<string, number>;
    queue: { id: number; title: string; type: string; status: string; category?: string; reporter?: string; created_at?: string }[];
}>();

const cards = [
    ['open_lost', 'Open lost'],
    ['open_found', 'Open found'],
    ['awaiting_review', 'Awaiting review'],
    ['claims_awaiting', 'Claims waiting'],
    ['returns_7', 'Returns 7d'],
    ['returns_30', 'Returns 30d'],
    ['flags_open', 'Open flags'],
    ['matches', 'Matches'],
] as const;
</script>

<template>
    <div>
        <h1 class="text-2xl font-semibold">Dashboard</h1>
        <div class="mt-6 grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
            <div v-for="[key, label] in cards" :key="key" class="rounded-xl bg-paper p-4 shadow-sm">
                <p class="text-xs uppercase tracking-wide text-ink/50">{{ label }}</p>
                <p class="mt-2 text-3xl font-semibold">{{ stats[key] }}</p>
            </div>
        </div>
        <div class="mt-8 grid gap-6 lg:grid-cols-2">
            <section class="rounded-xl bg-paper p-5">
                <h2 class="font-semibold">Hub occupancy</h2>
                <div v-for="hub in hubs" :key="hub.id" class="mt-3">
                    <div class="flex justify-between text-sm">
                        <span>{{ hub.name }}</span>
                        <span>{{ hub.occupancy }}/{{ hub.capacity }}</span>
                    </div>
                    <div class="mt-1 h-2 rounded bg-mist">
                        <div class="h-2 rounded bg-coral" :style="{ width: Math.min(100, (hub.occupancy / Math.max(hub.capacity, 1)) * 100) + '%' }" />
                    </div>
                </div>
            </section>
            <section class="rounded-xl bg-paper p-5">
                <h2 class="font-semibold">Funnel</h2>
                <ul class="mt-3 space-y-2 text-sm">
                    <li v-for="(value, key) in funnel" :key="key" class="flex justify-between">
                        <span class="capitalize">{{ key }}</span>
                        <strong>{{ value }}</strong>
                    </li>
                </ul>
            </section>
        </div>
        <section class="mt-8 rounded-xl bg-paper p-5">
            <div class="flex items-center justify-between">
                <h2 class="font-semibold">My next 10</h2>
                <Link href="/admin/review" class="text-sm text-coral">Open queue</Link>
            </div>
            <table class="mt-4 w-full text-left text-sm">
                <thead class="text-ink/50">
                    <tr><th class="py-2">Title</th><th>Type</th><th>Status</th><th>Reporter</th></tr>
                </thead>
                <tbody>
                    <tr v-for="row in queue" :key="row.id" class="border-t border-mist">
                        <td class="py-2"><Link :href="`/admin/reports/${row.id}`" class="font-medium">{{ row.title }}</Link></td>
                        <td>{{ row.type }}</td>
                        <td>{{ row.status }}</td>
                        <td>{{ row.reporter }}</td>
                    </tr>
                </tbody>
            </table>
        </section>
    </div>
</template>
