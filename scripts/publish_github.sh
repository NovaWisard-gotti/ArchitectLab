#!/usr/bin/env bash
# Publica el proyecto en GitHub y dispara el pipeline de CI/CD.
# Requiere GitHub CLI autenticado: gh auth login
set -euo pipefail

REPO_NAME="${1:-database-architect-lab}"
VISIBILITY="${2:-public}"

if ! command -v gh >/dev/null 2>&1; then
  echo "Instala GitHub CLI (https://cli.github.com) o crea el repositorio a mano."
  exit 1
fi

git init -b main
git add .
git commit -m "Database Architect Lab: laboratorio movil de diseno de bases de datos"
gh repo create "$REPO_NAME" --"$VISIBILITY" --source=. --push

echo "==> Repositorio publicado. El workflow de CI compila el APK automaticamente."
echo "==> Para generar un release con APK adjunto:"
echo "    git tag v1.0.0 && git push origin v1.0.0"
