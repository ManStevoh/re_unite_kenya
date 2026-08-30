<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('match_candidates', function (Blueprint $table) {
            $table->id();
            $table->foreignId('lost_id')->constrained('item_reports')->cascadeOnDelete();
            $table->foreignId('found_id')->constrained('item_reports')->cascadeOnDelete();
            $table->unsignedSmallInteger('score')->default(0);
            $table->json('reasons_json')->nullable();
            $table->string('status', 32)->default('suggested');
            $table->timestamps();
            $table->unique(['lost_id', 'found_id']);
        });

        Schema::create('claims', function (Blueprint $table) {
            $table->id();
            $table->foreignId('item_report_id')->constrained('item_reports')->cascadeOnDelete();
            $table->foreignId('claimant_id')->constrained('users')->cascadeOnDelete();
            $table->string('status', 32)->default('submitted');
            $table->unsignedTinyInteger('attempts')->default(0);
            $table->text('decision_reason')->nullable();
            $table->foreignId('decided_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('decided_at')->nullable();
            $table->timestamps();
            $table->index(['item_report_id', 'claimant_id', 'status'], 'claims_report_claimant_status_idx');
        });

        Schema::table('media_assets', function (Blueprint $table) {
            $table->foreign('claim_id')->references('id')->on('claims')->nullOnDelete();
        });

        Schema::create('claim_answers', function (Blueprint $table) {
            $table->id();
            $table->foreignId('claim_id')->constrained()->cascadeOnDelete();
            $table->string('question_key');
            $table->string('question');
            $table->text('answer');
            $table->timestamps();
        });

        Schema::create('claim_evidence', function (Blueprint $table) {
            $table->id();
            $table->foreignId('claim_id')->constrained()->cascadeOnDelete();
            $table->string('path');
            $table->string('note')->nullable();
            $table->timestamps();
        });

        Schema::create('conversations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('claim_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('item_report_id')->nullable()->constrained('item_reports')->nullOnDelete();
            $table->string('status', 24)->default('open');
            $table->boolean('flagged')->default(false);
            $table->timestamp('escalated_at')->nullable();
            $table->timestamps();
        });

        Schema::create('conversation_participants', function (Blueprint $table) {
            $table->id();
            $table->foreignId('conversation_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->timestamps();
            $table->unique(['conversation_id', 'user_id']);
        });

        Schema::create('messages', function (Blueprint $table) {
            $table->id();
            $table->foreignId('conversation_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->text('body');
            $table->string('image_path')->nullable();
            $table->timestamps();
            $table->index(['conversation_id', 'created_at']);
        });

        Schema::create('handovers', function (Blueprint $table) {
            $table->id();
            $table->foreignId('claim_id')->constrained()->cascadeOnDelete();
            $table->string('type', 32)->default('hub_pickup');
            $table->timestamp('scheduled_at')->nullable();
            $table->string('place')->nullable();
            $table->string('code_hash')->nullable();
            $table->string('status', 32)->default('scheduled');
            $table->timestamp('confirmed_at')->nullable();
            $table->foreignId('confirmed_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
        });

        Schema::create('flags', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('target_type');
            $table->unsignedBigInteger('target_id');
            $table->string('reason', 64);
            $table->text('details')->nullable();
            $table->string('severity', 16)->default('medium');
            $table->string('status', 24)->default('open');
            $table->timestamps();
            $table->index(['target_type', 'target_id']);
        });

        Schema::create('disputes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('item_report_id')->constrained('item_reports')->cascadeOnDelete();
            $table->string('type', 64);
            $table->text('notes')->nullable();
            $table->string('status', 24)->default('open');
            $table->foreignId('resolved_by')->nullable()->constrained('users')->nullOnDelete();
            $table->text('resolution')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('disputes');
        Schema::dropIfExists('flags');
        Schema::dropIfExists('handovers');
        Schema::dropIfExists('messages');
        Schema::dropIfExists('conversation_participants');
        Schema::dropIfExists('conversations');
        Schema::dropIfExists('claim_evidence');
        Schema::dropIfExists('claim_answers');
        Schema::table('media_assets', function (Blueprint $table) {
            $table->dropForeign(['claim_id']);
        });
        Schema::dropIfExists('claims');
        Schema::dropIfExists('match_candidates');
    }
};
