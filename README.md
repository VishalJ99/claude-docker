# Claude Docker

A complete AI coding agent starter pack with Claude Code, pre-configured with essential MCP servers for a powerful autonomous development experience.

📋 **MCP Setup Guide**: See [MCP_SERVERS.md](MCP_SERVERS.md) for customizing or adding more MCP servers

## 🚀 AI Coding Agent Starter Pack

This is a complete starter pack for autonomous AI development. 

## What This Does
- **Complete AI coding agent setup** with Claude Code in an isolated Docker container
- **Pre-configured MCP servers** for maximum coding productivity:
  - **Serena** - Advanced coding agent toolkit with project indexing and symbol manipulation
  - **Context7** - Pulls up-to-date, version-specific documentation and code examples straight from the source into your prompt
  - **Twilio** - SMS notifications when long-running tasks complete (perfect for >10min jobs)
- **Persistent conversation history** - Resumes from where you left off, even after crashes
- **Remote work notifications** - Get pinged via SMS when tasks finish, so you can step away from your monitor
- **Simple one-command setup and usage** - Zero friction set up for plug and play integration with existing cc workflows.
- **Fully customizable** - Modify the can modify the files at `~/.claude-docker` for custom slash commands, settings and claude.md files.

## Quick Start
```bash
# 0. Assumes you claude-code and docker already installed.

# 1. Clone and enter directory
git clone https://github.com/VishalJ99/claude-docker.git
cd claude-docker

# 2. Setup environment
cp .env.example .env
nano .env  # Add your API keys (see below)

# 3. Install
./src/install.sh

# 4. Run from any project
cd ~/your-project
claude-docker

# Optional: use `claude-docker --podman` or `DOCKER=podman claude-docker`
# to use podman instead of docker.
#
# Optional: Set up SSH keys for git push (see Prerequisites section)
# The script will show setup instructions if keys are missing
```
## Command Line Flags

Claude Docker supports several command-line flags for different use cases:

### Basic Usage
```bash
claude-docker                    # Start Claude in current directory
claude-docker --podman           # Use podman instead of docker to run containers
claude-docker --continue         # Resume previous conversation in this directory
claude-docker --rebuild          # Force rebuild Docker image
claude-docker --rebuild --no-cache  # Rebuild without using Docker cache
```

### Available Flags

| Flag | Description | Example |
|------|-------------|---------|
| `--podman` | Use podman in place of docker | `claude-docker --podman` |
| `--continue` | Resume the previous conversation in current directory | `claude-docker --continue` |
| `--rebuild` | Force rebuild of the Docker image | `claude-docker --rebuild` |
| `--no-cache` | When rebuilding, don't use Docker cache | `claude-docker --rebuild --no-cache` |
| `--memory` | Set container memory limit | `claude-docker --memory 8g` |
| `--gpus` | Enable GPU access (requires nvidia-docker) | `claude-docker --gpus all` |

### Environment Variables
You can also set defaults in your `.env` file:
```bash
DOCKER_MEMORY_LIMIT=8g          # Default memory limit
DOCKER_GPU_ACCESS=all           # Default GPU access
```

### Examples
```bash
# Resume work with 16GB memory limit
claude-docker --continue --memory 16g

# Rebuild after updating .env file
claude-docker --rebuild

# Use GPU for ML tasks
claude-docker --gpus all
```

## Prerequisites

⚠️ **IMPORTANT**: Complete these steps BEFORE using claude-docker:

### 1. Claude Code Authentication (Required)
You must authenticate Claude Code on your host system first:
```bash
# Install Claude Code globally
npm install -g @anthropic-ai/claude-code

# Run and complete authentication
claude

# Verify authentication files exist
ls ~/.claude.json ~/.claude/
```

📖 **Full Claude Code Setup Guide**: https://docs.anthropic.com/en/docs/claude-code

### 2. Docker Installation (Required)
- **Docker Desktop**: https://docs.docker.com/get-docker/
- Ensure Docker daemon is running before proceeding

