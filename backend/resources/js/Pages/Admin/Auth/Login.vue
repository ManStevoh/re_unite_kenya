<script setup lang="ts">
import { useForm } from '@inertiajs/vue3';

const form = useForm({
    email: '',
    password: '',
    remember: false,
});

function submit() {
    form.post('/admin/login');
}
</script>

<template>
    <div class="flex min-h-screen items-center justify-center bg-ink px-4">
        <div class="w-full max-w-md rounded-2xl bg-paper p-8 shadow-xl">
            <p class="text-sm font-medium text-coral">Staff access</p>
            <h1 class="mt-1 text-2xl font-semibold text-ink">Sign in to Reunite</h1>
            <p class="mt-2 text-sm text-ink/60">Operational console for listings, claims, and hubs.</p>
            <form class="mt-6 space-y-4" @submit.prevent="submit">
                <label class="block text-sm">
                    Email
                    <input v-model="form.email" type="email" class="input mt-1" required>
                    <p v-if="form.errors.email" class="mt-1 text-coral">{{ form.errors.email }}</p>
                </label>
                <label class="block text-sm">
                    Password
                    <input v-model="form.password" type="password" class="input mt-1" required>
                </label>
                <label class="flex items-center gap-2 text-sm">
                    <input v-model="form.remember" type="checkbox"> Remember me
                </label>
                <button class="btn btn-primary w-full" :disabled="form.processing">Sign in</button>
            </form>
        </div>
    </div>
</template>
