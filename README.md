# Claude Docker

Containerized drop-in replacement for Claude Code - run worry-free in `--dangerously-skip-permissions` mode with complete isolation. Pre-configured MCP servers, host GPU access, conda environment mounting, and modular plugin system for effortless customization.

---

## Prerequisites

**Required:**
- ✅ Claude Code authentication
- ✅ Docker installation

**Everything else is optional** - the container runs fine without any additional setup.

---

## Quick Start

```bash
# 1. Clone and enter directory
git clone https://github.com/VishalJ99/claude-docker.git
cd claude-docker

# 2. Setup environment (completely optional - skip if you don't need custom config)
cp .env.example .env
nano .env  # Add any optional configs

# 3. Install
./src/install.sh

# 4. Run from any project
cd ~/your-project
claude-docker
```

**That's it!** Claude runs in an isolated Docker container with access to your project directory.

---

## Command Line Reference

### Basic Usage
```bash
claude-docker                       # Start Claude in current directory
claude-docker --podman              # Use podman instead of docker
claude-docker --continue            # Resume previous conversation
claude-docker --rebuild             # Force rebuild Docker image
claude-docker --rebuild --no-cache  # Rebuild without using cache
claude-docker --memory 8g           # Set container memory limit
claude-docker --gpus all            # Enable GPU access (requires nvidia-docker)
```

### Available Flags

| Flag | Description | Example |
|------|-------------|---------|
| `--podman` | Use podman instead of docker | `claude-docker --podman` |
| `--continue` | Resume previous conversation in current directory | `claude-docker --continue` |
| `--rebuild` | Force rebuild of the Docker image | `claude-docker --rebuild` |
| `--no-cache` | When rebuilding, don't use Docker cache | `claude-docker --rebuild --no-cache` |
| `--memory` | Set container memory limit | `claude-docker --memory 8g` |
| `--gpus` | Enable GPU access | `claude-docker --gpus all` |

### Environment Variable Defaults
Set defaults in your `.env` file:
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

---

## Optional Configuration

All configuration below is optional. The container works out-of-the-box without any of these settings.

### Environment Variables (.env file)

**All environment variables are completely optional.** Only configure what you need:

#### Twilio SMS Notifications
Get phone notifications when long-running tasks complete:
```bash
TWILIO_ACCOUNT_SID=your_twilio_sid
TWILIO_AUTH_TOKEN=your_twilio_auth_token
TWILIO_FROM_NUMBER=+1234567890
TWILIO_TO_NUMBER=+0987654321
```
**Setup:** Create a free trial account at https://www.twilio.com/docs/usage/tutorials/how-to-use-your-free-trial-account

#### Conda Integration
Mount your host conda environments and packages into the container:
```bash
# Primary conda installation path
CONDA_PREFIX=/path/to/your/conda

# Additional conda directories (space-separated list)
# Directories are mounted to the same path inside the container
# Automatic detection:
#   - Paths with "*env*" are added to CONDA_ENVS_DIRS (for environments)
#   - Paths with "*pkg*" are added to CONDA_PKGS_DIRS (for package cache)
CONDA_EXTRA_DIRS="/path/to/envs /path/to/pkgs"
```

All your conda environments work exactly as they do on your host system - no Dockerfile modifications needed.

#### System Packages
Additional apt packages beyond the Dockerfile defaults:
```bash
SYSTEM_PACKAGES="libopenslide0 libgdal-dev"
```
**Note:** Adding system packages requires rebuilding the image with `claude-docker --rebuild`.

### Git & SSH Configuration

#### Git Credentials
Git configuration (global username and email) is automatically loaded from your host system during Docker build. Commits appear as you.

**Note:** Whether Claude uses git at all is controlled by your `CLAUDE.md` prompt engineering. The default configuration does NOT include git behaviors - customize after installation if needed.

#### SSH Keys for Git Push
Claude Docker uses dedicated SSH keys (separate from your personal keys for security):

```bash
# 1. Create directory and generate key
mkdir -p ~/.claude-docker/ssh
ssh-keygen -t rsa -b 4096 -f ~/.claude-docker/ssh/id_rsa -N ''

# 2. Add public key to GitHub
cat ~/.claude-docker/ssh/id_rsa.pub
# Copy output and add to: GitHub → Settings → SSH and GPG keys → New SSH key

# 3. Test connection
ssh -T git@github.com -i ~/.claude-docker/ssh/id_rsa
```

### Custom Agent Behavior

After installation, customize Claude's behavior by editing files in `~/.claude-docker/claude-home/`:

#### CLAUDE.md (Prompt Engineering)
```bash
nano ~/.claude-docker/claude-home/CLAUDE.md
```

**Important:** The default `CLAUDE.md` includes the author's opinionated workflow preferences:
- Automatic codebase indexing on startup
- Task clarification protocols
- Conda environment execution standards
- Context.md maintenance requirements
- SMS notification behaviors

These are NOT requirements of the Docker container - they're customizable prompt engineering. Change `CLAUDE.md` to match your workflow preferences.

#### settings.json (Claude Code Settings)
```bash
nano ~/.claude-docker/claude-home/settings.json
```

Configure Claude Code settings including:
- **Timeouts:** Bash command execution timeouts (default: 24 hours)
- **MCP Timeout:** MCP server response timeout (default: 60 seconds)
- **Permissions:** Auto-approved commands (ls, grep, find, etc.)

