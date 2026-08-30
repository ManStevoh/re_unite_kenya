<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('organizations', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('slug')->unique();
            $table->timestamps();
        });

        Schema::create('devices', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('name')->nullable();
            $table->string('os')->nullable();
            $table->string('last_ip', 45)->nullable();
            $table->timestamp('last_seen_at')->nullable();
            $table->unsignedBigInteger('token_id')->nullable()->index();
            $table->timestamps();
        });

        Schema::create('refresh_tokens', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('token_hash', 64)->unique();
            $table->string('device_name')->nullable();
            $table->timestamp('expires_at');
            $table->timestamp('revoked_at')->nullable();
            $table->timestamps();
        });

        Schema::create('otp_codes', function (Blueprint $table) {
            $table->id();
            $table->string('channel', 16);
            $table->string('destination');
            $table->string('code_hash');
            $table->timestamp('expires_at');
            $table->timestamp('consumed_at')->nullable();
            $table->unsignedTinyInteger('attempts')->default(0);
            $table->timestamps();
            $table->index(['destination', 'channel']);
        });

        Schema::create('categories', function (Blueprint $table) {
            $table->id();
            $table->foreignId('parent_id')->nullable()->constrained('categories')->nullOnDelete();
            $table->string('slug')->unique();
            $table->string('name');
            $table->string('sensitivity', 32)->default('public');
            $table->text('photo_guidance')->nullable();
            $table->unsignedSmallInteger('retention_days')->default(90);
            $table->unsignedSmallInteger('sort_order')->default(0);
            $table->json('schema_json')->nullable();
            $table->timestamps();
        });

        Schema::create('category_attributes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('category_id')->constrained()->cascadeOnDelete();
            $table->string('key');
            $table->string('label');
            $table->string('type', 24)->default('text');
            $table->string('visibility', 32)->default('public');
            $table->boolean('required')->default(false);
            $table->json('options_json')->nullable();
            $table->unsignedSmallInteger('sort_order')->default(0);
            $table->timestamps();
        });

        Schema::create('hubs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('organization_id')->nullable()->constrained()->nullOnDelete();
            $table->string('name');
            $table->string('type', 32)->default('mall');
            $table->string('address')->nullable();
            $table->decimal('lat', 10, 7)->nullable();
            $table->decimal('lng', 10, 7)->nullable();
            $table->json('hours_json')->nullable();
            $table->boolean('is_public')->default(true);
            $table->unsignedSmallInteger('retention_days')->default(60);
            $table->unsignedSmallInteger('capacity')->default(200);
            $table->string('contact_internal')->nullable();
            $table->timestamps();
        });

        Schema::create('hub_staff', function (Blueprint $table) {
            $table->id();
            $table->foreignId('hub_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('role', 32)->default('hub_staff');
            $table->timestamps();
            $table->unique(['hub_id', 'user_id']);
        });

        Schema::create('storage_locations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('hub_id')->constrained()->cascadeOnDelete();
            $table->string('code');
            $table->string('name');
            $table->timestamps();
            $table->unique(['hub_id', 'code']);
        });

        Schema::create('item_reports', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('type', 16);
            $table->string('title');
            $table->foreignId('category_id')->nullable()->constrained()->nullOnDelete();
            $table->text('description')->nullable();
            $table->text('hidden_notes')->nullable();
            $table->string('serial')->nullable();
            $table->json('attributes_json')->nullable();
            $table->decimal('lat', 10, 7)->nullable();
            $table->decimal('lng', 10, 7)->nullable();
            $table->string('geohash', 16)->nullable();
            $table->string('place_name')->nullable();
            $table->string('area')->nullable();
            $table->timestamp('occurred_at')->nullable();
            $table->string('status', 32)->default('draft');
            $table->string('visibility', 32)->default('public_teaser');
            $table->string('custody', 32)->nullable();
            $table->foreignId('hub_id')->nullable()->constrained()->nullOnDelete();
            $table->string('storage_code')->nullable();
            $table->string('condition')->nullable();
            $table->string('reward_note')->nullable();
            $table->text('moderation_reason')->nullable();
            $table->timestamps();

            $table->index(['type', 'status', 'category_id', 'occurred_at'], 'item_reports_type_status_cat_occurred_idx');
            $table->index(['geohash', 'status']);
            $table->index(['user_id', 'status']);
        });

        Schema::create('media_assets', function (Blueprint $table) {
            $table->id();
            $table->foreignId('report_id')->nullable()->constrained('item_reports')->cascadeOnDelete();
            $table->unsignedBigInteger('claim_id')->nullable()->index();
            $table->string('path');
            $table->string('variant', 32)->default('original');
            $table->string('visibility', 16)->default('private');
            $table->string('mime')->nullable();
            $table->unsignedInteger('size')->default(0);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('media_assets');
        Schema::dropIfExists('item_reports');
        Schema::dropIfExists('storage_locations');
        Schema::dropIfExists('hub_staff');
        Schema::dropIfExists('hubs');
        Schema::dropIfExists('category_attributes');
        Schema::dropIfExists('categories');
        Schema::dropIfExists('otp_codes');
        Schema::dropIfExists('refresh_tokens');
        Schema::dropIfExists('devices');
        Schema::dropIfExists('organizations');
    }
};
