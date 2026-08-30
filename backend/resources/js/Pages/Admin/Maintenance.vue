<script setup lang="ts">
import AdminLayout from '../../Layouts/AdminLayout.vue';
import { useForm } from '@inertiajs/vue3';
defineOptions({ layout: AdminLayout });
const props = defineProps<{ banner: any; read_only: boolean }>();
const form = useForm({
    banner: { enabled: props.banner?.enabled ?? false, text: props.banner?.text ?? '' },
    read_only: props.read_only ?? false,
});
</script>

<template>
    <div class="max-w-lg rounded-xl bg-paper p-6">
        <h1 class="text-2xl font-semibold">Maintenance</h1>
        <form class="mt-6 space-y-3" @submit.prevent="form.post('/admin/maintenance')">
            <label class="flex items-center gap-2 text-sm"><input v-model="form.banner.enabled" type="checkbox"> Show banner</label>
            <textarea v-model="form.banner.text" class="input" rows="3" placeholder="Banner text" />
            <label class="flex items-center gap-2 text-sm"><input v-model="form.read_only" type="checkbox"> Read-only mode</label>
            <button class="btn btn-accent">Save</button>
        </form>
    </div>
</template>
