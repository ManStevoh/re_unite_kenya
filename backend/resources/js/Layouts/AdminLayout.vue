<script setup lang="ts">
import { computed } from 'vue';
import { Link, router, usePage } from '@inertiajs/vue3';

const page = usePage();
const user = computed(() => (page.props.auth as { user?: { display_name?: string; email?: string } } | undefined)?.user);
const banner = computed(() => page.props.maintenance_banner as { enabled?: boolean; text?: string } | null);
const flash = computed(() => page.props.flash as { success?: string; error?: string });

const nav = [
    { href: '/admin', label: 'Dashboard' },
    { href: '/admin/review', label: 'Listings review' },
    { href: '/admin/reports/lost', label: 'Lost' },
    { href: '/admin/reports/found', label: 'Found' },
    { href: '/admin/matches', label: 'Matches' },
    { href: '/admin/claims', label: 'Claims' },
    { href: '/admin/handovers', label: 'Handovers' },
    { href: '/admin/flags', label: 'Flags' },
    { href: '/admin/disputes', label: 'Disputes' },
    { href: '/admin/chats', label: 'Chat escalations' },
    { href: '/admin/users', label: 'Users' },
    { href: '/admin/roles', label: 'Roles' },
    { href: '/admin/staff/invite', label: 'Staff invites' },
    { href: '/admin/hubs', label: 'Hubs' },
    { href: '/admin/categories', label: 'Categories' },
    { href: '/admin/notifications/compose', label: 'Notify' },
    { href: '/admin/notifications/logs', label: 'Delivery logs' },
    { href: '/admin/cms', label: 'CMS' },
    { href: '/admin/analytics', label: 'Analytics' },
    { href: '/admin/exports', label: 'Exports' },
    { href: '/admin/audit', label: 'Audit' },
    { href: '/admin/settings', label: 'Settings' },
    { href: '/admin/feature-flags', label: 'Flags' },
    { href: '/admin/maintenance', label: 'Maintenance' },
];

function logout() {
    router.post('/admin/logout');
}
</script>

<template>
    <div class="min-h-screen bg-sand text-ink">
        <div class="flex min-h-screen">
            <aside class="hidden w-64 shrink-0 bg-ink text-white lg:flex lg:flex-col">
                <div class="px-5 py-6">
                    <Link href="/admin" class="text-lg font-semibold tracking-tight">Reunite</Link>
                    <p class="mt-1 text-xs text-white/60">Operations console</p>
                </div>
                <nav class="flex-1 space-y-0.5 overflow-y-auto px-3 pb-6">
                    <Link
                        v-for="item in nav"
                        :key="item.href"
                        :href="item.href"
                        class="block rounded-lg px-3 py-2 text-sm text-white/80 hover:bg-white/10 hover:text-white"
                        :class="{ 'bg-white/15 text-white': page.url === item.href || page.url.startsWith(item.href + '/') && item.href !== '/admin' }"
                    >
                        {{ item.label }}
                    </Link>
                </nav>
            </aside>
            <div class="flex min-w-0 flex-1 flex-col">
                <header class="flex items-center justify-between border-b border-mist bg-paper px-6 py-4">
                    <div>
                        <p class="text-xs uppercase tracking-wider text-ink/50">Staff</p>
                        <p class="font-semibold">{{ user?.display_name || user?.email }}</p>
                    </div>
                    <div class="flex items-center gap-3">
                        <Link href="/admin/account" class="text-sm text-ink/70 hover:text-ink">Account</Link>
                        <button class="btn btn-accent" type="button" @click="logout">Sign out</button>
                    </div>
                </header>
                <div v-if="banner?.enabled && banner.text" class="bg-coral px-6 py-2 text-sm text-white">
                    {{ banner.text }}
                </div>
                <div v-if="flash?.success" class="mx-6 mt-4 rounded-lg bg-ink px-4 py-2 text-sm text-white">{{ flash.success }}</div>
                <div v-if="flash?.error" class="mx-6 mt-4 rounded-lg bg-coral px-4 py-2 text-sm text-white">{{ flash.error }}</div>
                <main class="flex-1 p-6">
                    <slot />
                </main>
            </div>
        </div>
    </div>
</template>
