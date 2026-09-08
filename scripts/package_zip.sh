#!/usr/bin/env bash
# Empaqueta el codigo fuente listo para entregar.
set -euo pipefail

NAME="database-architect-lab-src"
rm -rf "dist/$NAME.zip"
mkdir -p dist
zip -r "dist/$NAME.zip" . \
  -x '*.git*' 'build/*' '.dart_tool/*' 'android/*' 'dist/*' '*.apk' >/dev/null
echo "==> Paquete generado en dist/$NAME.zip"
