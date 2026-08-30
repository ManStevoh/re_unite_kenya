<script setup lang="ts">
import AdminLayout from '../../Layouts/AdminLayout.vue';
import { useForm } from '@inertiajs/vue3';
defineOptions({ layout: AdminLayout });
const props = defineProps<{ settings: Record<string, any> }>();
const form = useForm({
    settings: {
        registration_open: props.settings.registration_open ?? true,
        guest_browse: props.settings.guest_browse ?? true,
        match_score_threshold: props.settings.match_score_threshold ?? 60,
        claim_attempt_limit: props.settings.claim_attempt_limit ?? 3,
        sso: props.settings.sso ?? { enabled: false, provider: 'saml', note: 'Phase 3 stub' },
    },
});
</script>

<template>
    <div class="max-w-lg">
        <h1 class="text-2xl font-semibold">Settings</h1>
        <form class="mt-6 space-y-4 rounded-xl bg-paper p-6" @submit.prevent="form.post('/admin/settings')">
            <label class="flex items-center gap-2 text-sm"><input v-model="form.settings.registration_open" type="checkbox"> Registration open</label>
            <label class="flex items-center gap-2 text-sm"><input v-model="form.settings.guest_browse" type="checkbox"> Guest browse</label>
            <label class="block text-sm">Match threshold
                <input v-model.number="form.settings.match_score_threshold" class="input mt-1" type="number">
            </label>
            <label class="block text-sm">Claim attempt limit
                <input v-model.number="form.settings.claim_attempt_limit" class="input mt-1" type="number">
            </label>
            <p class="text-xs text-ink/50">SSO settings are stored but not enforced yet (Phase 3 stub).</p>
            <button class="btn btn-primary">Save</button>
        </form>
    </div>
</template>
