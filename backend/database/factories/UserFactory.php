<?php

namespace Database\Factories;

use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

/**
 * @extends Factory<User>
 */
class UserFactory extends Factory
{
    protected static ?string $password;

    public function definition(): array
    {
        return [
            'name' => fake()->name(),
            'display_name' => fake()->firstName(),
            'email' => fake()->unique()->safeEmail(),
            'email_verified_at' => now(),
            'password' => static::$password ??= Hash::make('password'),
            'phone' => '+2547'.fake()->unique()->numerify('#######'),
            'phone_verified_at' => now(),
            'city' => 'Nairobi',
            'status' => 'active',
            'verification_level' => 3,
            'trust_score' => 60,
            'reputation_points' => 0,
            'locale' => 'en',
            'id_verification_status' => 'none',
            'remember_token' => Str::random(10),
        ];
    }

    public function unverified(): static
    {
        return $this->state(fn () => [
            'email_verified_at' => null,
            'phone_verified_at' => null,
            'status' => 'pending_verification',
            'verification_level' => 1,
        ]);
    }
}
