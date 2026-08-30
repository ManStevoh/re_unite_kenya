<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Cache;

#[Fillable(['key', 'value_json'])]
class Setting extends Model
{
    protected function casts(): array
    {
        return [
            'value_json' => 'array',
        ];
    }

    public static function getValue(string $key, mixed $default = null): mixed
    {
        return Cache::remember("setting:{$key}", 60, function () use ($key, $default) {
            $row = static::query()->where('key', $key)->first();

            return $row?->value_json ?? $default;
        });
    }

    public static function setValue(string $key, mixed $value): self
    {
        $row = static::query()->updateOrCreate(['key' => $key], ['value_json' => $value]);
        Cache::forget("setting:{$key}");

        return $row;
    }
}
