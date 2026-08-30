<?php

namespace App\Domain\Matching;

use App\Domain\Geo\GeoHash;
use App\Models\ItemReport;

class DeterministicMatchingEngine implements MatchingEngine
{
    public function score(ItemReport $lost, ItemReport $found): ?array
    {
        if ($lost->type === $found->type) {
            return null;
        }

        $owner = $lost->isLost() ? $lost : $found;
        $finder = $lost->isLost() ? $found : $lost;

        if ($owner->type !== 'lost' || $finder->type !== 'found') {
            return null;
        }

        if ($owner->category_id && $finder->category_id && $owner->category_id !== $finder->category_id) {
            return null;
        }

        $score = 0;
        $reasons = [];

        if ($owner->category_id && $owner->category_id === $finder->category_id) {
            $score += 40;
            $reasons[] = 'same_category';
        }

        $ownerAttrs = $owner->attributes_json ?? [];
        $finderAttrs = $finder->attributes_json ?? [];

        if ($this->overlap($ownerAttrs, $finderAttrs, ['type', 'subcategory', 'item_type'])) {
            $score += 15;
            $reasons[] = 'same_subcategory';
        }

        if ($this->overlap($ownerAttrs, $finderAttrs, ['color', 'colour'])) {
            $score += 10;
            $reasons[] = 'color';
        }

        if ($this->overlap($ownerAttrs, $finderAttrs, ['brand', 'model'])) {
            $score += 15;
            $reasons[] = 'brand_model';
        }

        if ($owner->occurred_at && $finder->occurred_at) {
            $diffHours = abs($owner->occurred_at->diffInHours($finder->occurred_at));
            if ($diffHours <= 72) {
                $score += 10;
                $reasons[] = 'date_overlap';
            }

            if ($owner->occurred_at->gt($finder->occurred_at->copy()->addDay())) {
                $score -= 25;
                $reasons[] = 'lost_after_found';
            }
        }

        if ($owner->lat && $owner->lng && $finder->lat && $finder->lng) {
            $km = GeoHash::haversineKm((float) $owner->lat, (float) $owner->lng, (float) $finder->lat, (float) $finder->lng);
            if ($km < 1) {
                $score += 15;
                $reasons[] = 'nearby';
            } elseif ($km < 5) {
                $score += 8;
                $reasons[] = 'nearby';
            }
        }

        if ($owner->hub_id && $finder->hub_id && $owner->hub_id === $finder->hub_id) {
            $score += 10;
            $reasons[] = 'same_hub';
        }

        $tokens = $this->uncommonTokens($owner, $finder);
        if ($tokens !== []) {
            $score += 20;
            $reasons[] = 'shared_keyword';
        }

        return [
            'score' => max(0, $score),
            'reasons' => $reasons,
        ];
    }

    /**
     * @param  array<string, mixed>  $a
     * @param  array<string, mixed>  $b
     * @param  list<string>  $keys
     */
    private function overlap(array $a, array $b, array $keys): bool
    {
        foreach ($keys as $key) {
            $left = isset($a[$key]) ? mb_strtolower((string) $a[$key]) : null;
            $right = isset($b[$key]) ? mb_strtolower((string) $b[$key]) : null;
            if ($left && $right && $left === $right) {
                return true;
            }
        }

        return false;
    }

    /**
     * @return list<string>
     */
    private function uncommonTokens(ItemReport $owner, ItemReport $finder): array
    {
        $hay = mb_strtolower(implode(' ', array_filter([
            $owner->serial,
            $owner->hidden_notes,
            $finder->serial,
            $finder->hidden_notes,
        ])));

        $tokens = preg_split('/[^a-z0-9]+/i', $hay, -1, PREG_SPLIT_NO_EMPTY) ?: [];
        $tokens = array_values(array_unique(array_filter($tokens, fn (string $t) => strlen($t) >= 4)));

        $ownerBits = mb_strtolower(implode(' ', array_filter([$owner->serial, $owner->hidden_notes])));
        $finderBits = mb_strtolower(implode(' ', array_filter([$finder->serial, $finder->hidden_notes])));

        return array_values(array_filter($tokens, fn (string $t) => str_contains($ownerBits, $t) && str_contains($finderBits, $t)));
    }
}
