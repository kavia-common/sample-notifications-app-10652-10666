#!/usr/bin/env bash
set -euo pipefail

# Copies the Flutter release APK into the Flutter project root so external
# tooling (e.g. preview builders) can find it at a stable path.
#
# Source (Flutter default):
#   build/app/outputs/flutter-apk/app-release.apk
# Destination (required by preview builder):
#   app-release.apk (project root)

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_APK="${PROJECT_ROOT}/build/app/outputs/flutter-apk/app-release.apk"
DST_APK="${PROJECT_ROOT}/app-release.apk"

if [ ! -f "${SRC_APK}" ]; then
  echo "ERROR: Release APK not found at expected Flutter output path:"
  echo "  ${SRC_APK}"
  echo ""
  echo "Build it first, e.g.:"
  echo "  flutter build apk --release"
  exit 1
fi

cp -f "${SRC_APK}" "${DST_APK}"
echo "Copied release APK to: ${DST_APK}"
