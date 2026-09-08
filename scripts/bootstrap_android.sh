#!/usr/bin/env bash
# Genera la carpeta android/ (excluida del repositorio) sin tocar lib/.
# Flutter regenera las plataformas nativas de forma determinista, asi que el
# repositorio solo versiona codigo propio.
set -euo pipefail

ORG="${ANDROID_ORG:-com.emaf}"
TMP=".platform_tmp"

echo "==> Generando plataforma Android (org: $ORG)"
rm -rf "$TMP"
flutter create \
  --platforms=android \
  --org "$ORG" \
  --project-name database_architect_lab \
  "$TMP" >/dev/null

rm -rf android
cp -r "$TMP/android" ./android
rm -rf "$TMP"

MANIFEST="android/app/src/main/AndroidManifest.xml"
if [ -f "$MANIFEST" ]; then
  sed -i.bak 's/android:label="[^"]*"/android:label="Database Architect Lab"/' "$MANIFEST"
  rm -f "${MANIFEST}.bak"
fi

echo "==> Resolviendo dependencias"
flutter pub get
echo "==> Listo. Ahora puedes ejecutar: flutter build apk --release"
