<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Agent Deployment Console</title>
    <style>
        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, monospace;
        }
        body {
            background-color: #0d1117;
            color: #c9d1d9;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            padding: 20px;
        }
        .card {
            background: #161b22;
            border: 1px solid #30363d;
            border-radius: 12px;
            width: 100%;
            max-width: 800px;
            padding: 24px;
            box-shadow: 0 8px 24px rgba(0,0,0,0.5);
        }
        .header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 20px;
            padding-bottom: 15px;
            border-bottom: 1px solid #21262d;
        }
        .header h1 {
            font-size: 1.25rem;
            color: #58a6ff;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        .status-badge {
            font-size: 0.8rem;
            padding: 4px 10px;
            border-radius: 20px;
            background: #21262d;
            color: #8b949e;
        }
        .form-grid {
            display: grid;
            grid-template-columns: 1fr 1fr auto;
            gap: 12px;
            margin-bottom: 20px;
        }
        @media (max-width: 640px) {
            .form-grid {
                grid-template-columns: 1fr;
            }
        }
        .input-group label {
            display: block;
            font-size: 0.75rem;
            text-transform: uppercase;
            letter-spacing: 0.05em;
            color: #8b949e;
            margin-bottom: 6px;
        }
        .input-group input {
            width: 100%;
            background: #0d1117;
            border: 1px solid #30363d;
            border-radius: 6px;
            color: #f0f6fc;
            padding: 10px 12px;
            font-size: 0.9rem;
            outline: none;
            transition: border-color 0.2s;
        }
        .input-group input:focus {
            border-color: #58a6ff;
        }
        .btn-deploy {
            align-self: flex-end;
            background: #238636;
            color: #fff;
            border: none;
            border-radius: 6px;
            padding: 10px 20px;
            font-size: 0.9rem;
            font-weight: 600;
            cursor: pointer;
            transition: background 0.2s, opacity 0.2s;
            height: 42px;
        }
        .btn-deploy:hover {
            background: #2ea043;
        }
        .btn-deploy:disabled {
            background: #21262d;
            color: #8b949e;
            cursor: not-allowed;
        }
        .terminal {
            background: #010409;
            border: 1px solid #30363d;
            border-radius: 8px;
            padding: 16px;
            font-family: ui-monospace, SFMono-Regular, "SF Mono", Menlo, Consolas, monospace;
            font-size: 0.85rem;
            line-height: 1.5;
            color: #7ee787;
            height: 380px;
            overflow-y: auto;
            white-space: pre-wrap;
            word-break: break-all;
        }
        .log-line {
            margin-bottom: 4px;
        }
        .log-error {
            color: #f85149;
        }
        .log-warn {
            color: #d29922;
        }
        .log-info {
            color: #58a6ff;
        }
    </style>
</head>
<body>
<div class="card">
    <div class="header">
        <h1>🤖 Autonomous Deploy Console</h1>
        <span id="statusBadge" class="status-badge">Idle</span>
    </div>

    <form id="deployForm" onsubmit="triggerDeploy(event)" class="form-grid">
        <div class="input-group">
            <label for="branchInput">Target Branch</label>
            <input type="text" id="branchInput" value="main" required />
        </div>
        <div class="input-group">
            <label for="keyInput">Deploy Secret Key</label>
            <input type="password" id="keyInput" placeholder="Enter DEPLOY_SECRET" required />
        </div>
        <button type="submit" id="deployBtn" class="btn-deploy">Deploy</button>
    </form>

    <div id="terminal" class="terminal">
        <div class="log-line log-info">System ready. Awaiting trigger...</div>
    </div>
</div>

<script>
    // URL Secret Scrubbing: scrub key immediately from URL address bar
    (function scrubSecretFromUrl() {
        const urlParams = new URLSearchParams(window.location.search);
        if (urlParams.has('key')) {
            document.getElementById('keyInput').value = urlParams.get('key');
            urlParams.delete('key');
            const newRelativePathQuery = window.location.pathname + (urlParams.toString() ? '?' + urlParams.toString() : '');
            window.history.replaceState({}, document.title, newRelativePathQuery);
        }
        if (urlParams.has('branch')) {
            document.getElementById('branchInput').value = urlParams.get('branch');
        }
    })();

    function log(text, className = '') {
        const terminal = document.getElementById('terminal');
        const line = document.createElement('div');
        line.className = 'log-line ' + className;
        line.textContent = text;
        terminal.appendChild(line);
        terminal.scrollTop = terminal.scrollHeight;
    }

    async function triggerDeploy(e) {
        e.preventDefault();
        const branch = document.getElementById('branchInput').value.trim();
        const key = document.getElementById('keyInput').value.trim();
        const deployBtn = document.getElementById('deployBtn');
        const statusBadge = document.getElementById('statusBadge');
        const terminal = document.getElementById('terminal');

        if (!branch || !key) return;

        terminal.innerHTML = '';
        log(`Initiating live SSE deployment for branch: [${branch}]...`, 'log-info');
        deployBtn.disabled = true;
        statusBadge.textContent = 'Deploying...';
        statusBadge.style.color = '#e3b341';

        try {
            const response = await fetch('{{ url('/deploy/agent') }}', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'text/event-stream',
                    'X-Deploy-Agent-Key': key
                },
                body: JSON.stringify({ branch: branch })
            });

            if (!response.ok) {
                const errorJson = await response.json().catch(() => null);
                const errMsg = errorJson?.message || `HTTP error ${response.status} ${response.statusText}`;
                log(`❌ ${errMsg}`, 'log-error');
                statusBadge.textContent = 'Failed';
                statusBadge.style.color = '#f85149';
                deployBtn.disabled = false;
                return;
            }

            const reader = response.body.getReader();
            const decoder = new TextDecoder('utf-8');
            let buffer = '';

            while (true) {
                const { done, value } = await reader.read();
                if (done) break;

                buffer += decoder.decode(value, { stream: true });
                const parts = buffer.split('\n\n');
                buffer = parts.pop();

                for (const part of parts) {
                    const line = part.trim();
                    if (line.startsWith('data: ')) {
                        try {
                            const data = JSON.parse(line.substring(6));
                            if (data.type === 'log') {
                                log(data.line);
                            } else if (data.type === 'start') {
                                log(data.message, 'log-info');
                            } else if (data.type === 'done') {
                                log(data.message, 'log-info');
                                statusBadge.textContent = 'Complete';
                                statusBadge.style.color = '#7ee787';
                            }
                        } catch (err) {
                            log(line);
                        }
                    }
                }
            }
        } catch (err) {
            log(`❌ Connection error: ${err.message}`, 'log-error');
            statusBadge.textContent = 'Error';
            statusBadge.style.color = '#f85149';
        } finally {
            deployBtn.disabled = false;
        }
    }
</script>
</body>
</html>
