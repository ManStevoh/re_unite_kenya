<script setup lang="ts">
import AdminLayout from '../../../Layouts/AdminLayout.vue';
import { useForm } from '@inertiajs/vue3';
import { ref } from 'vue';

defineOptions({ layout: AdminLayout });
const props = defineProps<{ categories: any[] }>();

const form = useForm({
    name: '',
    sensitivity: 'public',
    retention_days: 90,
    photo_guidance: '',
    icon: 'category',
});

const editing = ref<number | null>(null);
const editForm = useForm({
    name: '',
    sensitivity: 'public',
    retention_days: 90,
    photo_guidance: '',
    icon: 'category',
});

const attrForm = useForm({
    key: '',
    label: '',
    type: 'text',
    visibility: 'public',
    required: false,
});

function startEdit(cat: any) {
    editing.value = cat.id;
    editForm.name = cat.name;
    editForm.sensitivity = cat.sensitivity;
    editForm.retention_days = cat.retention_days;
    editForm.photo_guidance = cat.photo_guidance || '';
    editForm.icon = cat.schema_json?.icon || cat.icon || 'category';
}

function saveEdit(id: number) {
    editForm.post(`/admin/categories/${id}`, {
        onSuccess: () => {
            editing.value = null;
        },
    });
}

function addAttr(id: number) {
    attrForm.post(`/admin/categories/${id}/attributes`, {
        onSuccess: () => attrForm.reset(),
    });
}
</script>

<template>
    <div>
        <h1 class="text-2xl font-semibold">Categories</h1>
        <p class="mt-1 text-sm text-ink/60">These appear in the mobile app catalog as soon as you add them.</p>

        <form class="mt-4 grid gap-2 md:grid-cols-2 lg:grid-cols-3" @submit.prevent="form.post('/admin/categories')">
            <input v-model="form.name" class="input" placeholder="Name" required>
            <input v-model="form.icon" class="input" placeholder="Icon (wallet, smartphone, key…)">
            <select v-model="form.sensitivity" class="input">
                <option value="public">public</option>
                <option value="restricted">restricted</option>
                <option value="highly_sensitive">highly_sensitive</option>
            </select>
            <input v-model.number="form.retention_days" type="number" min="1" class="input" placeholder="Retention days">
            <input v-model="form.photo_guidance" class="input md:col-span-2" placeholder="Photo guidance">
            <button class="btn btn-primary">Add category</button>
        </form>

        <div class="mt-6 space-y-3">
            <article v-for="cat in categories" :key="cat.id" class="rounded-xl bg-paper p-4">
                <div v-if="editing !== cat.id">
                    <p class="font-semibold">
                        {{ cat.name }}
                        <span class="text-xs text-ink/50">{{ cat.sensitivity }} · {{ cat.slug }} · icon {{ cat.schema_json?.icon || 'category' }}</span>
                    </p>
                    <p class="text-sm text-ink/60">{{ cat.photo_guidance }}</p>
                    <p class="mt-2 text-xs">Attrs: {{ (cat.category_attributes || [])?.map((a: any) => a.label).join(', ') || 'none' }}</p>
                    <button class="mt-3 text-sm underline" type="button" @click="startEdit(cat)">Edit</button>
                </div>
                <form v-else class="grid gap-2 md:grid-cols-2" @submit.prevent="saveEdit(cat.id)">
                    <input v-model="editForm.name" class="input" required>
                    <input v-model="editForm.icon" class="input" placeholder="Icon">
                    <select v-model="editForm.sensitivity" class="input">
                        <option value="public">public</option>
                        <option value="restricted">restricted</option>
                        <option value="highly_sensitive">highly_sensitive</option>
                    </select>
                    <input v-model.number="editForm.retention_days" type="number" class="input">
                    <input v-model="editForm.photo_guidance" class="input md:col-span-2">
                    <div class="flex gap-2">
                        <button class="btn btn-primary" type="submit">Save</button>
                        <button class="btn" type="button" @click="editing = null">Cancel</button>
                    </div>
                </form>
                <form class="mt-3 flex flex-wrap gap-2" @submit.prevent="addAttr(cat.id)">
                    <input v-model="attrForm.key" class="input max-w-32" placeholder="key">
                    <input v-model="attrForm.label" class="input max-w-40" placeholder="Label">
                    <select v-model="attrForm.type" class="input max-w-28">
                        <option>text</option><option>color</option><option>enum</option><option>number</option>
                    </select>
                    <select v-model="attrForm.visibility" class="input max-w-40">
                        <option>public</option><option>hidden_challenge</option><option>admin_only</option>
                    </select>
                    <button class="btn" type="submit">Add attribute</button>
                </form>
            </article>
        </div>
    </div>
</template>
