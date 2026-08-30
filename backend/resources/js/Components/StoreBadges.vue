<script setup lang="ts">
withDefaults(
    defineProps<{
        appStoreUrl?: string;
        playStoreUrl?: string;
    }>(),
    {
        appStoreUrl: '#download',
        playStoreUrl: '#download',
    },
);
</script>

<template>
    <div class="flex flex-wrap items-center gap-3">
        <a
            :href="appStoreUrl"
            class="inline-flex h-12 items-center gap-3 rounded-xl bg-ink px-4 text-white shadow-sm transition hover:bg-ink-dark"
            aria-label="Download on the App Store"
        >
            <svg viewBox="0 0 24 24" class="h-7 w-7 fill-current" aria-hidden="true">
                <path d="M16.37 12.86c0-2.17 1.77-3.21 1.85-3.26-1.01-1.48-2.58-1.68-3.14-1.7-1.33-.14-2.61.79-3.29.79-.68 0-1.73-.77-2.85-.75-1.46.02-2.82.86-3.57 2.18-1.53 2.66-.39 6.59 1.1 8.75.73 1.06 1.59 2.24 2.72 2.2 1.1-.05 1.51-.7 2.84-.7 1.32 0 1.69.7 2.85.68 1.18-.02 1.92-1.07 2.64-2.13.83-1.21 1.17-2.39 1.19-2.45-.03-.01-2.28-.87-2.3-3.46zM14.7 6.4c.6-.73 1.01-1.75.9-2.77-.87.04-1.92.58-2.54 1.31-.56.64-1.05 1.68-.92 2.67 1.03.08 2.0-.52 2.56-1.21z" />
            </svg>
            <span class="leading-tight">
                <span class="block text-[10px] font-medium uppercase tracking-wide text-white/70">Download on the</span>
                <span class="block text-[17px] font-semibold -mt-0.5">App Store</span>
            </span>
        </a>
        <a
            :href="playStoreUrl"
            class="inline-flex h-12 items-center gap-3 rounded-xl bg-ink px-4 text-white shadow-sm transition hover:bg-ink-dark"
            aria-label="Get it on Google Play"
        >
            <svg viewBox="0 0 24 24" class="h-7 w-7" aria-hidden="true">
                <path fill="#34A853" d="M3.6 20.7 13.3 11 3.6 3.3C3.2 3.6 3 4.1 3 4.7v14.6c0 .6.2 1.1.6 1.4z" />
                <path fill="#FBBC04" d="M20.3 10.2 16.6 8.1 13.3 11l3.3 2.9 3.7-2.1c.9-.5.9-1.6 0-2.1z" />
                <path fill="#4285F4" d="M3.6 20.7c.4.3.9.4 1.4.2l11.6-6.6-3.3-2.9z" />
                <path fill="#EA4335" d="M16.6 8.1 5 1.5C4.5 1.3 4 1.4 3.6 1.7L13.3 11z" />
            </svg>
            <span class="leading-tight">
                <span class="block text-[10px] font-medium uppercase tracking-wide text-white/70">Get it on</span>
                <span class="block text-[17px] font-semibold -mt-0.5">Google Play</span>
            </span>
        </a>
    </div>
</template>
