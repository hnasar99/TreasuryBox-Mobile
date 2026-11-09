#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

# Match the mobile application's SDK and verify the immutable Git revision.
readonly FLUTTER_VERSION=3.47.7
readonly FLUTTER_REVISION=abaf9c523780a608bd46686fd5e53740a07077f8
readonly SDK_DIR="${FLUTTER_SDK_PATH:-/tmp/treasurybox-flutter-${FLUTTER_VERSION}}"
export CI=true
export FLUTTER_SUPPRESS_ANALYTICS=true
export DART_SUPPRESS_ANALYTICS=true
if [[ ! -x "${SDK_DIR}/bin/flutter" ]]; then
  git clone --depth 1 --branch "${FLUTTER_VERSION}" https://github.com/flutter/flutter.git "${SDK_DIR}"
fi
[[ "$(git -C "${SDK_DIR}" rev-parse HEAD)" == "${FLUTTER_REVISION}" ]] || {
  echo 'Unexpected Flutter SDK revision; refusing to build.' >&2
  exit 1
}
export PATH="${SDK_DIR}/bin:${PATH}"
flutter config --no-analytics
flutter --version
flutter pub get --enforce-lockfile
flutter test
flutter build web --release --no-web-resources-cdn \
  -t lib/main_web.dart \
  --dart-define-from-file=env/celo.example.json \
  --dart-define=TREASURY_MODE=dry-run
[[ -s build/web/index.html && -s build/web/main.dart.js ]]
