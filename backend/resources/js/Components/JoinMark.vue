<script setup lang="ts">
import { useId } from 'vue';

withDefaults(
    defineProps<{
        size?: number;
    }>(),
    { size: 36 },
);

const clipId = `join-vesica-${useId().replace(/:/g, '')}`;
</script>

<template>
    <svg
        :width="size * 1.55"
        :height="size"
        viewBox="0 0 72 48"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
        aria-hidden="true"
    >
        <defs>
            <clipPath :id="clipId">
                <circle cx="26" cy="24" r="16" />
            </clipPath>
        </defs>
        <circle cx="46" cy="24" r="16" fill="#E36414" :clip-path="`url(#${clipId})`" />
        <circle cx="26" cy="24" r="16" stroke="#0F4C5C" stroke-width="5.2" />
        <circle cx="46" cy="24" r="16" stroke="#0F4C5C" stroke-width="5.2" />
    </svg>
</template>
