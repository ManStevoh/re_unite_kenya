<script setup lang="ts">
import AdminLayout from '../../../Layouts/AdminLayout.vue';
import { reactive } from 'vue';
import { router, useForm } from '@inertiajs/vue3';
defineOptions({ layout: AdminLayout });
defineProps<{ pages: any[] }>();
const create = useForm({ slug: '', title: '', body: '', published: true });
const drafts = reactive<Record<number, any>>({});
function save(page: any) {
    const d = drafts[page.id] || page;
    router.post(`/admin/cms/${page.id}`, { title: d.title, body: d.body, published: d.published });
}
</script>

<template>
    <div>
        <h1 class="text-2xl font-semibold">CMS pages</h1>
        <form class="mt-4 grid gap-2 md:grid-cols-2" @submit.prevent="create.post('/admin/cms')">
            <input v-model="create.slug" class="input" placeholder="slug" required>
            <input v-model="create.title" class="input" placeholder="Title" required>
            <textarea v-model="create.body" class="input md:col-span-2" rows="3" />
            <button class="btn btn-primary">Create</button>
        </form>
        <article v-for="page in pages" :key="page.id" class="mt-4 rounded-xl bg-paper p-5">
            <input :value="(drafts[page.id] || page).title" class="input" @input="drafts[page.id] = { ...page, ...(drafts[page.id] || {}), title: ($event.target as HTMLInputElement).value }">
            <textarea :value="(drafts[page.id] || page).body" class="input mt-2" rows="6" @input="drafts[page.id] = { ...page, ...(drafts[page.id] || {}), body: ($event.target as HTMLTextAreaElement).value }" />
            <label class="mt-2 flex items-center gap-2 text-sm">
                <input type="checkbox" :checked="(drafts[page.id] || page).published" @change="drafts[page.id] = { ...page, ...(drafts[page.id] || {}), published: ($event.target as HTMLInputElement).checked }">
                Published
            </label>
            <button class="btn btn-ghost mt-3" @click="save(page)">Save {{ page.slug }}</button>
        </article>
    </div>
</template>
