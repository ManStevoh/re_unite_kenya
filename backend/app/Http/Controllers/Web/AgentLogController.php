<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Services\Deploy\DeployAuthService;
use App\Services\Logs\AgentLogReaderService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\HttpFoundation\StreamedResponse;

class AgentLogController extends Controller
{
    public function __construct(
        private readonly DeployAuthService $authService,
        private readonly AgentLogReaderService $logReader,
    ) {}

    public function handle(Request $request): Response|JsonResponse|StreamedResponse
    {
        $key = (string) (
            $request->header('X-Deploy-Agent-Key')
            ?: $request->bearerToken()
            ?: $request->input('key')
            ?: ''
        );

        if (! $this->authService->validateAgentKey($key)) {
            return response()->json(['success' => false, 'message' => 'Unauthorized.'], 401);
        }

        $channel = (string) $request->input('channel', 'laravel');
        $level   = $request->filled('level') ? (string) $request->input('level') : null;
        $lines   = max(1, min(AgentLogReaderService::MAX_LINES, (int) $request->input('lines', AgentLogReaderService::DEFAULT_LINES)));
        $grep    = $request->filled('grep') ? (string) $request->input('grep') : null;
        $since   = $request->filled('since') ? (string) $request->input('since') : null;
        $format  = strtolower((string) $request->input('format', 'json'));

        $wantsStream = $format === 'stream' || ($request->hasHeader('Accept') && str_contains((string) $request->header('Accept'), 'text/event-stream'));

        if ($wantsStream) {
            return response()->stream(function () use ($channel, $level, $grep) {
                @set_time_limit(0);
                while (ob_get_level() > 0) {
                    @ob_end_clean();
                }
                ob_implicit_flush(true);

                $send = fn ($p) => print('data: ' . json_encode($p, JSON_UNESCAPED_UNICODE) . "\n\n");
                $send(['type' => 'start', 'channel' => $channel, 'message' => "Live tail initiated for [{$channel}]..."]);
                $this->logReader->tailStream($channel, fn ($e) => $send(['type' => 'log', 'data' => $e]), 120, $level, $grep);
                $send(['type' => 'end', 'message' => 'Stream closed.']);
            }, 200, [
                'Content-Type'      => 'text/event-stream',
                'Cache-Control'     => 'no-cache, no-transform',
                'Connection'        => 'keep-alive',
                'X-Accel-Buffering' => 'no',
            ]);
        }

        $result = $this->logReader->read($channel, $level, $lines, $grep, $since);

        return response()->json([
            'success' => true,
            'channel' => $result['channel'],
            'count'   => $result['count'],
            'filters' => ['level' => $level ?? 'all', 'lines' => $lines, 'grep' => $grep, 'since' => $since],
            'logs'    => $result['logs'],
        ]);
    }
}
