#!/usr/bin/env bash
# OpenClaw post-stow setup
# Run after: cd ~/dotfiles && make stow

set -euo pipefail

OPENCLAW_DIR="$HOME/.openclaw"
PHONE_NUMBER="${1:-}"

if [ -z "$PHONE_NUMBER" ]; then
  echo "Usage: $0 +31XXXXXXXXX"
  echo "This will configure OpenClaw with your phone number"
  exit 1
fi

echo "🦞 Setting up OpenClaw..."

# 1. Create openclaw.json from template
if [ ! -f "$OPENCLAW_DIR/openclaw.json" ]; then
  echo "Creating openclaw.json from template..."
  cp "$OPENCLAW_DIR/openclaw.json.template" "$OPENCLAW_DIR/openclaw.json"

  # Generate gateway token
  GATEWAY_TOKEN=$(openssl rand -hex 24)

  # Replace placeholders
  sed -i '' "s/PHONE_NUMBER_PLACEHOLDER/$PHONE_NUMBER/g" "$OPENCLAW_DIR/openclaw.json"
  sed -i '' "s/GATEWAY_TOKEN_PLACEHOLDER/$GATEWAY_TOKEN/g" "$OPENCLAW_DIR/openclaw.json"

  echo "✓ openclaw.json created"
  echo "  Phone: $PHONE_NUMBER"
  echo "  Gateway token: $GATEWAY_TOKEN"
else
  echo "✓ openclaw.json already exists, skipping"
fi

# 2. Setup auth profiles
AGENT_DIR="$OPENCLAW_DIR/agents/main/agent"
mkdir -p "$AGENT_DIR"

if [ ! -f "$AGENT_DIR/auth-profiles.json" ]; then
  echo "Creating auth-profiles.json..."
  cat > "$AGENT_DIR/auth-profiles.json" <<'EOF'
{
  "version": 1,
  "profiles": {
    "lmstudio:default": {
      "type": "token",
      "provider": "lmstudio",
      "token": "lm-studio"
    }
  },
  "lastGood": {
    "lmstudio": "lmstudio:default"
  },
  "usageStats": {}
}
EOF
  echo "✓ auth-profiles.json created (LM Studio only)"
else
  echo "✓ auth-profiles.json already exists"
fi

# 3. Setup models.json
if [ ! -f "$AGENT_DIR/models.json" ]; then
  echo "Creating models.json..."
  cat > "$AGENT_DIR/models.json" <<'EOF'
{
  "providers": {
    "lmstudio": {
      "baseUrl": "http://127.0.0.1:1234/v1",
      "apiKey": "lm-studio",
      "api": "openai-completions",
      "models": [
        {
          "id": "mistralai/devstral-small-2-2512",
          "name": "Devstral Small",
          "reasoning": false,
          "input": ["text"],
          "cost": { "input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0 },
          "contextWindow": 32768,
          "maxTokens": 8192
        }
      ]
    }
  }
}
EOF
  echo "✓ models.json created"
fi

# 4. Install/reload gateway service from current OpenClaw CLI
echo "Installing OpenClaw gateway service..."
openclaw gateway install --force >/dev/null 2>&1 || true
openclaw gateway restart >/dev/null 2>&1 || true
echo "✓ Gateway service installed/restarted"

echo ""
echo "✅ OpenClaw setup complete!"
echo ""
echo "Next steps:"
echo "  1. Verify LM Studio is running: curl http://127.0.0.1:1234/v1/models"
echo "  2. Check status: openclaw doctor"
echo "  3. Test agent: openclaw agent --message 'Hello!' --to '$PHONE_NUMBER'"
echo "  4. Optional: Add Anthropic key with 'openclaw models auth add'"
