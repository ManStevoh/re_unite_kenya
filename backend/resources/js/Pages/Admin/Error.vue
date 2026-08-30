<script setup lang="ts">
defineProps<{ status: number }>();
const copy: Record<number, string> = {
    403: 'You do not have access to this page.',
    404: 'That page could not be found.',
    500: 'Something went wrong. Staff have been notified.',
    503: 'Reunite is briefly unavailable.',
};
</script>

<template>
    <div class="flex min-h-screen items-center justify-center bg-sand px-6">
        <div class="max-w-md rounded-2xl bg-paper p-8 text-center">
            <p class="text-sm text-coral">{{ status }}</p>
            <h1 class="mt-2 text-2xl font-semibold text-ink">{{ copy[status] || 'Unexpected error' }}</h1>
            <a href="/admin" class="btn btn-primary mt-6">Back to dashboard</a>
        </div>
    </div>
</template>
