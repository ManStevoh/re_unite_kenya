# AGENTS.md — Autonomous Agent Guidelines

## 🔴 MANDATORY DEPLOYMENT RULE
**BEFORE TRIGGERING ANY SERVER DEPLOYMENT, YOU MUST ALWAYS ASK AND CONFIRM WITH THE DEVELOPER WHICH BRANCH TO USE.**
Under no circumstances should an agent trigger a deployment unilaterally.

### Standard 4-Step Protocol:

1. **Build Client Assets** (if frontend changes exist):
   ```bash
   npm run build
   ```

2. **Commit & Push to GitHub**:
   ```bash
   git add -A && git commit -m "feat/fix: descriptive summary" && git push origin <branch>
   ```

3. **Ask Developer for Confirmation**:
   > "I have compiled the build assets and pushed to GitHub. Which branch should I deploy to the server? (e.g. main or <feature-branch>)"

4. **Trigger Live SSE Deployment** (Only after confirmation):
   ```bash
   DEPLOY_KEY=$(grep -E '^DEPLOY_SECRET=' .env | cut -d '=' -f2-)
   REMOTE_URL=$(grep -E '^DEPLOY_REMOTE_URL=' .env | cut -d '=' -f2-)
   curl -N -s -X POST "${REMOTE_URL}/deploy/agent" \
     -H "X-Deploy-Agent-Key: ${DEPLOY_KEY}" \
     -H "Content-Type: application/json" \
     -H "Accept: text/event-stream" \
     -d "{\"branch\": \"${CONFIRMED_BRANCH}\"}"
   ```
