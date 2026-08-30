<?php

namespace Database\Seeders;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Storage;

class DemoPhoto
{
    public static function store(string $filename, string $unsplashId, string $label, string $hex): string
    {
        $path = 'demo/'.$filename;
        if (Storage::disk('public')->exists($path) && Storage::disk('public')->size($path) > 800) {
            return $path;
        }

        $bytes = self::download($unsplashId) ?? self::placeholder($label, $hex);
        Storage::disk('public')->put($path, $bytes);

        return $path;
    }

    private static function download(string $unsplashId): ?string
    {
        $url = 'https://images.unsplash.com/'.$unsplashId.'?auto=format&fit=crop&w=1200&h=800&q=80';

        try {
            $response = Http::timeout(20)
                ->withHeaders(['Accept' => 'image/*', 'User-Agent' => 'ReuniteDemoSeeder/1.0'])
                ->get($url);

            if ($response->successful() && strlen($response->body()) > 800) {
                return $response->body();
            }
        } catch (\Throwable) {
            return null;
        }

        return null;
    }

    private static function placeholder(string $label, string $hex): string
    {
        $rgb = sscanf(ltrim($hex, '#'), '%02x%02x%02x') ?: [15, 76, 92];
        if (function_exists('imagecreatetruecolor')) {
            $im = imagecreatetruecolor(1200, 800);
            $bg = imagecolorallocate($im, $rgb[0], $rgb[1], $rgb[2]);
            $fg = imagecolorallocate($im, 247, 244, 239);
            imagefilledrectangle($im, 0, 0, 1200, 800, $bg);
            imagestring($im, 5, 48, 360, 'Reunite · '.$label, $fg);
            ob_start();
            imagejpeg($im, null, 82);
            $bytes = (string) ob_get_clean();
            imagedestroy($im);

            return $bytes;
        }

        return (string) base64_decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==');
    }
}
