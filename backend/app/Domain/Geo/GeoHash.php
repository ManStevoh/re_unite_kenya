<?php

namespace App\Domain\Geo;

class GeoHash
{
    private const BASE32 = '0123456789bcdefghjkmnpqrstuvwxyz';

    public static function encode(float $lat, float $lng, int $precision = 7): string
    {
        $minLat = -90.0;
        $maxLat = 90.0;
        $minLng = -180.0;
        $maxLng = 180.0;
        $hash = '';
        $bit = 0;
        $ch = 0;
        $even = true;

        while (strlen($hash) < $precision) {
            if ($even) {
                $mid = ($minLng + $maxLng) / 2;
                if ($lng > $mid) {
                    $ch |= 1 << (4 - $bit);
                    $minLng = $mid;
                } else {
                    $maxLng = $mid;
                }
            } else {
                $mid = ($minLat + $maxLat) / 2;
                if ($lat > $mid) {
                    $ch |= 1 << (4 - $bit);
                    $minLat = $mid;
                } else {
                    $maxLat = $mid;
                }
            }

            $even = ! $even;

            if ($bit < 4) {
                $bit++;
            } else {
                $hash .= self::BASE32[$ch];
                $bit = 0;
                $ch = 0;
            }
        }

        return $hash;
    }

    public static function haversineKm(float $lat1, float $lng1, float $lat2, float $lng2): float
    {
        $earth = 6371;
        $dLat = deg2rad($lat2 - $lat1);
        $dLng = deg2rad($lng2 - $lng1);
        $a = sin($dLat / 2) ** 2 + cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * sin($dLng / 2) ** 2;

        return $earth * 2 * atan2(sqrt($a), sqrt(1 - $a));
    }
}
