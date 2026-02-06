# Claude Docker Architecture Diagrams

This document contains Mermaid diagrams explaining the internals of each core script.

Note: Diagrams use `~/.claude-docker` as the default host path. You can override this with `CLAUDE_DOCKER_HOME`.

---

## System Overview

```mermaid
flowchart TB
    subgraph HOST["Host System"]
        User([User])
        Install["install.sh<br/>(one-time setup)"]
        Wrapper["claude-docker.sh<br/>(launcher)"]

        subgraph HostFiles["Host File System"]
            HomeDir["~/.claude-docker/"]
            ClaudeHome["claude-home/"]
            SSHDir["ssh/"]
            ProjectDir["Project Directory"]
            EnvFile[".env<br/>(SYSTEM_PACKAGES,<br/>CONDA_PREFIX,<br/>CONDA_EXTRA_DIRS)"]
        end

        subgraph CondaHost["Conda Installation (Host)"]
            CondaPrefix["$CONDA_PREFIX<br/>/path/to/miniconda3"]
            CondaExtraDirs["$CONDA_EXTRA_DIRS<br/>(space-separated paths)"]
        end
    end

    subgraph DOCKER["Docker Container"]
        Startup["startup.sh<br/>(entrypoint)"]
        Claude["Claude Code CLI"]

        subgraph Mounts["Volume Mounts"]
            Workspace["/workspace<br/>(rw)"]
            ContainerClaudeHome["/home/claude-user/.claude<br/>(rw)"]
            ContainerSSH["/home/claude-user/.ssh<br/>(rw)"]
            ContainerConda["$CONDA_PREFIX<br/>(ro - read only)"]
            ContainerCondaExtra["CONDA_EXTRA_DIRS<br/>(ro - read only)"]
        end
    end

    User -->|"First time"| Install
    User -->|"Each session"| Wrapper
    Install -->|"Creates"| HomeDir
    Install -->|"Copies template"| ClaudeHome

    Wrapper -->|"Sources .env<br/>builds image"| EnvFile
    Wrapper -->|"Runs container"| DOCKER
    Wrapper -->|"Mounts"| ProjectDir --> Workspace
    Wrapper -->|"Mounts"| ClaudeHome --> ContainerClaudeHome
    Wrapper -->|"Mounts"| SSHDir --> ContainerSSH
    Wrapper -->|"Mounts (if set)"| CondaPrefix --> ContainerConda
    Wrapper -->|"Mounts (if set)"| CondaExtraDirs --> ContainerCondaExtra

    Startup -->|"Loads env &<br/>starts"| Claude
```

---

## 1. install.sh - One-Time Setup

### Flow Diagram

```mermaid
flowchart TD
    Start([Start install.sh]) --> GetPaths["Resolve SCRIPT_DIR<br/>and PROJECT_ROOT"]

    GetPaths --> CreateDir["mkdir -p ~/.claude-docker/claude-home"]

    CreateDir --> CopyTemplate["Copy .claude/* template<br/>to ~/.claude-docker/claude-home/"]

    CopyTemplate --> CheckEnv{"Does .env exist<br/>in PROJECT_ROOT?"}

    CheckEnv -->|No| CreateEnv["Copy .env.example → .env"]
    CheckEnv -->|Yes| SkipEnv["Skip .env creation"]

    CreateEnv --> WarnEdit["Warn: Please edit<br/>with your API keys!"]
    WarnEdit --> CheckAlias
    SkipEnv --> CheckAlias

    CheckAlias{"'claude-docker' alias<br/>in detected shell rc?"}

    CheckAlias -->|No| AddAlias["Append alias to shell rc file:<br/>alias claude-docker='...src/claude-docker.sh'"]
    CheckAlias -->|Yes| SkipAlias["Skip alias creation"]

    AddAlias --> MakeExec
    SkipAlias --> MakeExec

    MakeExec["chmod +x claude-docker.sh<br/>chmod +x startup.sh"]

    MakeExec --> Done([Installation Complete])
```

### Files Created/Modified

