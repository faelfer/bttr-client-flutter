#!/bin/sh
set -eu

platform="${1:-}"
suite="${E2E_SUITE:-functional}"
case "$suite" in
    functional|performance) ;;
    *) echo 'E2E_SUITE deve ser functional ou performance.' >&2; exit 2 ;;
esac
if [ "$suite" = performance ] && [ "$platform" != android ]; then
    echo 'Performance CI está configurada apenas para Android.' >&2
    exit 2
fi
case "$platform" in
    android)
        driver_name=uiautomator2
        driver_package=appium-uiautomator2-driver
        driver_version=8.7.0
        ;;
    ios)
        driver_name=xcuitest
        driver_package=appium-xcuitest-driver
        driver_version=12.13.2
        ;;
    *)
        echo 'Uso: scripts/appium-e2e-ci.sh android|ios' >&2
        exit 2
        ;;
esac

for tool in node npm flutter curl; do
    command -v "$tool" >/dev/null || {
        echo "Ferramenta obrigatória ausente: $tool" >&2
        exit 1
    }
done
if [ "${BTTR_MOCK_API_MANAGED_EXTERNALLY:-0}" != 1 ]; then
    command -v docker >/dev/null || {
        echo 'Ferramenta obrigatória ausente: docker' >&2
        exit 1
    }
    docker compose version >/dev/null
fi

if [ "$platform" = android ]; then
    command -v adb >/dev/null || {
        echo 'Android SDK/adb não está no PATH.' >&2
        exit 1
    }
    E2E_ANDROID_UDID="${E2E_ANDROID_UDID:-$(adb devices | awk '$1 ~ /^emulator-/ && $2 == "device" { print $1; exit }')}"
    [ -n "$E2E_ANDROID_UDID" ] || {
        echo 'Inicie um emulador Android antes de executar os testes.' >&2
        exit 1
    }
    case "$E2E_ANDROID_UDID" in
        emulator-*) ;;
        *)
            echo 'E2E_ANDROID_UDID deve identificar um emulador Android.' >&2
            exit 1
            ;;
    esac
    export E2E_ANDROID_UDID
    export ANDROID_SERIAL="$E2E_ANDROID_UDID"
    # Production ("user") images, such as google_apis_playstore, do not register
    # the launcher activity of sideloaded apps. Appium then fails to start its
    # io.appium.settings helper with a misleading "Activity class does not
    # exist". Automation needs a userdebug image, such as google_apis.
    build_type="$(adb -s "$E2E_ANDROID_UDID" shell getprop ro.build.type | tr -d '\r')"
    [ "$build_type" = userdebug ] || {
        echo "O emulador usa uma imagem '$build_type'; o Appium exige userdebug." >&2
        echo 'Crie o AVD com system-images;android-<api>;google_apis;<abi>' >&2
        echo '(não use google_apis_playstore).' >&2
        exit 1
    }
else
    command -v xcrun >/dev/null || {
        echo 'Xcode/xcrun não está no PATH.' >&2
        exit 1
    }
    E2E_IOS_UDID="${E2E_IOS_UDID:-$(xcrun simctl list devices booted -j | node -e 'let s="";process.stdin.on("data",x=>s+=x);process.stdin.on("end",()=>{const devices=Object.values(JSON.parse(s).devices).flat();process.stdout.write(devices.find(d=>d.state==="Booted")?.udid??"")})')}"
    [ -n "$E2E_IOS_UDID" ] || {
        echo 'Inicie um simulador iOS antes de executar os testes.' >&2
        exit 1
    }
    export E2E_IOS_UDID
    E2E_IOS_PLATFORM_VERSION="${E2E_IOS_PLATFORM_VERSION:-$(xcrun simctl list devices booted -j | node -e 'let s="";process.stdin.on("data",x=>s+=x);process.stdin.on("end",()=>{for(const [runtime,devices] of Object.entries(JSON.parse(s).devices)){if(devices.some(d=>d.udid===process.env.E2E_IOS_UDID)){const match=runtime.match(/iOS-(\d+)-(\d+)/);process.stdout.write(match?`${match[1]}.${match[2]}`:"");break}}})')}"
    [ -n "$E2E_IOS_PLATFORM_VERSION" ] || {
        echo 'Não foi possível determinar a versão do simulador iOS.' >&2
        exit 1
    }
    export E2E_IOS_PLATFORM_VERSION
fi
if [ "${BTTR_MOCK_API_MANAGED_EXTERNALLY:-0}" != 1 ]; then
    docker info >/dev/null
fi

