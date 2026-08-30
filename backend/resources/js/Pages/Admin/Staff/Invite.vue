<script setup lang="ts">
import AdminLayout from '../../../Layouts/AdminLayout.vue';
import { useForm } from '@inertiajs/vue3';
defineOptions({ layout: AdminLayout });
defineProps<{ roles: string[]; hubs: { id: number; name: string }[] }>();
const form = useForm({ name: '', email: '', role: 'moderator', hub_id: '', password: 'password' });
</script>

<template>
    <div class="max-w-lg">
        <h1 class="text-2xl font-semibold">Staff invite</h1>
        <form class="mt-6 space-y-4 rounded-xl bg-paper p-6" @submit.prevent="form.post('/admin/staff/invite')">
            <input v-model="form.name" class="input" placeholder="Name" required>
            <input v-model="form.email" class="input" type="email" placeholder="Email" required>
            <select v-model="form.role" class="input">
                <option v-for="r in roles" :key="r" :value="r">{{ r }}</option>
            </select>
            <select v-model="form.hub_id" class="input">
                <option value="">No hub</option>
                <option v-for="h in hubs" :key="h.id" :value="h.id">{{ h.name }}</option>
            </select>
            <input v-model="form.password" class="input" placeholder="Temporary password" required>
            <p v-if="form.errors.email" class="text-sm text-coral">{{ form.errors.email }}</p>
            <button class="btn btn-accent">Create staff user</button>
        </form>
    </div>
</template>