```mermaid
flowchart LR
    subgraph Created["Files Created"]
        A["~/.claude-docker/claude-home/"]
        B["~/.claude-docker/claude-home/CLAUDE.md"]
        C["~/.claude-docker/claude-home/settings.json"]
        D["PROJECT_ROOT/.env"]
    end

    subgraph Modified["Files Modified"]
        E["Detected shell rc file<br/>(alias added)"]
    end

    subgraph Read["Files Read"]
        F["PROJECT_ROOT/.claude/*<br/>(templates)"]
        G["PROJECT_ROOT/.env.example"]
    end
```

---

## 2. claude-docker.sh - Main Launcher

### Argument Parsing

```mermaid
flowchart TD
    Start([Start]) --> ParseArgs["Parse CLI Arguments"]

    ParseArgs --> ArgLoop{{"Loop through args"}}

    ArgLoop -->|--podman| SetPodman["DOCKER=podman"]
    ArgLoop -->|--no-cache| SetNoCache["NO_CACHE='--no-cache'"]
    ArgLoop -->|--rebuild| SetRebuild["FORCE_REBUILD=true"]
    ArgLoop -->|--continue| SetContinue["CONTINUE_FLAG='--continue'"]
    ArgLoop -->|--memory X| SetMemory["MEMORY_LIMIT=X"]
    ArgLoop -->|--gpus X| SetGPU["GPU_ACCESS=X"]
    ArgLoop -->|other| CollectArgs["ARGS+=(arg)"]

    SetPodman --> ArgLoop
    SetNoCache --> ArgLoop
    SetRebuild --> ArgLoop
    SetContinue --> ArgLoop
    SetMemory --> ArgLoop
    SetGPU --> ArgLoop
    CollectArgs --> ArgLoop

    ArgLoop -->|done| ResolvePaths["Resolve Paths:<br/>CURRENT_DIR, SCRIPT_DIR, PROJECT_ROOT"]
```

### Main Flow

```mermaid
flowchart TD
    Start([Start claude-docker.sh]) --> ParseArgs["Parse CLI arguments<br/>(--podman, --rebuild, etc.)"]

    ParseArgs --> CheckClaudeDir{"Does .claude/ exist<br/>in current project?"}

    CheckClaudeDir -->|No| CreateClaudeDir["Create .claude/<br/>Copy CLAUDE.md template<br/>Copy scratchpad.md"]
    CheckClaudeDir -->|Yes| SkipCreate["Skip creation"]

    CreateClaudeDir --> CheckEnv
    SkipCreate --> CheckEnv

    CheckEnv{"Does PROJECT_ROOT/.env<br/>exist?"}

    CheckEnv -->|Yes| SourceEnv["Source .env file<br/>(get TWILIO vars, etc.)"]
    CheckEnv -->|No| WarnEnv["Warn: Twilio features<br/>unavailable"]

    SourceEnv --> ApplyEnvDefaults
    WarnEnv --> ApplyEnvDefaults

    ApplyEnvDefaults["Apply env defaults:<br/>MEMORY_LIMIT, GPU_ACCESS"]

    ApplyEnvDefaults --> NeedRebuild{"Need to rebuild<br/>Docker image?"}

    NeedRebuild -->|"Image missing OR<br/>--rebuild flag"| BuildImage["Build Docker Image"]
    NeedRebuild -->|No| SkipBuild["Skip build"]

    BuildImage --> EnsureDirs
    SkipBuild --> EnsureDirs

    EnsureDirs["Ensure directories exist:<br/>~/.claude-docker/claude-home<br/>~/.claude-docker/ssh"]

    EnsureDirs --> CopyAuth{"Copy credentials<br/>if not present?"}

    CopyAuth --> CheckSSH{"SSH keys<br/>configured?"}

    CheckSSH -->|No| WarnSSH["Warn: SSH keys not found<br/>Show setup instructions"]
    CheckSSH -->|Yes| CreateSSHConfig["Create SSH config<br/>if not exists"]

    WarnSSH --> PrepMounts
    CreateSSHConfig --> PrepMounts

    PrepMounts["Prepare mount arguments:<br/>- Conda mounts<br/>- Memory/GPU options"]

    PrepMounts --> RunDocker["docker run -it --rm<br/>with all mounts and args"]

    RunDocker --> End([Container Running])
```

### Docker Build Process

