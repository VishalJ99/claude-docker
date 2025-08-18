# CORE EXECUTION PROTOCOL
THESE RULES ARE ABSOLUTE AND APPLY AT ALL TIMES.

## General

### 1. STARTUP PROCEDURE
- **FIRST & ALWAYS**: IF project dir has existing code, we MUST index the codebase using Serena MCP.
  `uvx --from git+https://github.com/oraios/serena index-project`

### 2. TASK CLARIFICATION PROTOCOL
- **MANDATORY CLARIFICATION**: If the user's prompt contains ANY vagueness or insufficient detail related to the goal being implied, you MUST ask clarifying questions before proceeding.

### 3A. SYSTEM PACKAGE INSTALLATION PROTOCOL
- **APT-GET SYSTEM PACKAGES**: USE `sudo apt-get install` to install missing system packages when required for the task.

### 3B. PYTHON/CONDA ENVIRONMENT EXECUTION PROTOCOL
- **MANDATORY CONDA BINARY**:
  ALWAYS use the conda binary at `$CONDA_PREFIX/bin/conda` for all environment and script execution commands.

- **SCRIPT EXECUTION FORMAT**:
  ALWAYS follow these steps for Python script execution:
  
  1. **First, list conda environments to get Python binary paths**:
  ```bash
  ${CONDA_EXE:-conda} env list
  /vol/biomedic3/vj724/miniconda3/bin/conda env list
  ```
  
  2. **Then execute Python scripts using the direct binary path**:
  ```bash
  /path/to/environment/bin/python your_script.py [args]
  ```
  - Replace `/path/to/environment/bin/python` with the actual Python binary path from step 1.
  - Replace `your_script.py [args]` with the script and its arguments.

### 4. CODEBASE CONTEXT MAINTENANCE PROTOCOL
- All scripts MUST use the `argparse` module for command-line argument handling. This ensures consistent, robust, and self-documenting CLI interfaces for all scripts.
- **MANDATORY CONTEXT.MD MAINTENANCE**: The `context.md` file MUST be maintained and updated by EVERY agent working on the codebase.
- **PURPOSE**: `context.md` provides a high-level architectural overview of the codebase, eliminating the need for future agents to scan the entire codebase for understanding.
- **CONTENT REQUIREMENTS**: `context.md` MUST contain:
  - **MODULE ARCHITECTURE**: Clear mapping of all key modules/scripts and their primary responsibilities
  - **DATA FLOW**: How data flows between different components
  - **DEPENDENCIES**: Key dependencies between modules and external libraries
  - **ENTRY POINTS**: Main execution entry points and their purposes
  - **CONFIGURATION**: How configuration is managed across the system
  - **CORE LOGIC**: Summary of the core business logic each module handles
- **UPDATE FREQUENCY**: 
  - **IMMEDIATE**: Update `context.md` whenever new modules are created
  - **AFTER LOGIC CHANGES**: Update whenever core logic in existing modules is modified
  - **BEFORE COMMITS**: Ensure `context.md` is current before any commit
- **STRUCTURE**: Use clear headings, bullet points, and code examples where helpful
- **NO EXCEPTIONS**: This file is CRITICAL for maintaining agent productivity and MUST be kept current

### 5. LOGGING & COMMUNICATION PROTOCOL
- **SEND USER TEXT AS CHECKLIST ITEM**: ALWAYS add 'Send user text' as an explicit checklist item to assure the user the text will be sent.
- **TWILIO SMS IS THE PRIMARY "CALL-BACK" MECHANISM**:
    - **SEND A TEXT AT THE END OF EVERY CHECKLIST**: A checklist represents a significant task. A text signals that this task is complete and your attention is needed.
    - **WHEN TO SEND**:
        1.  **SUCCESSFUL CHECKLIST COMPLETION**: When all items are successfully checked off.
        2.  **EARLY TERMINATION OF CHECKLIST**: When you must abandon the current checklist for any reason (e.g., you are stuck, the plan is flawed).
    - **MESSAGE CONTENT**: The text MUST contain a brief summary of the outcome (what was achieved or why termination occurred) so you are up-to-speed when you return.
    - **PREREQUISITE**: This is mandatory ONLY if all `TWILIO_*` environment variables are set.
    - **CRITICAL**: Evaluate `$TWILIO_TO_NUMBER` and store it in a temporary variable BEFORE using it in the send command. NEVER embed the raw `$TWILIO_TO_NUMBER` variable directly in the MCP tool call.
    - **MESSAGE DELIVERY VERIFICATION**: After sending ANY SMS, ALWAYS verify delivery status using:
        ```bash
        curl -X GET "https://api.twilio.com/2010-04-01/Accounts/$TWILIO_ACCOUNT_SID/Messages/[MESSAGE_SID].json" -u "$TWILIO_ACCOUNT_SID:$TWILIO_AUTH_TOKEN"
        ```
        Check the "status" field in the response. If status is "failed", retry with progressively shorter messages:
        1. First retry: "Task complete - [brief outcome]"
        2. Second retry: "Task done - [status]"
        3. Final retry: "Task complete"
        Continue until a message has status "delivered" or "sent".

## Tool Usage

### Documentation Tools

**View Official Documentation** - 
`resolve-library-id` - Resolve library name to Context7 ID- `get-library-docs` - Get latest official documentation

**Search Real Code** - 
`searchGitHub` - Search actual use cases on GitHub 

**Writing Specification Documentation Tools** - 
Use `specs-workflow` when writing requirements and design documents:

**Check Progress**: `action.type="check"`

**Initialize**: `action.type="init"`

**Update Tasks**: `action.type="complete_task"` Path: `/docs/specs/*` 
