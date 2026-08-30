<script setup lang="ts">
import AdminLayout from '../../../Layouts/AdminLayout.vue';
import { useForm } from '@inertiajs/vue3';
defineOptions({ layout: AdminLayout });
const props = defineProps<{ user: any }>();
const form = useForm({
    status: props.user.status,
    verification_level: props.user.verification_level,
    roles: props.user.roles || [],
    verify_phone: false,
});
</script>

<template>
    <div class="grid gap-6 lg:grid-cols-3">
        <div class="lg:col-span-2 space-y-4">
            <h1 class="text-2xl font-semibold">{{ user.display_name }}</h1>
            <p class="text-sm text-ink/60">{{ user.email }} · {{ user.city }} · L{{ user.verification_level }} · {{ user.id_verification_status }}</p>
            <section class="rounded-xl bg-paper p-5 text-sm">
                <p>Reports: {{ user.reports?.length }} · Claims: {{ user.claims?.length }}</p>
                <p class="mt-2">Reputation {{ user.reputation_points }} · Trust {{ user.trust_score }}</p>
            </section>
        </div>
        <form class="space-y-3 rounded-xl bg-paper p-5" @submit.prevent="form.post(`/admin/users/${user.id}`)">
            <label class="block text-sm">Status
                <select v-model="form.status" class="input mt-1">
                    <option value="active">active</option>
                    <option value="restricted">restricted</option>
                    <option value="suspended">suspended</option>
                    <option value="banned">banned</option>
                    <option value="deactivated">deactivated</option>
                </select>
            </label>
            <label class="block text-sm">Roles
                <select v-model="form.roles" class="input mt-1" multiple>
                    <option v-for="r in user.available_roles" :key="r" :value="r">{{ r }}</option>
                </select>
            </label>
            <label class="flex items-center gap-2 text-sm"><input v-model="form.verify_phone" type="checkbox"> Verify phone manually</label>
            <button class="btn btn-accent w-full">Save</button>
        </form>
    </div>
</template>
