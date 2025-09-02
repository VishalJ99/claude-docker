#!/usr/bin/env bash
set -euo pipefail
trap 'echo "$0: line $LINENO: $BASH_COMMAND: exitcode $?"' ERR
# ABOUTME: Installation script for claude-docker
# ABOUTME: Creates claude-docker/claude-home directory at home, copies .env.example to .env,
# ABOUTME: adds claude-docker alias to .zshrc, makes scripts executable.

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Create claude persistence directory
mkdir -p "$HOME/.claude-docker/claude-home"

# Create scripts directory
mkdir -p "$HOME/.claude-docker/scripts"

# Copy template scripts
echo "✓ Copying template scripts to persistent directory"
cp -r "$PROJECT_ROOT/scripts/"* "$HOME/.claude-docker/scripts/"

# Copy template .claude contents to persistent directory
echo "✓ Copying template Claude configuration to persistent directory"
cp -r "$PROJECT_ROOT/.claude/"* "$HOME/.claude-docker/claude-home/"

# Copy example env file if doesn't exist
if [ ! -f "$PROJECT_ROOT/.env" ]; then
    cp "$PROJECT_ROOT/.env.example" "$PROJECT_ROOT/.env"
    echo "⚠️  Created .env file at $PROJECT_ROOT/.env"
    echo "   Please edit it with your API keys!"
fi

# Add alias to .zshrc
ALIAS_LINE="alias claude-docker='$PROJECT_ROOT/src/claude-docker.sh'"

if ! grep -q "alias claude-docker=" "$HOME/.zshrc"; then
    echo "" >> "$HOME/.zshrc"
    echo "# Claude Docker alias" >> "$HOME/.zshrc"
    echo "$ALIAS_LINE" >> "$HOME/.zshrc"
    echo "✓ Added 'claude-docker' alias to .zshrc"
else
    echo "✓ Claude-docker alias already exists in .zshrc"
fi

# Add scripts directory to PATH and PYTHONPATH in .bashrc
if grep -q "/.claude-docker/scripts" "$HOME/.bashrc"; then
    echo "✓ Scripts directory already in .bashrc PATH/PYTHONPATH"
else
    echo "" >> "$HOME/.bashrc"
    echo "# Claude Docker scripts directory" >> "$HOME/.bashrc"
    echo "export PATH=\"\$HOME/.claude-docker/scripts:\$PATH\"" >> "$HOME/.bashrc"
    echo "export PYTHONPATH=\"\$HOME/.claude-docker/scripts:\$PYTHONPATH\"" >> "$HOME/.bashrc"
    echo "✓ Added scripts directory to .bashrc PATH/PYTHONPATH"
fi

# Add scripts directory to PATH and PYTHONPATH in .zshrc
if grep -q "/.claude-docker/scripts" "$HOME/.zshrc"; then
    echo "✓ Scripts directory already in .zshrc PATH/PYTHONPATH"
else
    echo "" >> "$HOME/.zshrc"
    echo "# Claude Docker scripts directory" >> "$HOME/.zshrc"
    echo "export PATH=\"\$HOME/.claude-docker/scripts:\$PATH\"" >> "$HOME/.zshrc"
    echo "export PYTHONPATH=\"\$HOME/.claude-docker/scripts:\$PYTHONPATH\"" >> "$HOME/.zshrc"
    echo "✓ Added scripts directory to .zshrc PATH/PYTHONPATH"
fi

# Make scripts executable
chmod +x "$PROJECT_ROOT/src/claude-docker.sh"
chmod +x "$PROJECT_ROOT/src/startup.sh"

echo ""
echo "Installation complete! 🎉"
echo ""
echo "Next steps:"
echo "1. (Optional) Edit $PROJECT_ROOT/.env with your API keys"
echo "2. Run 'source ~/.zshrc' or start a new terminal"
echo "3. Navigate to any project and run 'claude-docker' to start"
echo "4. If no API key, Claude will prompt for interactive authentication"
