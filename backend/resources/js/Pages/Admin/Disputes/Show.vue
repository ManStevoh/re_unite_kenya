<script setup lang="ts">
import AdminLayout from '../../../Layouts/AdminLayout.vue';
import { useForm } from '@inertiajs/vue3';
defineOptions({ layout: AdminLayout });
const props = defineProps<{ dispute: any; claims: any[] }>();
const form = useForm({ status: 'resolved', resolution: '' });
</script>

<template>
    <div>
        <h1 class="text-2xl font-semibold">Dispute #{{ dispute.id }}</h1>
        <p class="text-sm text-ink/60">{{ dispute.type }} · {{ dispute.status }}</p>
        <section class="mt-6 rounded-xl bg-paper p-5">
            <h2 class="font-semibold">Linked claims</h2>
            <div v-for="c in claims" :key="c.id" class="mt-3 border-t border-mist pt-3 text-sm">
                <p>#{{ c.id }} {{ c.status }} — {{ c.claimant?.display_name }}</p>
            </div>
        </section>
        <form class="mt-6 max-w-lg space-y-3" @submit.prevent="form.post(`/admin/disputes/${dispute.id}`)">
            <textarea v-model="form.resolution" class="input" rows="4" placeholder="Resolution notes" required />
            <button class="btn btn-primary">Resolve</button>
        </form>
    </div>
</template>
