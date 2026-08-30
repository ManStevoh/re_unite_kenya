<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('display_name')->nullable()->after('name');
            $table->string('phone')->nullable()->unique()->after('email');
            $table->timestamp('phone_verified_at')->nullable()->after('phone');
            $table->string('city')->nullable();
            $table->string('avatar_path')->nullable();
            $table->string('status', 32)->default('pending_verification')->index();
            $table->unsignedTinyInteger('verification_level')->default(1);
            $table->unsignedSmallInteger('trust_score')->default(50);
            $table->unsignedInteger('reputation_points')->default(0);
            $table->string('locale', 8)->default('en');
            $table->string('id_verification_status', 32)->default('none');
            $table->json('notification_preferences')->nullable();
            $table->softDeletes();
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn([
                'display_name',
                'phone',
                'phone_verified_at',
                'city',
                'avatar_path',
                'status',
                'verification_level',
                'trust_score',
                'reputation_points',
                'locale',
                'id_verification_status',
                'notification_preferences',
                'deleted_at',
            ]);
        });
    }
};
