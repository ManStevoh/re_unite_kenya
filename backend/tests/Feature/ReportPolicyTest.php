<?php

namespace Tests\Feature;

use App\Models\ItemReport;
use App\Models\User;
use Database\Seeders\RolePermissionSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ReportPolicyTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_cannot_patch_another_users_report(): void
    {
        $this->seed(RolePermissionSeeder::class);

        $owner = User::factory()->create();
        $other = User::factory()->create();
        $owner->assignRole('user');
        $other->assignRole('user');

        $report = ItemReport::factory()->create([
            'user_id' => $owner->id,
            'title' => 'Owner title',
        ]);

        Sanctum::actingAs($other);
        $this->patchJson('/api/v1/reports/'.$report->id, ['title' => 'Hacked title'])
            ->assertForbidden();

        $this->assertSame('Owner title', $report->fresh()->title);
    }

    public function test_owner_can_patch_own_report(): void
    {
        $this->seed(RolePermissionSeeder::class);
        $owner = User::factory()->create();
        $owner->assignRole('user');
        $report = ItemReport::factory()->create(['user_id' => $owner->id, 'title' => 'Mine']);

        Sanctum::actingAs($owner);
        $this->patchJson('/api/v1/reports/'.$report->id, ['title' => 'Updated title'])
            ->assertOk()
            ->assertJsonPath('data.title', 'Updated title');
    }

    public function test_guest_cannot_create_a_claim(): void
    {
        $report = ItemReport::factory()->found()->create();

        $this->postJson('/api/v1/claims', ['item_report_id' => $report->id])
            ->assertUnauthorized();
    }
}
