#!/bin/sh
set -eu
mode="${1:-e2e}"
case "$mode" in
    e2e|performance) ;;
    *) echo 'Uso: scripts/jenkins-android-e2e.sh [e2e|performance]' >&2; exit 2 ;;
esac

command -v docker >/dev/null || {
    echo 'O agente Jenkins precisa de Docker CLI e Compose v2.' >&2
    exit 1
}
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
if [ -e /dev/kvm ]; then
    KVM_GID="$(stat -c %g /dev/kvm)"
else
    KVM_GID=0
fi
job_hash="$(printf '%s' "${JOB_NAME:-local}" | cksum | cut -d ' ' -f 1)"
COMPOSE_PROJECT_NAME="bttr-client-flutter-${mode}-${job_hash}-${BUILD_NUMBER:-local}"
mock_project="${COMPOSE_PROJECT_NAME}-mock"
runner_project="${COMPOSE_PROJECT_NAME}-runner"
BTTR_MOCK_API_PORT="${BTTR_MOCK_API_PORT:-18080}"
export CI_UID CI_GID KVM_GID COMPOSE_PROJECT_NAME BTTR_MOCK_API_PORT

mock_started=
cleanup() {
    status=$?
    trap - EXIT
    if [ -n "$mock_started" ]; then
        if [ "$status" -ne 0 ]; then
            docker compose -p "$mock_project" -f compose.e2e.yaml \
                logs --no-color --tail 100 mock-api || true
        fi
        docker compose -p "$mock_project" -f compose.e2e.yaml \
            down --remove-orphans || true
    fi
    docker compose -p "$runner_project" -f compose.ci.yaml \
        down --remove-orphans >/dev/null 2>&1 || true
    exit "$status"
}
trap cleanup EXIT

: "${BTTR_MOCK_API_CONTEXT:=.ci/bttr-server/mock-api}"
export BTTR_MOCK_API_CONTEXT
mock_started=1
docker compose -p "$mock_project" -f compose.e2e.yaml \
    up -d --build --wait mock-api
docker compose -p "$runner_project" -f compose.ci.yaml build android-e2e
docker compose -p "$runner_project" -f compose.ci.yaml run --rm -T --no-deps \
    android-e2e ./scripts/android-emulator-ci.sh "$mode"
