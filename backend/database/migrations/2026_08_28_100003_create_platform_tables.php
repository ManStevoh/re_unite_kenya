<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('audit_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('actor_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('action');
            $table->string('subject_type')->nullable();
            $table->unsignedBigInteger('subject_id')->nullable();
            $table->json('properties')->nullable();
            $table->string('ip_address', 45)->nullable();
            $table->text('user_agent')->nullable();
            $table->timestamps();
            $table->index(['subject_type', 'subject_id', 'created_at'], 'audit_logs_subject_created_idx');
        });

        Schema::create('settings', function (Blueprint $table) {
            $table->id();
            $table->string('key')->unique();
            $table->json('value_json')->nullable();
            $table->timestamps();
        });

        Schema::create('cms_pages', function (Blueprint $table) {
            $table->id();
            $table->string('slug')->unique();
            $table->string('title');
            $table->longText('body')->nullable();
            $table->boolean('published')->default(false);
            $table->timestamps();
        });

        Schema::create('qr_tags', function (Blueprint $table) {
            $table->id();
            $table->string('code')->unique();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('item_label')->nullable();
            $table->string('status', 24)->default('active');
            $table->timestamps();
        });

        Schema::create('tips', function (Blueprint $table) {
            $table->id();
            $table->foreignId('from_user')->constrained('users')->cascadeOnDelete();
            $table->foreignId('to_user')->constrained('users')->cascadeOnDelete();
            $table->foreignId('claim_id')->nullable()->constrained()->nullOnDelete();
            $table->unsignedInteger('amount')->default(0);
            $table->string('status', 24)->default('pending');
            $table->timestamps();
        });

        Schema::create('delivery_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->string('channel', 16);
            $table->string('event');
            $table->string('recipient_masked');
            $table->string('status', 24)->default('queued');
            $table->text('error')->nullable();
            $table->timestamps();
        });

        Schema::create('notifications', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->string('type');
            $table->morphs('notifiable');
            $table->text('data');
            $table->timestamp('read_at')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('notifications');
        Schema::dropIfExists('delivery_logs');
        Schema::dropIfExists('tips');
        Schema::dropIfExists('qr_tags');
        Schema::dropIfExists('cms_pages');
        Schema::dropIfExists('settings');
        Schema::dropIfExists('audit_logs');
    }
};
