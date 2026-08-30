<script setup lang="ts">
import AdminLayout from '../../../Layouts/AdminLayout.vue';
import { useForm } from '@inertiajs/vue3';

defineOptions({ layout: AdminLayout });
const props = defineProps<{ report: any }>();
const form = useForm({ action: 'approve', reason: '' });
function decide() {
    form.post(`/admin/reports/${props.report.id}/decide`);
}
</script>

<template>
    <div class="grid gap-6 lg:grid-cols-3">
        <div class="lg:col-span-2 space-y-4">
            <h1 class="text-2xl font-semibold">{{ report.title }}</h1>
            <p class="text-sm text-ink/60">{{ report.type }} · {{ report.status }} · {{ report.category }}</p>
            <section class="rounded-xl bg-paper p-5">
                <h2 class="font-semibold">Public description</h2>
                <p class="mt-2 text-sm">{{ report.description || '—' }}</p>
                <p class="mt-3 text-sm"><strong>Area:</strong> {{ report.area }} · {{ report.place_name }}</p>
                <p class="text-sm"><strong>When:</strong> {{ report.occurred_on }}</p>
            </section>
            <section class="rounded-xl bg-paper p-5">
                <h2 class="font-semibold">Hidden fields</h2>
                <p class="mt-2 text-sm"><strong>Serial:</strong> {{ report.serial || '—' }}</p>
                <p class="text-sm"><strong>Notes:</strong> {{ report.hidden_notes || '—' }}</p>
                <p class="text-sm"><strong>Exact pin:</strong> {{ report.lat }}, {{ report.lng }}</p>
                <p class="text-sm"><strong>Storage:</strong> {{ report.storage_code || '—' }}</p>
            </section>
            <section class="rounded-xl bg-paper p-5">
                <h2 class="font-semibold">Matches</h2>
                <ul class="mt-2 text-sm">
                    <li v-for="m in report.matches" :key="m.id">#{{ m.id }} score {{ m.score }} · {{ m.status }}</li>
                </ul>
            </section>
        </div>
        <aside class="space-y-4">
            <section class="rounded-xl bg-paper p-5">
                <h2 class="font-semibold">Reporter</h2>
                <p class="mt-2 text-sm">{{ report.user?.display_name }}</p>
                <p class="text-sm text-ink/60">Trust {{ report.user?.trust_score }}</p>
            </section>
            <section class="rounded-xl bg-paper p-5">
                <h2 class="font-semibold">Decision</h2>
                <form class="mt-3 space-y-3" @submit.prevent="decide">
                    <select v-model="form.action" class="input">
                        <option value="approve">Approve</option>
                        <option value="reject">Reject</option>
                        <option value="request_changes">Request changes</option>
                    </select>
                    <textarea v-model="form.reason" class="input" rows="3" placeholder="Required reason" required />
                    <button class="btn btn-accent w-full">Apply</button>
                </form>
            </section>
        </aside>
    </div>
</template>
