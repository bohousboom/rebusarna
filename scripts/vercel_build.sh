#!/usr/bin/env bash
# Sestaví Flutter web na Vercelu (ten Flutter nemá předinstalovaný).
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-3.47.6}"
FLUTTER_DIR="$HOME/flutter"

if [ ! -x "$FLUTTER_DIR/bin/flutter" ]; then
  git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$FLUTTER_DIR" \
    || git clone --depth 1 --branch stable https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi

git config --global --add safe.directory "$FLUTTER_DIR" || true
export PATH="$FLUTTER_DIR/bin:$PATH"

flutter config --no-analytics >/dev/null
flutter --version
flutter precache --web
flutter pub get
# Pozdější klíče (Supabase) se předají přes --dart-define z proměnných prostředí Vercelu.
flutter build web --release
