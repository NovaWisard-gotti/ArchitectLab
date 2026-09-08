#!/usr/bin/env bash
# Compila el APK de release en local.
set -euo pipefail

if [ ! -d android ]; then
  bash scripts/bootstrap_android.sh
fi

flutter pub get
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
flutter build apk --release

mkdir -p dist
cp build/app/outputs/flutter-apk/app-release.apk \
   dist/database-architect-lab.apk
echo "==> APK disponible en dist/database-architect-lab.apk"
