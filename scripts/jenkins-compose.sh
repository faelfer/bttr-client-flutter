#!/bin/sh
set -eu

command -v docker >/dev/null || {
    echo 'O agente Jenkins precisa de Docker CLI e Compose v2.' >&2
    exit 1
}
COMPOSE_PROGRESS=quiet
export COMPOSE_PROGRESS
docker compose version
docker info >/dev/null

if [ -n "${CI_HOST_JENKINS_HOME:-}" ]; then
    : "${WORKSPACE:?WORKSPACE deve estar definido no Jenkins}"
    : "${JENKINS_HOME:?JENKINS_HOME deve estar definido no Jenkins}"
    case "$WORKSPACE" in
        "$JENKINS_HOME"/*)
            CI_WORKSPACE="$CI_HOST_JENKINS_HOME/${WORKSPACE#"$JENKINS_HOME"/}"
            export CI_WORKSPACE
            ;;
        *)
            echo 'WORKSPACE deve estar dentro de JENKINS_HOME para mapear o caminho no host.' >&2
            exit 1
            ;;
    esac
fi

CI_UID="$(id -u)"
CI_GID="$(id -g)"
job_hash="$(printf '%s' "${JOB_NAME:-local}" | cksum | cut -d ' ' -f 1)"
COMPOSE_PROJECT_NAME="bttr-client-flutter-ci-${job_hash}-${BUILD_NUMBER:-local}"
export CI_UID CI_GID COMPOSE_PROJECT_NAME

cleanup() {
    exit_code=$?
    docker compose -f compose.ci.yaml down --remove-orphans >/dev/null 2>&1 || true
    exit "$exit_code"
}
trap cleanup EXIT
docker compose -f compose.ci.yaml run --rm -T --no-deps "$@"
