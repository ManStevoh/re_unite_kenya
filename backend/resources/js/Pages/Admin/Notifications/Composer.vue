<script setup lang="ts">
import AdminLayout from '../../../Layouts/AdminLayout.vue';
import { useForm } from '@inertiajs/vue3';
defineOptions({ layout: AdminLayout });
defineProps<{ roles: string[]; hubs: { id: number; name: string }[] }>();
const form = useForm({ title: '', body: '', audience: 'all', city: '', hub_id: '', role: '' });
</script>

<template>
    <div class="max-w-lg">
        <h1 class="text-2xl font-semibold">Notification composer</h1>
        <form class="mt-6 space-y-3 rounded-xl bg-paper p-6" @submit.prevent="form.post('/admin/notifications/compose')">
            <input v-model="form.title" class="input" placeholder="Title" required>
            <textarea v-model="form.body" class="input" rows="4" placeholder="Body" required />
            <select v-model="form.audience" class="input">
                <option value="all">All users</option>
                <option value="city">City</option>
                <option value="hub">Hub</option>
                <option value="role">Role</option>
            </select>
            <input v-if="form.audience === 'city'" v-model="form.city" class="input" placeholder="City">
            <select v-if="form.audience === 'hub'" v-model="form.hub_id" class="input">
                <option v-for="h in hubs" :key="h.id" :value="h.id">{{ h.name }}</option>
            </select>
            <select v-if="form.audience === 'role'" v-model="form.role" class="input">
                <option v-for="r in roles" :key="r" :value="r">{{ r }}</option>
            </select>
            <button class="btn btn-accent">Send</button>
        </form>
    </div>
</template>