**Recommended:** Disable auto compact to gain 30% extra usable context window:
```bash
/config auto compact set to false
```
Run this command inside Claude Code to disable automatic context compaction.

#### Other Customizations
This directory is mounted as `~/.claude` inside the container, so you can also customize:
- Slash commands (`.claude/commands/`)
- Agent personas (`.claude/agents/`)
- All standard Claude Code customizations

---

## Pre-configured MCP Servers

MCP (Model Context Protocol) servers extend Claude's capabilities. Installation is simple - just add commands to `mcp-servers.txt` that you'd normally run in terminal.

### Included MCP Servers

#### Serena MCP
Semantic code navigation and symbol manipulation with automatic project indexing.

**Value:** Better efficiency in retrieving and editing code means greater token efficiency and more usable context window.

#### Context7 MCP
Official, version-specific documentation straight from the source.

**Value:** Unhobble Claude Code by giving it up-to-date docs. Stale documentation is an artificial performance bottleneck.

**Setup:** Create a free API key at [context7.com/dashboard](https://context7.com/dashboard) and add it to your `.env` file as `CONTEXT7_API_KEY`.

#### Grep MCP
Search real code examples on GitHub.

**Value:** When documentation is missing, rapidly search across GitHub for working implementations to understand different APIs and syntaxes for unfamiliar tasks.

#### Twilio MCP
SMS notifications when tasks complete - step away from your monitor.

**Value:** Work on long-running tasks without staying at your computer. Get notified when Claude needs your attention.

### Optional MCP Servers

These servers are pre-configured but commented out in `mcp-servers.txt` to keep the default setup lean. Uncomment to enable.

#### Zen MCP (Disabled by Default)
Multi-model code review and debugging using Gemini and other LLMs via OpenRouter.

**Value:** Different LLMs debating each other normally outperforms any single LLM. Zen supports conversation threading for collaborative AI discussions, second opinions, and model debates.

**Why disabled by default:** Each Zen tool adds significant tokens to context. For focused agentic coding, this overhead isn't worth it. Enable for "vibe coding" sessions where you want AI model collaboration.

**To enable:**
1. Uncomment the Zen MCP line in `mcp-servers.txt`
2. Add `OPENROUTER_API_KEY` to your `.env` file (get one at [openrouter.ai](https://openrouter.ai))
3. Rebuild: `claude-docker --rebuild`

**Important:** Only enable the tools you need - each tool is expensive in terms of context tokens. See the [Zen MCP tools documentation](https://github.com/BeehiveInnovations/zen-mcp-server/tree/main/tools) for available tools and the [.env.example](https://github.com/BeehiveInnovations/zen-mcp-server/blob/main/.env.example) for all supported environment variables.

### MCP Installation

Example `mcp-servers.txt`:
```bash
# Serena - Coding agent toolkit
claude mcp add-json "serena" '{"command":"bash","args":[...]}'

# Context7 - Documentation lookup (requires API key in .env)
claude mcp add -s user --transport http context7 https://mcp.context7.com/mcp --header "CONTEXT7_API_KEY: ${CONTEXT7_API_KEY}"

# Grep - GitHub code search (no API key needed)
claude mcp add -s user --transport http grep https://mcp.grep.app

# Twilio SMS - Send notifications (requires Twilio credentials in .env)
claude mcp add-json twilio -s user '{"command":"npx","args":["-y","@yiyang.1i/sms-mcp-server"],"env":{...}}'
```

Each line is exactly what you'd type in your terminal to run that MCP server. The installation script handles the rest.

📋 **See [MCP_SERVERS.md](MCP_SERVERS.md) for more examples and detailed setup instructions**

---

## Features

### Core Capabilities
- **Complete AI coding agent setup** - Claude Code in isolated Docker container
- **Pre-configured MCP servers** - Advanced coding tools, documentation lookup, SMS notifications and easy set up to add more.
- **Persistent conversation history** - Resumes from where you left off with `--continue`, even after crashes
- **Host machines conda envs** - No need to waste time re setting up conda environments, host machines conda dirs are mounted and ready to use by claude docker.
- **Simple one-command setup** - Zero friction plug-and-play integration
- **Fully customizable** - Modify files at `~/.claude-docker` for custom behavior

---

## Vanilla Installation (Minimal Setup)

Want to start simple? Skip the pre-configured MCP servers and extra packages:

### 1. Remove MCP Servers
```bash
# Empty the file or delete unwanted entries
> mcp-servers.txt
claude-docker --rebuild --no-cache # For changes to take effect.
```

### 2. Remove Unwanted Packages
Edit `Dockerfile` to remove packages you don't need:
```bash
# Line 8: Python
# Line 10: Git
# Other lines: Various system packages
nano Dockerfile
claude-docker --rebuild --no-cache # For changes to take effect.
```

### 3. Customize Agent Behavior
After installation, customize Claude's behavior:
```bash
nano ~/.claude-docker/claude-home/CLAUDE.md
```
---


## Created By
- **Repository**: https://github.com/VishalJ99/claude-docker
- **Author**: Vishal J (@VishalJ99)

---

## License

This project is open source. See the LICENSE file for details.
