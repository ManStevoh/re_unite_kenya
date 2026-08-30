<?php

namespace Database\Factories;

use App\Models\Category;
use App\Models\ItemReport;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<ItemReport>
 */
class ItemReportFactory extends Factory
{
    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'type' => 'lost',
            'title' => 'Black leather wallet',
            'category_id' => fn () => Category::query()->value('id') ?? Category::factory()->create()->id,
            'description' => 'Public blurb about a wallet',
            'hidden_notes' => 'initials JK inside',
            'serial' => 'SECRET-SERIAL-99',
            'attributes_json' => ['color' => 'black', 'brand' => 'Fossil'],
            'lat' => -1.2921,
            'lng' => 36.8219,
            'geohash' => 'kzf0t',
            'place_name' => 'City Mall, Level 2',
            'area' => 'City Mall',
            'occurred_at' => now()->subDay(),
            'status' => 'published',
            'visibility' => 'public_teaser',
            'custody' => null,
        ];
    }

    public function found(): static
    {
        return $this->state(fn () => [
            'type' => 'found',
            'custody' => 'with_finder',
        ]);
    }
}
