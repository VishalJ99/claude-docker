#!/usr/bin/env bash
set -euo pipefail
trap 'echo "$0: line $LINENO: $BASH_COMMAND: exitcode $?"' ERR

# ABOUTME: Startup script for claude-docker container with MCP server
# ABOUTME: Loads twilio env vars, checks for .credentials.json, copies CLAUDE.md template if no claude.md in claude-docker/claude-home.
# ABOUTME: Starts claude code with permissions bypass and continues from last session.
# NOTE: Need to call claude-docker --rebuild to integrate changes.

# Load environment variables from .env if it exists
# Use the .env file baked into the image at build time
if [ -f /app/.env ]; then
    echo "Loading environment from baked-in .env file"
    set -a
    source /app/.env 2>/dev/null || true
    set +a
    
    # Export Twilio variables for runtime use
    export TWILIO_ACCOUNT_SID
    export TWILIO_AUTH_TOKEN
    export TWILIO_FROM_NUMBER
    export TWILIO_TO_NUMBER
else
    echo "WARNING: No .env file found in image."
fi

# Check for existing authentication
if [ -f "$HOME/.claude/.credentials.json" ]; then
    echo "Found existing Claude authentication"
else
    echo "No existing authentication found - you will need to log in"
    echo "Your login will be saved for future sessions"
fi

# Handle CLAUDE.md template
if [ ! -f "$HOME/.claude/CLAUDE.md" ]; then
    echo "✓ No CLAUDE.md found at $HOME/.claude/CLAUDE.md - copying template"
    # Copy from the template that was baked into the image
    if [ -f "/app/.claude/CLAUDE.md" ]; then
        cp "/app/.claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
    elif [ -f "/home/claude-user/.claude.template/CLAUDE.md" ]; then
        # Fallback for existing images
        cp "/home/claude-user/.claude.template/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
    fi
    echo "  Template copied to: $HOME/.claude/CLAUDE.md"
else
    echo "✓ Using existing CLAUDE.md from $HOME/.claude/CLAUDE.md"
    echo "  This maps to your host persistent claude-home/CLAUDE.md"
    echo "  Default host path: ~/.claude-docker/claude-home/CLAUDE.md"
    echo "  To reset to template, delete this file and restart"
fi

# Verify Twilio MCP configuration
if [ -n "$TWILIO_ACCOUNT_SID" ] && [ -n "$TWILIO_AUTH_TOKEN" ]; then
    echo "✓ Twilio MCP server configured - SMS notifications enabled"
else
    echo "No Twilio credentials found - SMS notifications disabled"
fi

# # Export environment variables from settings.json
# # This is a workaround for Docker container not properly exposing these to Claude
# if [ -f "$HOME/.claude/settings.json" ] && command -v jq >/dev/null 2>&1; then
#     echo "Loading environment variables from settings.json..."
#     # First remove comments from JSON, then extract env vars
#     # Using sed to remove // comments before parsing with jq
#     while IFS='=' read -r key value; do
#         if [ -n "$key" ] && [ -n "$value" ]; then
#             export "$key=$value"
#             echo "  Exported: $key=$value"
#         fi
#     done < <(sed 's://.*$::g' "$HOME/.claude/settings.json" | jq -r '.env // {} | to_entries | .[] | "\(.key)=\(.value)"' 2>/dev/null)
# fi

# Start Claude Code with permissions bypass
echo "Starting Claude Code..."
exec claude $CLAUDE_CONTINUE_FLAG --dangerously-skip-permissions "$@"
