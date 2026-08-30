<?php

namespace App\Console\Commands;

use App\Services\Logs\AgentLogReaderService;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Http;

class LogsAgentCommand extends Command
{
    protected $signature = 'logs:agent
                            {channel=laravel : Channel to inspect}
                            {--level= : Filter severity (error, warning, info)}
                            {--lines=50 : Number of lines}
                            {--grep= : Keyword filter}
                            {--since= : Time window (e.g. 15m, 1h, 24h)}
                            {--tail : Live stream}
                            {--remote= : Remote base URL}
                            {--json : Output raw JSON}';

    protected $description = 'Inspect server logs via Agent Gateway';

    public function handle(AgentLogReaderService $logReader): int
    {
        $channel   = (string) $this->argument('channel');
        $level     = (string) $this->option('level');
        $lines     = (int) $this->option('lines');
        $grep      = (string) $this->option('grep');
        $since     = (string) $this->option('since');
        $remoteUrl = (string) $this->option('remote');

        if (! empty($remoteUrl)) {
            $key = env('DEPLOY_AGENT_KEY', env('DEPLOY_SECRET'));
            $res = Http::withHeaders(['X-Deploy-Agent-Key' => $key])
                ->post(rtrim($remoteUrl, '/') . '/logs/agent', [
                    'channel' => $channel,
                    'level'   => $level,
                    'lines'   => $lines,
                    'grep'    => $grep,
                    'since'   => $since,
                ]);

            if ($this->option('json')) {
                $this->line($res->body());
                return self::SUCCESS;
            }

            $data = $res->json('logs') ?? [];
            foreach (array_reverse($data) as $entry) {
                $this->line("[{$entry['timestamp']}] [{$entry['level']}] {$entry['message']}");
            }

            return self::SUCCESS;
        }

        $result = $logReader->read($channel, $level ?: null, $lines, $grep ?: null, $since ?: null);

        if ($this->option('json')) {
            $this->line(json_encode($result, JSON_PRETTY_PRINT));
            return self::SUCCESS;
        }

        foreach (array_reverse($result['logs']) as $entry) {
            $this->line("[{$entry['timestamp']}] [{$entry['level']}] {$entry['message']}");
        }

        return self::SUCCESS;
    }
}
