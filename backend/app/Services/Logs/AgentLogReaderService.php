<?php

namespace App\Services\Logs;

use Carbon\Carbon;
use Throwable;

class AgentLogReaderService
{
    public const DEFAULT_LINES = 50;
    public const MAX_LINES = 500;

    private array $fileChannels = [];

    public function __construct()
    {
        $this->fileChannels = [
            'laravel' => storage_path('logs/laravel.log'),
            'deploy'  => storage_path('logs/deploy.log'),
        ];
    }

    public function read(
        string $channel = 'laravel',
        ?string $level = null,
        int $lines = self::DEFAULT_LINES,
        ?string $grep = null,
        ?string $since = null
    ): array {
        $lines = max(1, min(self::MAX_LINES, $lines));
        $level = ! empty($level) && $level !== 'all' ? strtolower(trim($level)) : null;
        $grep  = ! empty($grep) ? trim($grep) : null;
        $sinceTimestamp = $this->parseSinceTimestamp($since);

        if ($channel === 'all') {
            return $this->readAllChannels($lines, $level, $grep, $sinceTimestamp);
        }

        $filePath = $this->fileChannels[$channel] ?? $this->fileChannels['laravel'];
        $actualChannel = isset($this->fileChannels[$channel]) ? $channel : 'laravel';

        return $this->tailFile($filePath, $lines, $level, $grep, $sinceTimestamp, $actualChannel);
    }

    public function tailFile(
        string $filePath,
        int $lines = self::DEFAULT_LINES,
        ?string $level = null,
        ?string $grep = null,
        ?int $sinceTimestamp = null,
        string $channelName = 'laravel'
    ): array {
        if (! file_exists($filePath) || ! is_readable($filePath)) {
            return ['channel' => $channelName, 'count' => 0, 'total_available' => 0, 'logs' => []];
        }

        $fp = @fopen($filePath, 'rb');
        if (! $fp) {
            return ['channel' => $channelName, 'count' => 0, 'total_available' => 0, 'logs' => []];
        }

        $fileSize = filesize($filePath);
        if ($fileSize === 0) {
            fclose($fp);
            return ['channel' => $channelName, 'count' => 0, 'total_available' => 0, 'logs' => []];
        }

        $chunkSize = 8192;
        $pos = $fileSize;
        $buffer = '';
        $matchedEntries = [];
        $totalParsed = 0;

        while ($pos > 0 && count($matchedEntries) < $lines) {
            $readLength = min($chunkSize, $pos);
            $pos -= $readLength;
            fseek($fp, $pos);
            $chunk = fread($fp, $readLength);
            $buffer = $chunk . $buffer;
            $rawLines = explode("\n", $buffer);
            $buffer = array_shift($rawLines);

            for ($i = count($rawLines) - 1; $i >= 0; $i--) {
                $rawLine = trim($rawLines[$i]);
                if ($rawLine === '') {
                    continue;
                }

                $totalParsed++;
                $parsed = $this->parseLogLine($rawLine, $channelName);
                if (! $parsed) {
                    continue;
                }

                if ($sinceTimestamp !== null && $parsed['timestamp_unix'] < $sinceTimestamp) {
                    $pos = 0;
                    break;
                }

                if ($level !== null && strtolower($parsed['level']) !== $level) {
                    continue;
                }

                if ($grep !== null && ! $this->matchesGrep($rawLine, $grep)) {
                    continue;
                }

                $parsed['message'] = LogDataScrubber::scrub($parsed['message']);
                $matchedEntries[] = $parsed;

                if (count($matchedEntries) >= $lines) {
                    break;
                }
            }
        }

        if (! empty($buffer) && count($matchedEntries) < $lines) {
            $parsed = $this->parseLogLine(trim($buffer), $channelName);
            if ($parsed && ($sinceTimestamp === null || $parsed['timestamp_unix'] >= $sinceTimestamp)) {
                $levelMatches = ($level === null || strtolower($parsed['level']) === $level);
                $grepMatches  = ($grep === null || $this->matchesGrep($buffer, $grep));
                if ($levelMatches && $grepMatches) {
                    $parsed['message'] = LogDataScrubber::scrub($parsed['message']);
                    $matchedEntries[] = $parsed;
                }
            }
        }

        fclose($fp);

        return [
            'channel'         => $channelName,
            'count'           => count($matchedEntries),
            'total_available' => $totalParsed,
            'logs'            => $matchedEntries,
        ];
    }

