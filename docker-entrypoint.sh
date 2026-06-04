#!/bin/sh
set -eu

if [ -n "${CODEX_DOCKER_MODEL_CONTEXT_HOST:-}" ] && command -v docker >/dev/null 2>&1; then
    context_name="${CODEX_DOCKER_MODEL_CONTEXT_NAME:-codex-host}"

    if ! docker model context inspect "$context_name" >/dev/null 2>&1; then
        docker model context create "$context_name" \
            --host "$CODEX_DOCKER_MODEL_CONTEXT_HOST" >/dev/null 2>&1 || true
    fi

    docker model context use "$context_name" >/dev/null 2>&1 || true
fi

exec codex "$@"
