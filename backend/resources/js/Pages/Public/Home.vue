<script setup lang="ts">
import PublicLayout from '../../Layouts/PublicLayout.vue';
import StoreBadges from '../../Components/StoreBadges.vue';
defineOptions({ layout: PublicLayout });
</script>

<template>
    <div>
        <section class="relative overflow-hidden bg-gradient-to-br from-sand via-paper to-[#f4e6d8]">
            <div class="mx-auto grid max-w-6xl items-center gap-12 px-6 py-14 md:grid-cols-2 md:py-20">
                <div>
                    <p class="text-sm font-medium tracking-wide text-coral">Reunite for iOS and Android</p>
                    <h1 class="mt-3 text-4xl font-semibold leading-[1.1] text-ink md:text-5xl">
                        Get things back,
                        <span class="text-coral">privately.</span>
                    </h1>
                    <p class="mt-5 max-w-md text-lg leading-relaxed text-ink/65">
                        Report what you lost or found, answer hidden-mark claims, and meet at a trusted hub. The public never sees serials, IDs, or exact pins.
                    </p>
                    <div id="download" class="mt-8">
                        <StoreBadges />
                    </div>
                    <p class="mt-3 text-sm text-ink/45">Free to download. Browse teasers as a guest.</p>
                </div>
                <div class="flex justify-center md:justify-end">
                    <img
                        src="/images/app-phone.png"
                        alt="Reunite app on a phone"
                        class="w-full max-w-sm drop-shadow-2xl md:max-w-md"
                    >
                </div>
            </div>
        </section>
        <section class="mx-auto grid max-w-6xl gap-6 px-6 py-14 md:grid-cols-3">
            <article class="rounded-3xl bg-paper p-6">
                <p class="text-sm font-medium text-coral">Teasers only</p>
                <h2 class="mt-2 text-lg font-semibold">Color and area, not secrets</h2>
                <p class="mt-2 text-sm leading-relaxed text-ink/60">Listings stay useful without exposing a serial, an ID number, or a home pin.</p>
            </article>
            <article class="rounded-3xl bg-paper p-6">
                <p class="text-sm font-medium text-coral">Verified claims</p>
                <h2 class="mt-2 text-lg font-semibold">Prove it is yours</h2>
                <p class="mt-2 text-sm leading-relaxed text-ink/60">Hidden marks stay in the app until a finder or hub accepts the claim.</p>
            </article>
            <article class="rounded-3xl bg-paper p-6">
                <p class="text-sm font-medium text-coral">Trusted hubs</p>
                <h2 class="mt-2 text-lg font-semibold">Hand over in public</h2>
                <p class="mt-2 text-sm leading-relaxed text-ink/60">Malls, campuses, and stations across Kenya hold items so you do not meet at a house.</p>
            </article>
        </section>
    </div>
</template>
