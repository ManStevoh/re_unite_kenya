<?php

namespace Tests\Feature;

use App\Models\ItemReport;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class TeaserPrivacyTest extends TestCase
{
    use RefreshDatabase;

    public function test_public_show_omits_hidden_fields(): void
    {
        $report = ItemReport::factory()->create([
            'status' => 'published',
            'visibility' => 'public_teaser',
            'serial' => 'SECRET-SERIAL-99',
            'hidden_notes' => 'initials JK inside',
            'lat' => -1.2921,
            'lng' => 36.8219,
        ]);

        $response = $this->getJson('/api/v1/reports/'.$report->id);

        $response->assertOk();
        $response->assertJsonPath('data.id', $report->id);
        $response->assertJsonPath('data.title', $report->title);
        $response->assertJsonMissingPath('data.serial');
        $response->assertJsonMissingPath('data.hidden_notes');
        $response->assertJsonMissingPath('data.lat');
        $response->assertJsonMissingPath('data.lng');
        $this->assertArrayNotHasKey('email', $response->json('data.owner') ?? []);
        $this->assertArrayNotHasKey('phone', $response->json('data') ?? []);
        $this->assertStringNotContainsString('SECRET-SERIAL-99', $response->getContent());
        $this->assertStringNotContainsString('initials JK inside', $response->getContent());
    }

    public function test_owner_can_see_hidden_fields(): void
    {
        $owner = User::factory()->create();
        $report = ItemReport::factory()->create([
            'user_id' => $owner->id,
            'status' => 'published',
            'serial' => 'SECRET-SERIAL-99',
            'hidden_notes' => 'initials JK inside',
        ]);

        Sanctum::actingAs($owner);
        $this->getJson('/api/v1/reports/'.$report->id)
            ->assertOk()
            ->assertJsonPath('data.serial', 'SECRET-SERIAL-99')
            ->assertJsonPath('data.hidden_notes', 'initials JK inside');
    }
}
