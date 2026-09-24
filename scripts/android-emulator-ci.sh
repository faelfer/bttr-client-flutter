#!/bin/sh
set -eu

for tool in adb emulator; do
    command -v "$tool" >/dev/null || {
        echo "Ferramenta obrigatória ausente no runner Android: $tool" >&2
        exit 1
    }
done

mkdir -p test-results

avd_name="${ANDROID_AVD_NAME:-bttr-ci}"
emulator_port="${ANDROID_EMULATOR_PORT:-5554}"
emulator_serial="emulator-$emulator_port"
emulator_accel="${ANDROID_EMULATOR_ACCEL:-}"
if [ -z "$emulator_accel" ]; then
    if [ -c /dev/kvm ] && [ -r /dev/kvm ] && [ -w /dev/kvm ]; then
        emulator_accel=on
    else
        emulator_accel=off
    fi
fi

emulator_pid=
restore_workspace_owner() {
    if [ "$(id -u)" -eq 0 ] && [ -n "${CI_UID:-}" ] && [ "${CI_UID}" -ne 0 ]; then
        for path in .appium .dart_tool .pub-cache .gradle-cache .cache \
            node_modules build test-results e2e/artifacts \
            .flutter-plugins-dependencies android/.gradle android/.kotlin \
            android/local.properties android/app/src/main/java; do
            if [ -e "$path" ]; then
                chown -R "${CI_UID}:${CI_GID}" "$path"
            fi
        done
    fi
}
cleanup() {
    status=$?
    trap - EXIT INT TERM
    if [ -n "$emulator_pid" ]; then
        adb -s "$emulator_serial" emu kill >/dev/null 2>&1 || true
        kill "$emulator_pid" 2>/dev/null || true
        wait "$emulator_pid" 2>/dev/null || true
    fi
    restore_workspace_owner
    if [ "$status" -ne 0 ]; then
        echo 'Últimas linhas do log do emulador Android:' >&2
        tail -n 100 test-results/android-emulator.log >&2 || true
    fi
    exit "$status"
}
trap cleanup EXIT INT TERM

adb start-server >/dev/null
emulator -avd "$avd_name" \
    -port "$emulator_port" \
    -accel "$emulator_accel" \
    -gpu lavapipe \
    -no-window \
    -no-audio \
    -no-boot-anim \
    -no-snapshot \
    -no-metrics \
    -wipe-data \
    >test-results/android-emulator.log 2>&1 &
emulator_pid=$!

booted=
for attempt in $(seq 1 360); do
    if ! kill -0 "$emulator_pid" 2>/dev/null; then
        break
    fi
    if [ "$(adb -s "$emulator_serial" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = 1 ]; then
        booted=1
        break
    fi
    sleep 2
done
[ -n "$booted" ] || {
    echo 'O emulador Android não concluiu o boot em 12 minutos.' >&2
    exit 1
}

adb -s "$emulator_serial" shell settings put global window_animation_scale 0
adb -s "$emulator_serial" shell settings put global transition_animation_scale 0
adb -s "$emulator_serial" shell settings put global animator_duration_scale 0
adb -s "$emulator_serial" shell input keyevent 82

export E2E_ANDROID_UDID="$emulator_serial"
./scripts/appium-e2e-ci.sh android