### 3. Git Configuration (Required)
Git configuration is automatically loaded from your host system during Docker build:
- Make sure you have configured git on your host system first:
  ```bash
  git config --global user.name "Your Name"
  git config --global user.email "your.email@example.com"
  ```
- **Important**: Claude Docker will commit to your current branch - make sure you're on the correct branch before starting

### 4. SSH Keys for Git Push (Optional - for push/pull operations)
Claude Docker uses dedicated SSH keys (separate from your main SSH keys for security):

**Setup SSH keys:**
```bash
# 1. Create directory for Claude Docker SSH keys
mkdir -p ~/.claude-docker/ssh

# 2. Generate SSH key for Claude Docker
ssh-keygen -t rsa -b 4096 -f ~/.claude-docker/ssh/id_rsa -N ''

# 3. Add public key to GitHub
cat ~/.claude-docker/ssh/id_rsa.pub
# Copy output and add to: GitHub → Settings → SSH and GPG keys → New SSH key

# 4. Test connection
ssh -T git@github.com -i ~/.claude-docker/ssh/id_rsa
```

**Why separate SSH keys?**
- ✅ **Security Isolation**: Claude can't access or modify your personal SSH keys, config, or known_hosts
- ✅ **SSH State Persistence**: The SSH directory is mounted at runtime.
- ✅ **Easy Revocation**: Delete `~/.claude-docker/ssh/` to instantly revoke Claude's git access
- ✅ **Clean Audit Trail**: All Claude SSH activity is isolated and easily traceable

**Technical Note**: We mount the SSH directory rather than copying keys because SSH operations modify several files (`known_hosts`, connection state) that must persist between container sessions for a smooth user experience.

### 5. Twilio Account (Optional - for SMS notifications)
If you want SMS notifications when tasks complete:
- Create free trial account: https://www.twilio.com/docs/usage/tutorials/how-to-use-your-free-trial-account
- Get your Account SID and Auth Token from the Twilio Console
- Get a phone number for sending SMS

### Why Pre-authentication?
The Docker container needs your existing Claude authentication to function. This approach:
- ✅ Uses your existing Claude subscription/API access
- ✅ Maintains secure credential handling
- ✅ Enables persistent authentication across container restarts


### Environment Variables (.env)
```bash
# SMS notifications (highly recommended!)
# Perfect for long-running tasks - step away and get notified when done
TWILIO_ACCOUNT_SID=your_twilio_sid  
TWILIO_AUTH_TOKEN=your_twilio_auth_token
TWILIO_FROM_NUMBER=+1234567890
TWILIO_TO_NUMBER=+0987654321

# Optional - Custom conda paths
CONDA_PREFIX=/path/to/your/conda
CONDA_EXTRA_DIRS="/path/to/envs /path/to/pkgs"

# Optional - System packages
SYSTEM_PACKAGES="libopenslide0 libgdal-dev"
```

⚠️ **Security Note**: Credentials are baked into the Docker image. Keep your image secure!

## Features

### 🤖 Full Autonomy
- Claude runs with `--dangerously-skip-permissions` for complete access
- Can read, write, execute, and modify any files in your project
- No permission prompts or restrictions

### 🔌 Modular MCP Server Support
- Easy installation of any MCP server through `mcp-servers.txt`
- Automatic environment variable handling for MCP servers requiring API keys
- Pre-configured popular servers (Twilio, GitHub, filesystem, browser automation)
- See [MCP_SERVERS.md](MCP_SERVERS.md) for full setup guide

### 📱 SMS Notifications  
- Automatic SMS via Twilio when Claude completes tasks
- Configurable via MCP integration
- Optional - works without if Twilio not configured

