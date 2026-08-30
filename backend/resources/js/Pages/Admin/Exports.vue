<script setup lang="ts">
import AdminLayout from '../../Layouts/AdminLayout.vue';
defineOptions({ layout: AdminLayout });
</script>

<template>
    <div class="max-w-lg rounded-xl bg-paper p-6">
        <h1 class="text-2xl font-semibold">Exports</h1>
        <p class="mt-2 text-sm text-ink/70">Download a CSV of item reports. The download is audited.</p>
        <a href="/admin/exports/reports.csv" class="btn btn-primary mt-4">Download reports CSV</a>
    </div>
</template>
