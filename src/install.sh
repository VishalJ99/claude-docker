#!/usr/bin/env bash
set -euo pipefail
trap 'echo "$0: line $LINENO: $BASH_COMMAND: exitcode $?"' ERR
# ABOUTME: Installation script for claude-docker
# ABOUTME: Creates claude-docker/claude-home directory at home, copies .env.example to .env,
# ABOUTME: adds claude-docker alias to .zshrc.

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Create claude persistence directory
mkdir -p "$HOME/.claude-docker/claude-home"

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

# Make scripts executable
chmod +x "$PROJECT_ROOT/src/claude-docker.sh"
chmod +x "$PROJECT_ROOT/src/startup.sh"

# Check for GPU support
echo ""
echo "Checking GPU support..."

# Check if running with admin privileges
if [ "$EUID" -eq 0 ]; then
    echo "✓ Running with admin privileges"
    
    # Check if NVIDIA drivers are installed
    if command -v nvidia-smi &> /dev/null; then
        echo "✓ NVIDIA drivers detected"
        
        # Check if Docker has GPU support
        if docker info 2>/dev/null | grep -q nvidia; then
            echo "✓ Docker GPU support already installed"
        else
            echo "⚠️  Docker GPU support not found"
            echo "Installing NVIDIA Container Toolkit..."
            
            # Install without sudo (we're already root)
            distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
            curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | \
                gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
            curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
                sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
                tee /etc/apt/sources.list.d/nvidia-container-toolkit.list > /dev/null
            apt-get update -qq
            apt-get install -y -qq nvidia-container-toolkit
            nvidia-ctk runtime configure --runtime=docker > /dev/null
            systemctl restart docker
            echo "✓ NVIDIA Container Toolkit installed"
        fi
    else
        echo "ℹ️  No NVIDIA GPU detected - skipping GPU support"
    fi
else
    echo "ℹ️  Not running as root - skipping GPU installation"
    echo "   To install GPU support, run: sudo $0"
    
    # Still check status for informational purposes
    if command -v nvidia-smi &> /dev/null; then
        if docker info 2>/dev/null | grep -q nvidia; then
            echo "   ✓ GPU support appears to be already installed"
        else
            echo "   ⚠️  GPU detected but Docker GPU support not installed"
        fi
    fi
fi

echo ""
echo "Installation complete! 🎉"
echo ""
echo "Next steps:"
echo "1. (Optional) Edit $PROJECT_ROOT/.env with your API keys"
echo "2. Run 'source ~/.zshrc' or start a new terminal"
echo "3. Navigate to any project and run 'claude-docker' to start"
echo "4. If no API key, Claude will prompt for interactive authentication"
