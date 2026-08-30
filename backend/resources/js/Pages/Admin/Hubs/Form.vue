<script setup lang="ts">
import AdminLayout from '../../../Layouts/AdminLayout.vue';
import { useForm } from '@inertiajs/vue3';
defineOptions({ layout: AdminLayout });
const props = defineProps<{ hub: any; organizations: { id: number; name: string }[] }>();
const form = useForm({
    name: props.hub?.name || '',
    type: props.hub?.type || 'mall',
    address: props.hub?.address || '',
    lat: props.hub?.lat || '',
    lng: props.hub?.lng || '',
    is_public: props.hub?.is_public ?? true,
    retention_days: props.hub?.retention_days || 60,
    capacity: props.hub?.capacity || 200,
    organization_id: props.hub?.organization_id || '',
    contact_internal: props.hub?.contact_internal || '',
});
function submit() {
    props.hub ? form.post(`/admin/hubs/${props.hub.id}`) : form.post('/admin/hubs');
}
</script>

<template>
    <div class="max-w-lg">
        <h1 class="text-2xl font-semibold">{{ hub ? 'Edit hub' : 'New hub' }}</h1>
        <form class="mt-6 space-y-3 rounded-xl bg-paper p-6" @submit.prevent="submit">
            <input v-model="form.name" class="input" placeholder="Name" required>
            <select v-model="form.type" class="input">
                <option>campus</option><option>mall</option><option>airport</option><option>station</option><option>office</option><option>municipal</option>
            </select>
            <input v-model="form.address" class="input" placeholder="Address">
            <div class="grid grid-cols-2 gap-2">
                <input v-model="form.lat" class="input" placeholder="Lat">
                <input v-model="form.lng" class="input" placeholder="Lng">
            </div>
            <select v-model="form.organization_id" class="input">
                <option value="">No organization</option>
                <option v-for="o in organizations" :key="o.id" :value="o.id">{{ o.name }}</option>
            </select>
            <input v-model="form.capacity" class="input" type="number" placeholder="Capacity">
            <label class="flex items-center gap-2 text-sm"><input v-model="form.is_public" type="checkbox"> Public</label>
            <button class="btn btn-primary">Save</button>
        </form>
    </div>
</template>