    public function tailStream(
        string $channel,
        callable $onLine,
        int $durationSeconds = 60,
        ?string $level = null,
        ?string $grep = null
    ): void {
        $filePath = $this->fileChannels[$channel] ?? $this->fileChannels['laravel'];
        if (! file_exists($filePath)) {
            @touch($filePath);
        }

        $fp = @fopen($filePath, 'rb');
        if (! $fp) {
            return;
        }

        fseek($fp, 0, SEEK_END);
        $deadline = time() + $durationSeconds;

        while (time() < $deadline) {
            $line = fgets($fp);
            if ($line !== false) {
                $trimmed = trim($line);
                if ($trimmed !== '') {
                    $parsed = $this->parseLogLine($trimmed, $channel);
                    if ($parsed) {
                        if ($level !== null && strtolower($parsed['level']) !== strtolower($level)) {
                            continue;
                        }
                        if ($grep !== null && ! $this->matchesGrep($trimmed, $grep)) {
                            continue;
                        }
                        $parsed['message'] = LogDataScrubber::scrub($parsed['message']);
                        $onLine($parsed);
                    }
                }
            } else {
                usleep(250_000);
            }
        }

        fclose($fp);
    }

    private function readAllChannels(int $lines, ?string $level, ?string $grep, ?int $sinceTimestamp): array
    {
        $allLogs = [];
        $totalParsed = 0;

        foreach ($this->fileChannels as $channelName => $filePath) {
            $result = $this->tailFile($filePath, $lines, $level, $grep, $sinceTimestamp, $channelName);
            $totalParsed += $result['total_available'];
            foreach ($result['logs'] as $log) {
                $allLogs[] = $log;
            }
        }

        usort($allLogs, fn ($a, $b) => ($b['timestamp_unix'] ?? 0) <=> ($a['timestamp_unix'] ?? 0));
        $sliced = array_slice($allLogs, 0, $lines);

        return [
            'channel'         => 'all',
            'count'           => count($sliced),
            'total_available' => $totalParsed,
            'logs'            => $sliced,
        ];
    }

    public function parseLogLine(string $line, string $channelName): ?array
    {
        $trimmed = trim($line);
        if ($trimmed === '') {
            return null;
        }

        if (str_starts_with($trimmed, '{') && str_ends_with($trimmed, '}')) {
            $json = json_decode($trimmed, true);
            if (is_array($json)) {
                $timeStr = $json['timestamp'] ?? $json['created_at'] ?? now()->toIso8601String();
                $timeUnix = strtotime($timeStr) ?: time();
                $level = strtoupper($json['status'] ?? $json['level'] ?? 'INFO');

                return [
                    'timestamp'      => date('c', $timeUnix),
                    'timestamp_unix' => $timeUnix,
                    'level'          => $level === 'SUCCESS' ? 'INFO' : ($level === 'FAILURE' ? 'ERROR' : $level),
                    'channel'        => $channelName,
                    'message'        => json_encode(LogDataScrubber::scrubArray($json), JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE),
                    'raw'            => $trimmed,
                ];
            }
        }

        if (preg_match('/^\[?(\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2}(?:\.\d+)?)\]?\s+([a-zA-Z0-9_\-]+)\.([A-Z]+):\s+(.*)$/s', $trimmed, $m)) {
            $timeUnix = strtotime($m[1]) ?: time();

            return [
                'timestamp'      => date('c', $timeUnix),
                'timestamp_unix' => $timeUnix,
                'level'          => strtoupper($m[3]),
                'channel'        => $channelName,
                'message'        => trim($m[4]),
                'raw'            => $trimmed,
            ];
        }

        return [
            'timestamp'      => now()->toIso8601String(),
            'timestamp_unix' => time(),
            'level'          => 'INFO',
            'channel'        => $channelName,
            'message'        => $trimmed,
            'raw'            => $trimmed,
        ];
    }

    private function matchesGrep(string $line, string $grep): bool
    {
        if (str_starts_with($grep, '/') && str_ends_with($grep, '/')) {
            return (bool) @preg_match($grep, $line);
        }

        return stripos($line, $grep) !== false;
    }

    private function parseSinceTimestamp(?string $since): ?int
    {
        if (empty($since)) {
            return null;
        }

        if (preg_match('/^(\d+)\s*([mhdw])$/i', trim($since), $m)) {
            $val = (int) $m[1];
            $unit = strtolower($m[2]);

            return match ($unit) {
                'm' => now()->subMinutes($val)->timestamp,
                'h' => now()->subHours($val)->timestamp,
                'd' => now()->subDays($val)->timestamp,
                'w' => now()->subWeeks($val)->timestamp,
                default => null,
            };
        }

        try {
            return Carbon::parse($since)->timestamp;
        } catch (Throwable) {
            return null;
        }
    }
}
