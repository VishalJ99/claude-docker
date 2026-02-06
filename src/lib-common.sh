#!/usr/bin/env bash
# ABOUTME: Shared helpers for claude-docker launcher and installer scripts.

get_home_for_uid() {
    local uid="${1:-}"
    local home_dir=""

    if [ -z "$uid" ]; then
        return 1
    fi

    if command -v getent >/dev/null 2>&1; then
        home_dir="$(getent passwd "$uid" | cut -d: -f6 || true)"
    fi

    if [ -z "$home_dir" ] && [ -r /etc/passwd ]; then
        home_dir="$(awk -F: -v uid="$uid" '$3 == uid { print $6; exit }' /etc/passwd || true)"
    fi

    if [ -n "$home_dir" ]; then
        printf '%s\n' "$home_dir"
        return 0
    fi

    return 1
}

version_gte() {
    local version_a="${1#v}"
    local version_b="${2#v}"
    local i=0
    local max_len=0
    local part_a=0
    local part_b=0
    local digits_a=""
    local digits_b=""

    IFS='.' read -r -a version_a_parts <<< "$version_a"
    IFS='.' read -r -a version_b_parts <<< "$version_b"

    if [ "${#version_a_parts[@]}" -gt "${#version_b_parts[@]}" ]; then
        max_len="${#version_a_parts[@]}"
    else
        max_len="${#version_b_parts[@]}"
    fi

    while [ "$i" -lt "$max_len" ]; do
        digits_a="$(printf '%s' "${version_a_parts[$i]:-0}" | sed 's/[^0-9].*$//')"
        digits_b="$(printf '%s' "${version_b_parts[$i]:-0}" | sed 's/[^0-9].*$//')"

        if [ -z "$digits_a" ]; then
            digits_a="0"
        fi

        if [ -z "$digits_b" ]; then
            digits_b="0"
        fi

        part_a=$((10#$digits_a))
        part_b=$((10#$digits_b))

        if [ "$part_a" -gt "$part_b" ]; then
            return 0
        fi

        if [ "$part_a" -lt "$part_b" ]; then
            return 1
        fi

        i=$((i + 1))
    done

    return 0
}

resolve_claude_docker_dir() {
    local preferred_home="${1:-}"
    local home_dir="${preferred_home:-${HOME:-}}"
    local resolved_dir=""

    if [ -n "${CLAUDE_DOCKER_HOME:-}" ]; then
        resolved_dir="$CLAUDE_DOCKER_HOME"
    else
        if [ -z "$home_dir" ]; then
            home_dir="$(get_home_for_uid "$(id -u)" || true)"
        fi

        if [ -z "$home_dir" ]; then
            echo "Error: Could not determine a usable home directory."
            echo "Set CLAUDE_DOCKER_HOME to a writable location, for example:"
            echo "  export CLAUDE_DOCKER_HOME=/path/to/writable/dir"
            return 1
        fi

        resolved_dir="$home_dir/.claude-docker"
    fi

    if [ "$resolved_dir" = "~" ]; then
        if [ -z "${HOME:-}" ]; then
            echo "Error: CLAUDE_DOCKER_HOME='~' requires HOME to be set."
            echo "Set CLAUDE_DOCKER_HOME to an absolute writable path."
            return 1
        fi
        resolved_dir="$HOME"
    elif [[ "$resolved_dir" == "~/"* ]]; then
        if [ -z "${HOME:-}" ]; then
            echo "Error: CLAUDE_DOCKER_HOME uses '~' but HOME is not set."
            echo "Set CLAUDE_DOCKER_HOME to an absolute writable path."
            return 1
        fi
        resolved_dir="${HOME%/}/${resolved_dir#~/}"
    fi

    if [[ "$resolved_dir" != /* ]]; then
        resolved_dir="$(pwd)/$resolved_dir"
    fi

    if ! mkdir -p "$resolved_dir"; then
        echo "Error: Could not create directory: $resolved_dir"
        echo "Set CLAUDE_DOCKER_HOME to a writable location, for example:"
        echo "  export CLAUDE_DOCKER_HOME=/path/to/writable/dir"
        return 1
    fi

    if [ ! -d "$resolved_dir" ] || [ ! -w "$resolved_dir" ]; then
        echo "Error: Directory is not writable: $resolved_dir"
        echo "Set CLAUDE_DOCKER_HOME to a writable location, for example:"
        echo "  export CLAUDE_DOCKER_HOME=/path/to/writable/dir"
        return 1
    fi

    CLAUDE_DOCKER_DIR="$resolved_dir"
    export CLAUDE_DOCKER_DIR
}

check_container_runtime() {
    local runtime="${1:-docker}"
    local runtime_name=""
    local min_docker_api="${2:-1.44}"
    local client_api=""
    local server_api=""

    if ! command -v "$runtime" >/dev/null 2>&1; then
        echo "Error: Container runtime '$runtime' was not found in PATH."
        return 1
    fi

    if ! "$runtime" info >/dev/null 2>&1; then
        echo "Error: Cannot connect to '$runtime' daemon."
        echo "Ensure '$runtime' is running and your user has permission to access it."
        return 1
    fi

    runtime_name="$(basename "$runtime")"

    # Docker API compatibility gate (podman does not expose Docker APIVersion fields reliably).
    if [ "$runtime_name" = "docker" ]; then
        client_api="$("$runtime" version --format '{{.Client.APIVersion}}' 2>/dev/null || true)"
        server_api="$("$runtime" version --format '{{.Server.APIVersion}}' 2>/dev/null || true)"

        if [ -z "$client_api" ] || [ -z "$server_api" ]; then
            echo "Error: Unable to detect Docker API versions."
            echo "Run 'docker version' and verify both Client and Server API versions are available."
            return 1
        fi

        if ! version_gte "$client_api" "$min_docker_api"; then
            echo "Error: Docker client API version $client_api is too old."
            echo "Minimum supported Docker API version is $min_docker_api."
            return 1
        fi

        if ! version_gte "$server_api" "$min_docker_api"; then
            echo "Error: Docker server API version $server_api is too old."
            echo "Minimum supported Docker API version is $min_docker_api."
            return 1
        fi
    fi

    return 0
}
