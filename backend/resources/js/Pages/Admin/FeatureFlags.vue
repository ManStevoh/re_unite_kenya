<script setup lang="ts">
import AdminLayout from '../../Layouts/AdminLayout.vue';
import { useForm } from '@inertiajs/vue3';
defineOptions({ layout: AdminLayout });
const props = defineProps<{ flags: Record<string, boolean> }>();
const form = useForm({
    flags: {
        qr_tags: props.flags.qr_tags ?? true,
        tips: props.flags.tips ?? true,
        public_web: props.flags.public_web ?? true,
        id_verification: props.flags.id_verification ?? false,
        sso: props.flags.sso ?? false,
        meilisearch: props.flags.meilisearch ?? false,
    },
});
</script>

<template>
    <div class="max-w-lg rounded-xl bg-paper p-6">
        <h1 class="text-2xl font-semibold">Feature flags</h1>
        <form class="mt-6 space-y-3" @submit.prevent="form.post('/admin/feature-flags')">
            <label v-for="(_, key) in form.flags" :key="key" class="flex items-center justify-between text-sm capitalize">
                {{ String(key).replace('_', ' ') }}
                <input v-model="form.flags[key]" type="checkbox">
            </label>
            <button class="btn btn-primary">Save flags</button>
        </form>
    </div>
</template>