export APPIUM_HOME="${APPIUM_HOME:-$PWD/.appium}"
export BTTR_MOCK_API_PORT="${BTTR_MOCK_API_PORT:-18080}"
export BTTR_MOCK_API_URL="http://127.0.0.1:$BTTR_MOCK_API_PORT"
export APPIUM_PORT="${APPIUM_PORT:-4723}"
export APPIUM_SERVER_URL="http://127.0.0.1:$APPIUM_PORT"
export E2E_PLATFORM="$platform"
if [ -z "${COMPOSE_PROJECT_NAME:-}" ]; then
    job_hash="$(printf '%s' "${JOB_NAME:-local}" | cksum | cut -d ' ' -f 1)"
    export COMPOSE_PROJECT_NAME="bttr-client-flutter-$platform-$job_hash-${BUILD_NUMBER:-local}"
fi
mkdir -p test-results

appium_pid=
mock_started=
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
    trap - EXIT
    if [ -n "$appium_pid" ]; then
        kill "$appium_pid" 2>/dev/null || true
        wait "$appium_pid" 2>/dev/null || true
    fi
    if [ -n "$mock_started" ]; then
        if [ "$status" -ne 0 ]; then
            docker compose -f compose.e2e.yaml logs --no-color mock-api || true
        fi
        docker compose -f compose.e2e.yaml down --remove-orphans || true
    fi
    restore_workspace_owner
    exit "$status"
}
trap cleanup EXIT

if [ "${BTTR_MOCK_API_MANAGED_EXTERNALLY:-0}" != 1 ]; then
    mock_started=1
    docker compose -f compose.e2e.yaml up -d --build --wait mock-api
fi
curl --fail --silent --show-error "$BTTR_MOCK_API_URL/mock/health" >/dev/null

npm ci --no-audit --no-fund
# Os testes dos utilitários da suíte (fábricas e guardas de ambiente) não
# precisam de dispositivo e custam milissegundos. Rodá-los antes de instalar o
# driver e compilar o aplicativo troca uma falha no fim da etapa, depois de
# minutos de build, por uma falha no começo.
npm run test:e2e:helpers:ci
installed_version=
driver_manifest="$APPIUM_HOME/node_modules/$driver_package/package.json"
if [ -f "$driver_manifest" ]; then
    installed_version="$(node -p 'require(process.argv[1]).version' "$driver_manifest")"
fi
if [ "$installed_version" != "$driver_version" ]; then
    if [ -n "$installed_version" ]; then
        ./node_modules/.bin/appium driver uninstall "$driver_name"
    fi
    ./node_modules/.bin/appium driver install --source=npm "$driver_package@$driver_version"
fi

flutter pub get
if [ "$platform" = android ]; then
    if [ "$suite" = performance ]; then
        export BTTR_PERFORMANCE_BUILD=1
        flutter build apk --release \
            --dart-define=FLUTTER_ENV=dev \
            --dart-define="API_URL=http://10.0.2.2:$BTTR_MOCK_API_PORT" \
            --dart-define=BTTR_PERFORMANCE=true
        export E2E_APP_PATH="$PWD/build/app/outputs/flutter-apk/app-release.apk"
    else
        flutter build apk --debug \
            --dart-define=FLUTTER_ENV=dev \
            --dart-define="API_URL=http://10.0.2.2:$BTTR_MOCK_API_PORT"
        export E2E_APP_PATH="$PWD/build/app/outputs/flutter-apk/app-debug.apk"
    fi
else
    flutter build ios --simulator --debug \
        --dart-define=FLUTTER_ENV=dev \
        --dart-define="API_URL=http://127.0.0.1:$BTTR_MOCK_API_PORT"
    export E2E_APP_PATH="$PWD/build/ios/iphonesimulator/Runner.app"
fi

./node_modules/.bin/appium --address 127.0.0.1 --port "$APPIUM_PORT" \
    --log "test-results/appium-$platform.log" &
appium_pid=$!
ready=
for attempt in $(seq 1 60); do
    if curl --fail --silent "$APPIUM_SERVER_URL/status" >/dev/null; then
        ready=1
        break
    fi
    kill -0 "$appium_pid" 2>/dev/null || break
    sleep 1
done
[ -n "$ready" ] || {
    echo 'Appium não iniciou; consulte test-results/appium-*.log.' >&2
    exit 1
}

if [ "$suite" = performance ]; then
    npm run test:performance:android
    kill "$appium_pid" 2>/dev/null || true
    wait "$appium_pid" 2>/dev/null || true
    appium_pid=
    dart_defines="$(node -e 'process.stdout.write(["FLUTTER_ENV=dev", "API_URL=http://10.0.2.2:" + process.argv[1], "BTTR_PERFORMANCE=true"].map(x => Buffer.from(x).toString("base64")).join(","))' "$BTTR_MOCK_API_PORT")"
    (cd android && ./gradlew :macrobenchmark:connectedBenchmarkAndroidTest \
        --no-daemon \
        "-Pdart-defines=$dart_defines" \
        -Pandroid.testInstrumentationRunnerArguments.androidx.benchmark.suppressErrors=EMULATOR)
    node scripts/check-macrobenchmark.mjs
else
    npm run "test:e2e:$platform"
fi
