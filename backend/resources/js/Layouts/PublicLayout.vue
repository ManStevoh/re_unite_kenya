<script setup lang="ts">
import { Link } from '@inertiajs/vue3';
import JoinMark from '../Components/JoinMark.vue';
</script>

<template>
    <div class="min-h-screen bg-sand text-ink">
        <header class="border-b border-mist bg-paper">
            <div class="relative mx-auto flex max-w-6xl flex-col items-center gap-3 px-6 py-4 md:h-16 md:flex-row md:justify-end">
                <Link href="/" class="flex items-center gap-2.5 md:absolute md:left-1/2 md:-translate-x-1/2">
                    <JoinMark :size="30" />
                    <span class="text-xl font-semibold tracking-tight">Reunite</span>
                </Link>
                <nav class="flex gap-5 text-sm">
                    <Link href="/search" class="hover:text-coral">Search</Link>
                    <Link href="/p/faq" class="hover:text-coral">Help</Link>
                    <Link href="/admin/login" class="hover:text-coral">Staff</Link>
                </nav>
            </div>
        </header>
        <main>
            <slot />
        </main>
        <footer class="border-t border-mist bg-paper">
            <div class="mx-auto flex max-w-6xl flex-col items-center gap-4 px-6 py-8 text-sm text-ink/60 md:flex-row md:justify-between">
                <p>© {{ new Date().getFullYear() }} Reunite</p>
                <div class="text-center">
                    <Link href="/p/terms" class="mx-2 hover:text-ink">Terms</Link>
                    <Link href="/p/privacy" class="mx-2 hover:text-ink">Privacy</Link>
                    <Link href="/p/guidelines" class="mx-2 hover:text-ink">Guidelines</Link>
                    <Link href="/p/safety" class="mx-2 hover:text-ink">Safety</Link>
                </div>
            </div>
        </footer>
    </div>
</template>
