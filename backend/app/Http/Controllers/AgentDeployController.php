<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\StreamedResponse;

class AgentDeployController extends Controller
{
    public function deploy(Request $request)
    {
        // 1. Authenticate Request (Timing-Safe Comparison)
        $configuredKey = (string) (config('app.deploy_secret') ?? env('DEPLOY_SECRET', ''));
        $agentKey = (string) (config('app.deploy_agent_key') ?? env('DEPLOY_AGENT_KEY', $configuredKey));

        $providedKey = (string) ($request->header('X-Deploy-Agent-Key')
            ?? $request->input('key')
            ?? $request->bearerToken()
            ?? '');

        if ($configuredKey === '' || $providedKey === '' || (!hash_equals($configuredKey, $providedKey) && !hash_equals($agentKey, $providedKey))) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized: Invalid or missing deployment key.',
            ], 401);
        }

        // 2. Validate & Sanitize Target Branch
        $branch = (string) ($request->input('branch') ?? 'main');
        if (!preg_match('/^[a-zA-Z0-9_\-\/\.]+$/', $branch)) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid branch name format.',
            ], 422);
        }

        // 3. Concurrency Lock Handling (Auto-expire after 10 mins)
        $lockFile = storage_path('framework/deploy.lock');
        if (file_exists($lockFile)) {
            if (time() - filemtime($lockFile) < 600) {
                return response()->json([
                    'success' => false,
                    'message' => 'Conflict: A deployment is currently in progress.',
                ], 409);
            }
            @unlink($lockFile);
        }
        @file_put_contents($lockFile, (string) time());

        // 4. Stream Deployment Progress via Server-Sent Events (SSE)
        return new StreamedResponse(function () use ($branch, $lockFile) {
            $startTime = microtime(true);

            // Disable output buffering for live streaming
            while (ob_get_level() > 0) {
                ob_end_clean();
            }

            $sendEvent = function ($type, $data) {
                echo "data: " . json_encode(array_merge(['type' => $type], $data)) . "\n\n";
                if (ob_get_level()) {
                    ob_flush();
                }
                flush();
            };

            $sendEvent('start', [
                'branch' => $branch,
                'message' => "🤖 [Agent Mode] Live deployment stream initiated for [{$branch}]...",
            ]);

            // Execute the host deploy script
            $defaultScript = base_path('deploy.sh');
            if (!file_exists($defaultScript) && file_exists(base_path('../deploy.sh'))) {
                $defaultScript = base_path('../deploy.sh');
            }

            $deployScript = env('DEPLOY_SCRIPT_PATH', $defaultScript);
            $escapedBranch = escapeshellarg($branch);

            if (!file_exists($deployScript)) {
                $sendEvent('log', ['line' => "⚠️ Warning: Deploy script not found at {$deployScript}."]);
            }

            if (is_executable($deployScript)) {
                $cmd = "{$deployScript} {$escapedBranch} 2>&1";
            } else {
                $cmd = "bash {$deployScript} {$escapedBranch} 2>&1";
            }

            $sendEvent('log', ['line' => "⚡ Executing: {$cmd}"]);

            $process = popen($cmd, 'r');
            if ($process) {
                while (!feof($process)) {
                    $line = fgets($process);
                    if ($line !== false && trim($line) !== '') {
                        $sendEvent('log', ['line' => rtrim($line)]);
                    }
                }
                pclose($process);
            } else {
                $sendEvent('log', ['line' => "❌ Error: Failed to start deploy process command."]);
            }

            @unlink($lockFile);
            $duration = round(microtime(true) - $startTime, 2);
            $sendEvent('log', ['line' => "✅ [SUCCESS] Deployment completed in {$duration}s!"]);
            $sendEvent('done', [
                'success' => true,
                'status' => 'complete',
                'duration' => $duration,
                'message' => 'Agent deployment completed successfully.',
            ]);
        }, 200, [
            'Content-Type' => 'text/event-stream',
            'Cache-Control' => 'no-cache, no-transform',
            'Connection' => 'keep-alive',
            'X-Accel-Buffering' => 'no', // For Nginx / LiteSpeed reverse proxy flush
        ]);
    }

    public function webConsole(Request $request)
    {
        return view('deploy.console');
    }
}
