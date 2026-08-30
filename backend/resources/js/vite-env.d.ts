/// <reference types="vite/client" />

declare module '*.vue' {
    import type { DefineComponent } from 'vue';
    const component: DefineComponent<object, object, unknown>;
    export default component;
}

declare module 'laravel-vite-plugin/inertia-helpers' {
    export function resolvePageComponent<T>(path: string, pages: Record<string, () => Promise<T>>): Promise<T>;
}
