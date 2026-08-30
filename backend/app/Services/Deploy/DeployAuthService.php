<?php

namespace App\Services\Deploy;

class DeployAuthService
{
    public function validateAgentKey(?string $key): bool
    {
        if (empty($key)) {
            return false;
        }

        $configuredKey = (string) (config('app.deploy_secret') ?? env('DEPLOY_SECRET', ''));
        $agentKey = (string) (config('app.deploy_agent_key') ?? env('DEPLOY_AGENT_KEY', $configuredKey));

        if ($configuredKey === '' && $agentKey === '') {
            return false;
        }

        return ($configuredKey !== '' && hash_equals($configuredKey, $key))
            || ($agentKey !== '' && hash_equals($agentKey, $key));
    }
}
