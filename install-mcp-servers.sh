#!/usr/bin/env bash
set -euo pipefail
trap 'echo "$0: line $LINENO: $BASH_COMMAND: exitcode $?"' ERR

# ABOUTME: Installs MCP servers from mcp-servers.txt with environment variable substitution

echo "Installing MCP servers..."

# Source .env file if it exists
if [ -f /app/.env ]; then
    set -a
    source /app/.env
    set +a
    echo "Loaded environment variables from .env"
fi

if [ ! -f /app/mcp-servers.txt ]; then
    echo "No mcp-servers.txt file found, skipping"
    exit 0
fi

command_buffer=""
in_multiline=false

while IFS= read -r line || [[ -n "$line" ]]; do
    # Skip empty lines and comments (but only when not in multi-line mode)
    if ! $in_multiline && ([[ -z "$line" ]] || [[ "$line" =~ ^[[:space:]]*# ]]); then
        continue
    fi

    # Detect start of multi-line command (contains '{ without closing '}')
    if [[ "$line" =~ \'?\{[^}]*$ ]] && [[ "$line" =~ ^claude ]]; then
        in_multiline=true
        command_buffer="$line"
        continue
    fi

    # Accumulate multi-line command
    if $in_multiline; then
        command_buffer="$command_buffer"$'\n'"$line"
        # Check if we've reached the end (line contains }' )
        if [[ "$line" =~ \}\'[[:space:]]*$ ]]; then
            in_multiline=false
            line="$command_buffer"
            command_buffer=""
        else
            continue
        fi
    fi

    # 1. Check for missing variables
    var_names=$(echo "$line" | grep -o '\${[^}]*}' | sed 's/[${}]//g' || echo "")

    missing_vars=""
    for var in $var_names; do
        if [ -z "${!var:-}" ]; then
            missing_vars="$missing_vars $var"
        fi
    done

    if [ -n "$missing_vars" ]; then
        echo "⚠ Skipping MCP server - missing environment variables:$missing_vars"
        continue
    fi

    # 2. Expansion Logic
    if [[ -n "$var_names" ]]; then
        if [[ "$line" =~ "add-json" ]]; then
            expanded_line="$line"
            vars_in_line=$(echo "$line" | grep -o '\${[^}]*}' | sed 's/[${}]//g' | sort -u || echo "")
            for var in $vars_in_line; do
                if [ -n "${!var:-}" ]; then
                    value="${!var}"
                    expanded_line=$(echo "$expanded_line" | sed "s|\${$var}|$value|g")
                fi
            done
        else
            if command -v envsubst >/dev/null 2>&1; then
                expanded_line=$(echo "$line" | envsubst)
            else
                echo "Error: envsubst not found. Please install gettext-base."
                exit 1
            fi
        fi
    else
        expanded_line="$line"
    fi

    echo "Executing: $(echo "$expanded_line" | head -c 100)..."

    if eval "$expanded_line"; then
        echo "✓ Successfully installed MCP server"
    else
        echo "✗ Failed to install MCP server (continuing)"
    fi

    echo "---"
done < /app/mcp-servers.txt

echo "MCP server installation complete"
