<?php

namespace App\Domain\Search;

use Illuminate\Contracts\Pagination\LengthAwarePaginator;

interface SearchEngine
{
    /**
     * Scout-ready contract. Swap this binding for a Meilisearch implementation later.
     *
     * @param  array{q?: string, type?: string, category_id?: int, status?: string, lat?: float, lng?: float, radius?: float}  $filters
     */
    public function search(array $filters, int $perPage = 20): LengthAwarePaginator;
}
