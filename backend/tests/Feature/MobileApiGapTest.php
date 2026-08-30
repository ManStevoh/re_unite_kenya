<?php

namespace Tests\Feature;

use App\Models\Category;
use App\Models\Claim;
use App\Models\CmsPage;
use App\Models\ItemReport;
use App\Models\User;
use Database\Seeders\RolePermissionSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class MobileApiGapTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RolePermissionSeeder::class);
    }

    public function test_user_can_list_own_reports_and_drafts(): void
    {
        $user = User::factory()->create();
        $user->assignRole('user');
        $mine = ItemReport::factory()->create(['user_id' => $user->id, 'status' => 'published']);
        $draft = ItemReport::factory()->create(['user_id' => $user->id, 'status' => 'draft']);
        ItemReport::factory()->create(['status' => 'published']);

        Sanctum::actingAs($user);
        $this->getJson('/api/v1/me/reports')
            ->assertOk()
            ->assertJsonCount(2, 'data');
        $this->getJson('/api/v1/me/drafts')
            ->assertOk()
            ->assertJsonPath('data.0.id', $draft->id);
        $this->assertNotNull($mine->id);
    }

    public function test_user_can_list_and_review_claims(): void
    {
        $owner = User::factory()->create();
        $claimant = User::factory()->create();
        $owner->assignRole('user');
        $claimant->assignRole('user');
        $report = ItemReport::factory()->create(['user_id' => $owner->id, 'status' => 'published']);
        $claim = Claim::query()->create([
            'item_report_id' => $report->id,
            'claimant_id' => $claimant->id,
            'status' => 'in_review',
            'attempts' => 1,
        ]);

        Sanctum::actingAs($owner);
        $this->getJson('/api/v1/claims')->assertOk()->assertJsonPath('data.0.id', $claim->id);
        $this->postJson('/api/v1/claims/'.$claim->id.'/review', ['accept' => true])
            ->assertOk()
            ->assertJsonPath('data.status', 'approved');
    }

    public function test_catalog_and_help_pages_are_public(): void
    {
        Category::factory()->create(['name' => 'Umbrellas', 'slug' => 'umbrellas']);
        CmsPage::query()->create([
            'slug' => 'privacy',
            'title' => 'Privacy',
            'body' => 'We hide serials.',
            'published' => true,
        ]);

        $this->getJson('/api/v1/categories')->assertOk()->assertJsonFragment(['name' => 'Umbrellas']);
        $this->getJson('/api/v1/cms')->assertOk()->assertJsonFragment(['slug' => 'privacy']);
    }

    public function test_admin_can_create_a_category(): void
    {
        $admin = User::factory()->create();
        $admin->assignRole('admin');

        $this->actingAs($admin)
            ->from('/admin/categories')
            ->post('/admin/categories', [
                'name' => 'Musical instruments',
                'sensitivity' => 'public',
                'retention_days' => 90,
                'photo_guidance' => 'Hide faces.',
                'icon' => 'music_note',
            ])
            ->assertRedirect();

        $this->assertDatabaseHas('categories', ['name' => 'Musical instruments', 'slug' => 'musical-instruments']);
    }
}
