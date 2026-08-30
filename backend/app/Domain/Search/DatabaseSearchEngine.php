<?php

namespace App\Domain\Search;

use App\Domain\Geo\GeoHash;
use App\Models\ItemReport;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class DatabaseSearchEngine implements SearchEngine
{
    public function search(array $filters, int $perPage = 20): LengthAwarePaginator
    {
        $query = ItemReport::query()
            ->with(['category', 'hub', 'media'])
            ->whereIn('status', ['published', 'matched', 'claim_in_progress'])
            ->where('visibility', 'public_teaser');

        if (! empty($filters['type'])) {
            $query->where('type', $filters['type']);
        }

        if (! empty($filters['category_id'])) {
            $query->where('category_id', $filters['category_id']);
        }

        if (! empty($filters['status'])) {
            $query->where('status', $filters['status']);
        }

        if (! empty($filters['q'])) {
            $term = '%'.$filters['q'].'%';
            $query->where(function ($q) use ($term) {
                $q->where('title', 'like', $term)
                    ->orWhere('description', 'like', $term)
                    ->orWhere('area', 'like', $term)
                    ->orWhere('place_name', 'like', $term);
            });
        }

        if (isset($filters['lat'], $filters['lng'])) {
            $query->whereNotNull('lat')->whereNotNull('lng');
        }

        $paginator = $query->latest('occurred_at')->paginate($perPage);

        if (isset($filters['lat'], $filters['lng'], $filters['radius'])) {
            $lat = (float) $filters['lat'];
            $lng = (float) $filters['lng'];
            $radius = (float) $filters['radius'];
            $paginator->setCollection(
                $paginator->getCollection()->filter(function (ItemReport $report) use ($lat, $lng, $radius) {
                    if (! $report->lat || ! $report->lng) {
                        return false;
                    }

                    return GeoHash::haversineKm($lat, $lng, (float) $report->lat, (float) $report->lng) <= $radius;
                })->values()
            );
        }

        return $paginator;
    }
}
