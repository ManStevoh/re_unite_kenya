<script setup lang="ts">
import { Link } from '@inertiajs/vue3';
</script>

<template>
    <div class="flex min-h-screen items-center justify-center bg-ink px-4">
        <div class="w-full max-w-md rounded-2xl bg-paper p-8">
            <h1 class="text-2xl font-semibold text-ink">Two-factor authentication</h1>
            <p class="mt-3 text-sm text-ink/70">
                TOTP enforcement will be enabled later. Continue with your staff password for local environments.
            </p>
            <Link href="/admin/login" class="btn btn-primary mt-6">Back to login</Link>
        </div>
    </div>
</template>