```mermaid
flowchart TD
    NeedBuild([Need Rebuild]) --> SourceEnv["Source .env file<br/>(already done in main flow)"]

    SourceEnv --> CopyAuth{"~/.claude.json<br/>exists?"}

    CopyAuth -->|Yes| CopyClaude["Copy ~/.claude.json<br/>to PROJECT_ROOT/<br/>(temporary for build)"]
    CopyAuth -->|No| GetGitConfig

    CopyClaude --> GetGitConfig["Get git config from host:<br/>git config --global user.name<br/>git config --global user.email"]

    GetGitConfig --> BuildArgs["Construct BUILD_ARGS:<br/>--build-arg USER_UID=$(id -u)<br/>--build-arg USER_GID=$(id -g)<br/>--build-arg GIT_USER_NAME=...<br/>--build-arg GIT_USER_EMAIL=..."]

    BuildArgs --> CheckSysPkg{"SYSTEM_PACKAGES<br/>defined in .env?"}

    CheckSysPkg -->|Yes| AddSysPkg["Add --build-arg SYSTEM_PACKAGES=...<br/><br/>Example .env:<br/>SYSTEM_PACKAGES='vim curl htop'<br/><br/>These get installed via apt-get<br/>during image build"]
    CheckSysPkg -->|No| RunBuild

    AddSysPkg --> RunBuild["docker build $BUILD_ARGS<br/>-t claude-docker:latest<br/>PROJECT_ROOT"]

    RunBuild --> Cleanup["Remove temporary<br/>.claude.json from PROJECT_ROOT"]

    Cleanup --> Done([Build Complete])
```

### Volume Mounts

```mermaid
flowchart LR
    subgraph HOST["Host System"]
        PWD["Current Project<br/>(pwd)"]
        ClaudeHome["~/.claude-docker/<br/>claude-home/"]
        SSHDir["~/.claude-docker/<br/>ssh/"]
        CondaPrefix["$CONDA_PREFIX<br/>(if set in .env)"]
        CondaExtra["$CONDA_EXTRA_DIRS<br/>(if set in .env)"]
    end

    subgraph CONTAINER["Docker Container"]
        Workspace["/workspace<br/>(rw)"]
        ContClaudeHome["/home/claude-user/<br/>.claude (rw)"]
        ContSSH["/home/claude-user/<br/>.ssh (rw)"]
        ContConda["$CONDA_PREFIX<br/>(ro)"]
        ContCondaExtra["Extra conda dirs<br/>(ro)"]
    end

    PWD -->|"-v"| Workspace
    ClaudeHome -->|"-v"| ContClaudeHome
    SSHDir -->|"-v"| ContSSH
    CondaPrefix -.->|"-v (optional)"| ContConda
    CondaExtra -.->|"-v (optional)"| ContCondaExtra
```

### Conda Mounting Logic

```mermaid
flowchart TD
    Start([Start Conda Mount Setup]) --> CheckPrefix{"CONDA_PREFIX<br/>set in .env?"}

    CheckPrefix -->|Yes| ValidatePrefix{"Directory<br/>$CONDA_PREFIX exists?"}
    CheckPrefix -->|No| LogNoConda["Log: No conda<br/>installation configured"]

    ValidatePrefix -->|Yes| MountPrefix["Add mount:<br/>-v $CONDA_PREFIX:$CONDA_PREFIX:ro<br/><br/>Add env vars:<br/>-e CONDA_PREFIX=$CONDA_PREFIX<br/>-e CONDA_EXE=$CONDA_PREFIX/bin/conda"]
    ValidatePrefix -->|No| LogNoConda

    MountPrefix --> CheckExtra{"CONDA_EXTRA_DIRS<br/>set in .env?"}
    LogNoConda --> CheckExtra

    CheckExtra -->|Yes| ParseDirs["Parse space-separated paths<br/><br/>Example .env:<br/>CONDA_EXTRA_DIRS='/path/envs /path/pkgs'"]
    CheckExtra -->|No| Done([Done])

    ParseDirs --> LoopDirs{{"For each dir<br/>in CONDA_EXTRA_DIRS"}}

    LoopDirs --> CheckDirExists{"Directory<br/>exists?"}

    CheckDirExists -->|Yes| MountDir["Add mount:<br/>-v $dir:$dir:ro"]
    CheckDirExists -->|No| SkipDir["Log: Skipping $dir<br/>(not found)"]

    MountDir --> ClassifyDir{"Path contains<br/>'env' or 'pkg'?"}
    SkipDir --> LoopDirs

    ClassifyDir -->|"Contains 'env'"| AddEnvPath["Append to CONDA_ENVS_PATHS"]
    ClassifyDir -->|"Contains 'pkg'"| AddPkgPath["Append to CONDA_PKGS_PATHS"]
    ClassifyDir -->|Neither| LoopDirs

    AddEnvPath --> LoopDirs
    AddPkgPath --> LoopDirs

    LoopDirs -->|"All dirs<br/>processed"| SetEnvVars{"Any paths<br/>collected?"}

    SetEnvVars -->|"CONDA_ENVS_PATHS set"| ExportEnvs["-e CONDA_ENVS_DIRS=<br/>colon-separated paths"]
    SetEnvVars -->|"CONDA_PKGS_PATHS set"| ExportPkgs["-e CONDA_PKGS_DIRS=<br/>colon-separated paths"]
    SetEnvVars -->|No| Done

    ExportEnvs --> Done
    ExportPkgs --> Done
```

