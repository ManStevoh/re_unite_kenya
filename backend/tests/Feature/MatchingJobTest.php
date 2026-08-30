<?php

namespace Tests\Feature;

use App\Jobs\ComputeMatchesJob;
use App\Models\Category;
use App\Models\ItemReport;
use App\Models\MatchCandidate;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class MatchingJobTest extends TestCase
{
    use RefreshDatabase;

    public function test_it_stores_a_high_scoring_candidate(): void
    {
        $category = Category::factory()->create();
        $owner = User::factory()->create(['status' => 'active']);
        $finder = User::factory()->create(['status' => 'active']);

        $lost = ItemReport::factory()->create([
            'user_id' => $owner->id,
            'type' => 'lost',
            'category_id' => $category->id,
            'status' => 'published',
            'attributes_json' => ['color' => 'black', 'brand' => 'Fossil'],
            'lat' => -1.2921,
            'lng' => 36.8219,
            'serial' => 'ABC1234',
            'hidden_notes' => 'JK lining',
            'occurred_at' => now()->subDay(),
        ]);

        ItemReport::factory()->found()->create([
            'user_id' => $finder->id,
            'category_id' => $category->id,
            'status' => 'published',
            'attributes_json' => ['color' => 'black', 'brand' => 'Fossil'],
            'lat' => -1.2920,
            'lng' => 36.8218,
            'serial' => 'ABC1234',
            'hidden_notes' => 'JK lining',
            'occurred_at' => now()->subHours(12),
        ]);

        (new ComputeMatchesJob($lost->id))->handle(app(\App\Domain\Matching\MatchingService::class));

        $this->assertTrue(MatchCandidate::query()->where('lost_id', $lost->id)->exists());
        $this->assertGreaterThanOrEqual(60, MatchCandidate::query()->where('lost_id', $lost->id)->value('score'));
    }
}
