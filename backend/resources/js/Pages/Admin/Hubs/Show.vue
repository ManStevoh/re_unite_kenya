<script setup lang="ts">
import AdminLayout from '../../../Layouts/AdminLayout.vue';
import { Link, useForm } from '@inertiajs/vue3';
defineOptions({ layout: AdminLayout });
const props = defineProps<{ hub: any }>();
const form = useForm({ code: '', name: '' });
</script>

<template>
    <div>
        <div class="flex items-center justify-between">
            <div>
                <h1 class="text-2xl font-semibold">{{ hub.name }}</h1>
                <p class="text-sm text-ink/60">{{ hub.type }} · {{ hub.address }} · org {{ hub.organization_id || '—' }}</p>
            </div>
            <Link :href="`/admin/hubs/${hub.id}/edit`" class="btn btn-ghost">Edit</Link>
        </div>
        <div class="mt-6 grid gap-6 lg:grid-cols-2">
            <section class="rounded-xl bg-paper p-5">
                <h2 class="font-semibold">Staff</h2>
                <ul class="mt-3 text-sm">
                    <li v-for="s in hub.staff" :key="s.id">{{ s.name }} · {{ s.role }}</li>
                </ul>
            </section>
            <section class="rounded-xl bg-paper p-5">
                <h2 class="font-semibold">Storage</h2>
                <ul class="mt-3 text-sm">
                    <li v-for="s in hub.storage" :key="s.id">{{ s.code }} — {{ s.name }}</li>
                </ul>
                <form class="mt-4 flex gap-2" @submit.prevent="form.post(`/admin/hubs/${hub.id}/storage`)">
                    <input v-model="form.code" class="input" placeholder="Code">
                    <input v-model="form.name" class="input" placeholder="Name">
                    <button class="btn btn-primary">Add</button>
                </form>
            </section>
        </div>
        <section class="mt-6 rounded-xl bg-paper p-5">
            <h2 class="font-semibold">Inventory</h2>
            <p v-for="item in hub.inventory" :key="item.id" class="mt-2 text-sm">{{ item.title }} · {{ item.area }}</p>
        </section>
    </div>
</template>
