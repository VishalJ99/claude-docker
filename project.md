# Claude Docker Container Startup Logic

## Overview
The `claude-docker.sh` script provides a comprehensive wrapper for running Claude Code in a Docker container with project mounting, authentication setup, and environment customization.

## Core Components

### 1. Command Line Arguments
- `--no-cache`: Skip Docker build cache
- `--rebuild`: Force image rebuild
- `--continue`: Pass continue flag to Claude
- `--memory <size>`: Set container memory limit (e.g., 8g, 2048m)
- `--gpus <spec>`: Enable GPU access (e.g., all, 0,1, device=0)

### 2. Environment Configuration
The script sources `.env` file from project root and supports:
- `DOCKER_MEMORY_LIMIT`: Default memory allocation
- `DOCKER_GPU_ACCESS`: Default GPU configuration
- `CONDA_PREFIX`: Conda installation path
- `CONDA_EXTRA_DIRS`: Additional conda directories
- `SYSTEM_PACKAGES`: Extra system packages for build
- Twilio credentials for MCP features

### 3. Project Setup
- Creates `.claude` directory in current project
- Copies global Claude configuration
- Sets up persistent authentication and SSH keys
- Mounts project directory as `/workspace`

### 4. Resource Management
**Memory**: Configurable RAM limits using Docker `--memory` flag
**GPU**: NVIDIA GPU access with runtime detection and validation
**Storage**: Persistent Claude home directory at `~/.claude-docker/`

### 5. Container Execution
```bash
docker run -it --rm \
    $DOCKER_OPTS \           # Memory/GPU flags
    -v "$CURRENT_DIR:/workspace" \
    -v "$HOME/.claude-docker/claude-home:/home/claude-user/.claude:rw" \
    -v "$HOME/.claude-docker/ssh:/home/claude-user/.ssh:rw" \
    $MOUNT_ARGS \            # Conda mounts
    $ENV_ARGS \              # Environment variables
    --workdir /workspace \
    claude-docker:latest
```

## Usage Examples

### Basic Usage
```bash
./scripts/claude-docker.sh
```

### With Custom Memory
```bash
./scripts/claude-docker.sh --memory 16g
```

### With GPU Access
```bash
./scripts/claude-docker.sh --gpus all
```

### Combined Options
```bash
./scripts/claude-docker.sh --memory 8g --gpus 0,1 --continue
```

### Environment Configuration
```bash
# In .env file
DOCKER_MEMORY_LIMIT=12g
DOCKER_GPU_ACCESS=all
```

## GPU Requirements
- NVIDIA Docker runtime (nvidia-docker2 or nvidia-container-runtime)
- Compatible NVIDIA drivers
- Script validates GPU runtime availability before enabling

## Conda Integration
- Mounts existing conda installations read-only
- Preserves environment paths and package directories
- Supports multiple conda directory mounting via `CONDA_EXTRA_DIRS`