### Conda Mount Example

```mermaid
flowchart LR
    subgraph ENV[".env Configuration"]
        E1["CONDA_PREFIX=/home/user/miniconda3"]
        E2["CONDA_EXTRA_DIRS='/data/conda/envs /data/conda/pkgs'"]
    end

    subgraph Parsing["Parsed Result"]
        P1["Mount: -v /home/user/miniconda3:/home/user/miniconda3:ro"]
        P2["Mount: -v /data/conda/envs:/data/conda/envs:ro"]
        P3["Mount: -v /data/conda/pkgs:/data/conda/pkgs:ro"]
        P4["Env: CONDA_PREFIX=/home/user/miniconda3"]
        P5["Env: CONDA_EXE=/home/user/miniconda3/bin/conda"]
        P6["Env: CONDA_ENVS_DIRS=/data/conda/envs"]
        P7["Env: CONDA_PKGS_DIRS=/data/conda/pkgs"]
    end

    E1 --> P1
    E1 --> P4
    E1 --> P5
    E2 --> P2
    E2 --> P3
    E2 --> P6
    E2 --> P7
```

---

## 3. startup.sh - Container Entrypoint

### Flow Diagram

```mermaid
flowchart TD
    Start([Container Starts]) --> LoadEnv{"/app/.env<br/>exists?"}

    LoadEnv -->|Yes| SourceEnv["Source /app/.env<br/>Export TWILIO_* vars"]
    LoadEnv -->|No| WarnNoEnv["Warn: No .env<br/>in image"]

    SourceEnv --> CheckAuth
    WarnNoEnv --> CheckAuth

    CheckAuth{"~/.claude/<br/>.credentials.json<br/>exists?"}

    CheckAuth -->|Yes| FoundAuth["Log: Found existing<br/>authentication"]
    CheckAuth -->|No| NoAuth["Log: Will need to<br/>log in"]

    FoundAuth --> CheckClaudeMD
    NoAuth --> CheckClaudeMD

    CheckClaudeMD{"~/.claude/<br/>CLAUDE.md exists?"}

    CheckClaudeMD -->|No| CopyTemplate["Copy CLAUDE.md from:<br/>1. /app/.claude/CLAUDE.md<br/>2. ~/.claude.template/ (fallback)"]
    CheckClaudeMD -->|Yes| UseExisting["Use existing CLAUDE.md<br/>Log host path info"]

    CopyTemplate --> VerifyTwilio
    UseExisting --> VerifyTwilio

    VerifyTwilio{"TWILIO_ACCOUNT_SID<br/>and AUTH_TOKEN set?"}

    VerifyTwilio -->|Yes| TwilioOK["Log: SMS notifications<br/>enabled"]
    VerifyTwilio -->|No| TwilioDisabled["Log: SMS notifications<br/>disabled"]

    TwilioOK --> StartClaude
    TwilioDisabled --> StartClaude

    StartClaude["exec claude<br/>$CLAUDE_CONTINUE_FLAG<br/>--dangerously-skip-permissions<br/>$@"]

    StartClaude --> Running([Claude Code Running])
```

