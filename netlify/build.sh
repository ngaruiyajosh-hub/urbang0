#!/usr/bin/env bash
set -euo pipefail

# Install Flutter SDK (stable channel)
FLUTTER_DIR="$HOME/flutter"
if [ ! -d "$FLUTTER_DIR" ]; then
  git clone -b stable https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi

export PATH="$FLUTTER_DIR/bin:$PATH"

# Debug info
flutter --version

# Enable web support and fetch dependencies
flutter config --enable-web
flutter pub get
flutter precache --web

# Build release web output
flutter build web --release
