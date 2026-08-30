<script setup lang="ts">
import AdminLayout from '../../../Layouts/AdminLayout.vue';
import { Link } from '@inertiajs/vue3';
defineOptions({ layout: AdminLayout });
defineProps<{ hubs: any[] }>();
</script>

<template>
    <div>
        <div class="flex items-center justify-between">
            <h1 class="text-2xl font-semibold">Hubs</h1>
            <Link href="/admin/hubs/create" class="btn btn-primary">New hub</Link>
        </div>
        <div class="mt-6 grid gap-4 md:grid-cols-2">
            <Link v-for="hub in hubs" :key="hub.id" :href="`/admin/hubs/${hub.id}`" class="rounded-xl bg-paper p-5">
                <p class="font-semibold">{{ hub.name }}</p>
                <p class="text-sm text-ink/60">{{ hub.type }} · {{ hub.address }}</p>
                <p class="mt-2 text-sm">{{ hub.occupancy }}/{{ hub.capacity }} stored</p>
            </Link>
        </div>
    </div>
</template>