### 🐍 Conda Integration
- Has access to your conda envs so do not need to add build instructions to the Dockerfile
- Supports custom conda installation directories (ideal for academic/lab environments where home is quota'd)


### 🔑 Persistence
- Login once, use forever - authentication tokens persist across sessions
- Automatic UID/GID mapping ensures perfect file permissions between host and container
- Loads history from previous chats in a given project.

### 📝 Task Execution Logging  
- Prompt engineered to generate `task_log.md` documenting agent's execution process
- Stores assumptions, insights, and challenges encountered
- Acts as a simple summary to quickly understand what the agent accomplished

### 🛠️ Shared Utility Scripts (`~/.claude-docker/scripts/`)
- **`sys_utils.py`** - Common utilities for reproducibility and git state management
  - `check_git_state_clean()` - Ensures clean git state before script execution
  - `create_reproduce_command()` - Generates reproduction commands with git hash and arguments
- Automatically available for import in Python scripts: `from sys_utils import check_git_state_clean, create_reproduce_command`
- Enforces reproducibility standards and clean execution environments

**Custom Script Development:**
- Place executable scripts in `~/.claude-docker/scripts/` to extend Claude's capabilities
- Add Python modules for shared functionality across projects
- Scripts are accessible as commands in both host terminal and Claude containers
- All modifications persist across container sessions and rebuilds

### 🧠 Enhanced Prompt Engineering (`CLAUDE.md`)
- **Execution Protocols** - Strict guidelines for simplicity, no error handling, surgical edits
- **Python Reproducibility** - Mandatory output directory structure with git hash, timestamp, and reproduction commands
- **Git State Assertion** - Scripts automatically check for clean git state before execution (except test/demo inputs)
- **System Package Installation** - Automatic documentation of apt-get packages in task logs
- **Startup Procedure** - Automatic codebase indexing using Serena MCP for enhanced code understanding

### 🐳 Clean Environment
- Each session runs in fresh Docker container
- Only current working directory mounted (along with conda directories specified in `.env`).


## Configuration
During build, the `.env` file from the claude-docker repository directory is baked into the image:
- Credentials are embedded at `/app/.env` inside the container
- No need to manage .env files in each project
- The image contains everything needed to run
- **Important**: After updating `.env`, you must rebuild the image with `claude-docker --rebuild`

The setup creates `~/.claude-docker/` in your home directory with:
- `claude-home/` - Persistent Claude authentication and settings
- `ssh/` - Directory where claude-dockers private ssh key and known hosts file is stored

The `scripts/` directory is automatically mounted in each container session, making `sys_utils.py` and other shared utilities available across all projects.

### 🛣️ PATH and PYTHONPATH Integration
During installation, the scripts directory is automatically added to both your host system and container environments:

**Host System Setup:**
- `~/.claude-docker/scripts` is added to both `PATH` and `PYTHONPATH` in `.bashrc` and `.zshrc`
- Scripts placed in this directory become available as system commands on your host
- Python modules can be imported directly: `from sys_utils import check_git_state_clean`

**Container Setup:**
- Scripts directory mounted at `/home/claude-user/scripts` with read/write access
- Container `PATH` includes `/home/claude-user/scripts` (Dockerfile:92)
- Container `PYTHONPATH` includes `/home/claude-user/scripts` (Dockerfile:93)
- All custom scripts and Python modules are immediately available to Claude

**What This Means:**
- ✅ **Bidirectional Access**: Scripts work on both host and in Claude containers
- ✅ **No Import Issues**: Python utilities available without path manipulation
- ✅ **Custom Commands**: Add executable scripts to extend Claude's capabilities
- ✅ **Shared Libraries**: Common code shared across all projects automatically
- ✅ **Persistent Utilities**: Scripts survive container restarts and rebuilds

### Template Configuration Copy
During installation (`install.sh`), all contents from the project's `.claude/` directory are copied to `~/.claude-docker/claude-home/` as template/base settings. This includes:
- `settings.json` - Default Claude Code settings with MCP configuration
- `CLAUDE.md` - Default instructions and protocols  
- `commands/` - Slash commands (if any)
- Any other configuration files

**To modify these settings:**
- **Recommended**: Directly edit files in `~/.claude-docker/claude-home/`
- **Alternative**: Modify `.claude/` in this repository and re-run `install.sh`

All changes to `~/.claude-docker/claude-home/` persist across container sessions.

Each project gets:
- `.claude/settings.json` - Claude Code settings with MCP
- `.claude/CLAUDE.md` - Project-specific instructions (if you create one)


### Rebuilding the Image

The Docker image is built only once when you first run `claude-docker`. To force a rebuild:

```bash
# Force rebuild (uses cache)
claude-docker --rebuild

# Force rebuild without cache
claude-docker --rebuild --no-cache
```

Rebuild when you:
- Update your .env file with new credentials
- Update the Claude Docker repository
- Change system packages in .env

### Conda Configuration

For custom conda installations (common in academic/lab environments), add these to your `.env` file:

```bash
# Main conda installation
CONDA_PREFIX=/vol/lab/username/miniconda3

# Additional conda directories (space-separated)
CONDA_EXTRA_DIRS="/vol/lab/username/.conda/envs /vol/lab/username/conda_envs /vol/lab/username/.conda/pkgs /vol/lab/username/conda_pkgs"
```

**How it works:**
- `CONDA_PREFIX`: Mounts your conda installation to the same path in container
- `CONDA_EXTRA_DIRS`: Mounts additional directories and automatically configures conda

**Automatic Detection:**
- Paths containing `*env*` → Added to `CONDA_ENVS_DIRS` (conda environment search)
- Paths containing `*pkg*` → Added to `CONDA_PKGS_DIRS` (package cache search)

**Result:** All your conda environments and packages work exactly as they do on your host system.

### System Package Installation

For scientific computing packages that require system libraries, add them to your `.env` file:

```bash
# Install OpenSlide for medical imaging
SYSTEM_PACKAGES="libopenslide0"

# Install multiple packages (space-separated)
SYSTEM_PACKAGES="libopenslide0 libgdal-dev libproj-dev libopencv-dev"
```

**Note:** Adding system packages requires rebuilding the Docker image (`docker rmi claude-docker:latest`).
## How This Differs from Anthropic's DevContainer

We provide a different approach than [Anthropic's official .devcontainer](https://github.com/anthropics/claude-code/tree/main/.devcontainer), optimized for autonomous task execution:


### Feature Comparison

| Feature | claude-docker | Anthropic's DevContainer |
|---------|--------------|-------------------------|
| **IDE Support** | Any editor/IDE | VSCode-specific |
| **Authentication** | Once per machine, persists forever | Per-devcontainer setup |
| **Conda Environments** | Direct access to all host envs | Manual setup in Dockerfile |
| **Prompt Engineering** | Optimized CLAUDE.md for tasks | Standard behavior |
| **Network Access** | Full access (firewall coming soon) | Configurable firewall |
| **SMS Notifications** | Built-in Twilio MCP | Not available |
| **Permissions** | Auto (--dangerously-skip-permissions) | Auto (--dangerously-skip-permissions) |


**Note**: Network firewall functionality similar to Anthropic's implementation is our next planned feature.

## Next Steps

**Phase 2 - Security Enhancements:**
- Network firewall to whitelist specific domains (similar to Anthropic's DevContainer)
- Shell history persistence between sessions
- Additional security features

## Attribution & Dependencies

### Core Dependencies
- **Claude Code**: Anthropic's official CLI - https://github.com/anthropics/claude-code
- **Twilio MCP Server**: SMS integration by @yiyang.1i - https://github.com/yiyang1i/sms-mcp-server
- **Docker**: Container runtime - https://www.docker.com/

### Inspiration & References
- Anthropic's DevContainer implementation: https://github.com/anthropics/claude-code/tree/main/.devcontainer
- MCP (Model Context Protocol): https://modelcontextprotocol.io/

### Created By
- **Repository**: https://github.com/VishalJ99/claude-docker
- **Author**: Vishal J (@VishalJ99)

## License

This project is open source. See the LICENSE file for details.