### Environment Variables

```mermaid
flowchart TD
    subgraph Sources["Environment Variable Sources"]
        EnvFile["/app/.env<br/>(baked into image)"]
        DockerEnv["Docker -e flags<br/>(from claude-docker.sh)"]
    end

    subgraph Variables["Key Variables"]
        Twilio["TWILIO_ACCOUNT_SID<br/>TWILIO_AUTH_TOKEN<br/>TWILIO_FROM_NUMBER<br/>TWILIO_TO_NUMBER"]
        Conda["CONDA_PREFIX<br/>CONDA_EXE<br/>CONDA_ENVS_DIRS<br/>CONDA_PKGS_DIRS"]
        Claude["CLAUDE_CONTINUE_FLAG"]
    end

    subgraph Usage["Used By"]
        MCP["Twilio MCP Server"]
        Scripts["Python Scripts"]
        ClaudeCLI["Claude CLI"]
    end

    EnvFile --> Twilio
    DockerEnv --> Conda
    DockerEnv --> Claude

    Twilio --> MCP
    Conda --> Scripts
    Claude --> ClaudeCLI
```

### Files Accessed Inside Container

```mermaid
flowchart LR
    subgraph Read["Files Read"]
        R1["/app/.env"]
        R2["~/.claude/.credentials.json"]
        R3["/app/.claude/CLAUDE.md<br/>(template)"]
    end

    subgraph WriteOrCreate["Files Written/Created"]
        W1["~/.claude/CLAUDE.md<br/>(if missing)"]
    end

    subgraph Mounted["Mounted from Host"]
        M1["/workspace<br/>(project files)"]
        M2["~/.claude/<br/>(persistent settings)"]
        M3["~/.ssh/<br/>(SSH keys)"]
    end
```

---

## Complete Data Flow

```mermaid
sequenceDiagram
    participant U as User
    participant I as install.sh
    participant W as claude-docker.sh
    participant D as Docker Engine
    participant S as startup.sh
    participant C as Claude Code

    Note over U,C: First Time Setup
    U->>I: Run install.sh
    I->>I: Create ~/.claude-docker/
    I->>I: Copy templates
    I->>I: Setup .env
    I->>I: Add alias to detected shell rc file
    I-->>U: Setup complete

    Note over U,C: Each Session
    U->>W: Run claude-docker [args]
    W->>W: Parse arguments
    W->>W: Check/create project .claude/
    W->>W: Source .env

    alt Image needs building
        W->>D: docker build
        D-->>W: Image ready
    end

    W->>D: docker run with mounts
    D->>S: Container starts
    S->>S: Load /app/.env
    S->>S: Check credentials
    S->>S: Setup CLAUDE.md
    S->>C: exec claude CLI
    C-->>U: Interactive session
```

---

## Directory Structure

```mermaid
flowchart TD
    subgraph Host["Host File System"]
        Home["~"]
        ClaudeDocker["~/.claude-docker/"]
        CH["claude-home/<br/>├── CLAUDE.md<br/>├── settings.json<br/>└── .credentials.json"]
        SSH["ssh/<br/>├── id_rsa<br/>├── id_rsa.pub<br/>└── config"]

        Project["Your Project/"]
        ProjClaude[".claude/<br/>├── CLAUDE.md<br/>└── settings.local.json"]

        Repo["claude-docker repo/"]
        RepoSrc["src/<br/>├── install.sh<br/>├── claude-docker.sh<br/>└── startup.sh"]
        RepoEnv[".env"]
    end

    Home --> ClaudeDocker
    ClaudeDocker --> CH
    ClaudeDocker --> SSH

    Home --> Project
    Project --> ProjClaude

    Home --> Repo
    Repo --> RepoSrc
    Repo --> RepoEnv
```

---

## Quick Reference

| Script | Purpose | When Run | Key Actions |
|--------|---------|----------|-------------|
| `install.sh` | One-time setup | Once after cloning | Creates directories, copies templates, adds shell alias |
| `claude-docker.sh` | Launch wrapper | Each session | Builds image if needed, sets up mounts, runs container |
| `startup.sh` | Container entrypoint | Inside container | Loads env, checks auth, starts Claude CLI |
