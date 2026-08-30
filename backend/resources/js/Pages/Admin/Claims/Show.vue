<script setup lang="ts">
import AdminLayout from '../../../Layouts/AdminLayout.vue';
import { useForm } from '@inertiajs/vue3';

defineOptions({ layout: AdminLayout });
const props = defineProps<{ claim: any }>();
const form = useForm({ action: 'approve', reason: '' });
</script>

<template>
    <div>
        <h1 class="text-2xl font-semibold">Claim #{{ claim.id }}</h1>
        <p class="text-sm text-ink/60">{{ claim.status }} · attempts {{ claim.attempts }}</p>
        <div class="mt-6 grid gap-6 lg:grid-cols-2">
            <section class="rounded-xl bg-paper p-5">
                <h2 class="font-semibold">Hidden truth</h2>
                <p class="mt-2 text-sm"><strong>Serial:</strong> {{ claim.hidden_truth?.serial }}</p>
                <p class="text-sm"><strong>Notes:</strong> {{ claim.hidden_truth?.hidden_notes }}</p>
                <pre class="mt-2 overflow-auto text-xs">{{ JSON.stringify(claim.hidden_truth?.attributes, null, 2) }}</pre>
            </section>
            <section class="rounded-xl bg-paper p-5">
                <h2 class="font-semibold">Claimant answers</h2>
                <div v-for="a in claim.answers" :key="a.id" class="mt-3 border-t border-mist pt-3 text-sm">
                    <p class="text-ink/50">{{ a.question }}</p>
                    <p class="font-medium">{{ a.answer }}</p>
                </div>
            </section>
        </div>
        <form class="mt-6 max-w-lg space-y-3 rounded-xl bg-paper p-5" @submit.prevent="form.post(`/admin/claims/${claim.id}/decide`)">
            <select v-model="form.action" class="input">
                <option value="approve">Approve</option>
                <option value="reject">Reject</option>
                <option value="needs_info">Request info</option>
            </select>
            <textarea v-model="form.reason" class="input" rows="3" required />
            <button class="btn btn-accent">Decide</button>
        </form>
    </div>
</template>
