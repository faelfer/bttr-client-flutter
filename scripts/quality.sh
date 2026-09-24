#!/bin/sh
set -eu

# Compatibility fallback for callers that explicitly override the Compose
# user. The Jenkins pipeline normally runs with CI_UID:CI_GID from the start.
if [ "$(id -u)" -eq 0 ] && [ -n "${CI_UID:-}" ] && [ "${CI_UID}" -ne 0 ]; then
    restore_workspace_owner() {
        for path in .dart_tool .pub-cache .gradle-cache .cache coverage build test-results \
            .flutter-plugins-dependencies android/.gradle android/.kotlin \
            android/local.properties android/app/src/main/java \
            ios/Flutter/Generated.xcconfig ios/Flutter/flutter_export_environment.sh \
            ios/Flutter/ephemeral; do
            if [ -e "$path" ]; then
                chown -R "${CI_UID}:${CI_GID}" "$path"
            fi
        done
    }
    trap restore_workspace_owner EXIT
fi

case "${1:-}" in
    dependencies)
        flutter pub get --enforce-lockfile
        ;;
    dart-format-check)
        dart format --output=none --set-exit-if-changed lib test
        ;;
    dart-format)
        dart format lib test
        ;;
    dart-lint)
        flutter analyze
        ;;
    kotlin-check)
        (cd android && ./gradlew ktlintCheck :app:ktlintCheck --no-daemon)
        ;;
    kotlin-format)
        (cd android && ./gradlew ktlintFormat :app:ktlintFormat --no-daemon)
        ;;
    swift-format-check)
        swift format lint --strict --recursive ios/Runner ios/RunnerTests
        ;;
    swift-format)
        swift format format --in-place --recursive ios/Runner ios/RunnerTests
        ;;
    swift-lint)
        swiftlint lint --strict --no-cache --config .swiftlint.yml
        ;;
    test)
        flutter test --coverage
        ;;
    test-ci)
        mkdir -p test-results
        rm -f test-results/TEST-flutter.xml
        set +e
        flutter test --coverage --machine > test-results/flutter-tests.jsonl
        test_status=$?
        set -e
        # Flutter also prints JSON arrays for VM service notifications.
        # junitify consumes the JSON object events from the test protocol.
        sed -n '/^[[:space:]]*{/p' test-results/flutter-tests.jsonl \
            > test-results/flutter-tests.events.jsonl
        dart run junitify -i test-results/flutter-tests.events.jsonl \
            -o test-results/TEST-flutter.xml
        exit "$test_status"
        ;;
    *)
        echo "Uso: $0 {dependencies|dart-format-check|dart-format|dart-lint|kotlin-check|kotlin-format|swift-format-check|swift-format|swift-lint|test|test-ci}" >&2
        exit 2
        ;;
esac
