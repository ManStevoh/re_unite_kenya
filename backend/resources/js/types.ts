export type AuthUser = {
    id: number;
    name: string;
    display_name: string;
    email?: string;
    roles?: string[];
    permissions?: string[];
};

export type Paginator<T> = {
    data: T[];
    links: { url: string | null; label: string; active: boolean }[];
    current_page: number;
    last_page: number;
    total: number;
};

export type Teaser = {
    id: number;
    type: string;
    title: string;
    category?: string | null;
    color?: string | null;
    area?: string | null;
    occurred_on?: string | null;
    thumbnail?: string | null;
    hub_name?: string | null;
    status?: string;
};
