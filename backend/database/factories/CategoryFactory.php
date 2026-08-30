<?php

namespace Database\Factories;

use App\Models\Category;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

/**
 * @extends Factory<Category>
 */
class CategoryFactory extends Factory
{
    public function definition(): array
    {
        $name = fake()->unique()->words(2, true);

        return [
            'slug' => Str::slug($name).'-'.fake()->unique()->numerify('##'),
            'name' => ucfirst($name),
            'sensitivity' => 'public',
            'photo_guidance' => 'Avoid capturing ID numbers.',
            'retention_days' => 90,
            'sort_order' => 1,
        ];
    }
}
