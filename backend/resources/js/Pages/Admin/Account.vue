<script setup lang="ts">
import AdminLayout from '../../Layouts/AdminLayout.vue';
import { useForm, Link } from '@inertiajs/vue3';
defineOptions({ layout: AdminLayout });
const props = defineProps<{ user: any }>();
const form = useForm({ display_name: props.user.display_name, locale: props.user.locale || 'en', current_password: '', password: '', password_confirmation: '' });
</script>

<template>
    <div class="max-w-lg">
        <h1 class="text-2xl font-semibold">Admin account</h1>
        <form class="mt-6 space-y-3 rounded-xl bg-paper p-6" @submit.prevent="form.post('/admin/account')">
            <input v-model="form.display_name" class="input" required>
            <input v-model="form.locale" class="input">
            <input v-model="form.current_password" class="input" type="password" placeholder="Current password">
            <input v-model="form.password" class="input" type="password" placeholder="New password">
            <input v-model="form.password_confirmation" class="input" type="password" placeholder="Confirm">
            <button class="btn btn-primary">Update</button>
        </form>
        <p class="mt-4 text-sm text-ink/60">2FA setup can be enabled later. <Link href="/admin/2fa" class="text-coral">Learn more</Link></p>
    </div>
</template>
