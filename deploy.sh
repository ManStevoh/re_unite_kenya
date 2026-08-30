#!/usr/bin/env bash
set -euo pipefail

# 1. Target Directory & Target Branch
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="${APP_DIR:-$SCRIPT_DIR}"

# If artisan is located in backend/ subfolder, adjust APP_DIR
if [ ! -f "$APP_DIR/artisan" ] && [ -f "$APP_DIR/backend/artisan" ]; then
    APP_DIR="$APP_DIR/backend"
fi

BRANCH="${1:-main}"

echo "⚡ Running deploy pipeline: $(realpath "$0")"
echo "🚀 1. Deploying branch [${BRANCH}] from GitHub..."
cd "$APP_DIR"

# 2. Fetch and Reset to Remote Branch
git fetch origin "${BRANCH}"
git reset --hard "origin/${BRANCH}"

# 3. Database Migrations & Storage Link
echo "🗄️ 2. Checking database migrations..."
if [ -f artisan ]; then
    php artisan migrate --force || true
    php artisan storage:link || true
fi

# 4. Framework Optimization & Cache Warming
echo "⚡ 3. Compiling production caches..."
if [ -f artisan ]; then
    php artisan optimize:clear
    php artisan config:cache
    php artisan route:cache
    php artisan view:cache
    php artisan event:cache || true
fi

# 5. Prevent Stale Process Accumulation (Queue worker restart)
echo "🔄 4. Restarting queue workers..."
if [ -f artisan ]; then
    php artisan queue:restart || true
fi

echo "✅ Production updated, migrated & optimized successfully to [${BRANCH}]!"
