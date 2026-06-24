#!/usr/bin/env bash

set -euo pipefail

PROJECT="Melodic Stamp.xcodeproj"
SCHEME="MelodicStamp"
CONFIGURATION="${CONFIGURATION:-Release}"
DESTINATION="${DESTINATION:-platform=macOS}"
APP_NAME="Melodic Stamp"
DERIVED_DATA="${DERIVED_DATA:-$HOME/Library/Developer/Xcode/DerivedData}"
APP_DST="${APP_DST:-/Applications/${APP_NAME}.app}"
LAUNCH_COUNT="${LAUNCH_COUNT:-3}"
LAUNCH_WAIT_SECONDS="${LAUNCH_WAIT_SECONDS:-6}"

cd "$(git rev-parse --show-toplevel)"

echo "== Build ${CONFIGURATION}"
xcodebuild \
  -project "${PROJECT}" \
  -scheme "${SCHEME}" \
  -configuration "${CONFIGURATION}" \
  -destination "${DESTINATION}" \
  build

APP_SRC="$(find "${DERIVED_DATA}" -type d -path "*/Build/Products/${CONFIGURATION}/${APP_NAME}.app" 2>/dev/null | sort | tail -n 1)"
if [[ -z "${APP_SRC}" || ! -d "${APP_SRC}" ]]; then
  echo "Could not locate built app for ${CONFIGURATION}" >&2
  exit 1
fi

echo "== Install ${APP_DST}"
pkill -x "${APP_NAME}" 2>/dev/null || true
rm -rf "${APP_DST}"
ditto "${APP_SRC}" "${APP_DST}"

echo "== Ad-hoc sign and verify"
codesign --force --deep --sign - --entitlements "MelodicStamp/MelodicStamp.entitlements" "${APP_DST}"
codesign --verify --deep --strict --verbose=2 "${APP_DST}"

echo "== Launch smoke"
for i in $(seq 1 "${LAUNCH_COUNT}"); do
  open -n "${APP_DST}"
  sleep "${LAUNCH_WAIT_SECONDS}"

  if pgrep -f "${APP_DST}/Contents/MacOS/${APP_NAME}" >/dev/null; then
    echo "launch-${i}: running"
    pkill -x "${APP_NAME}" 2>/dev/null || true
    sleep 1
  else
    echo "launch-${i}: not running" >&2
    exit 1
  fi
done

echo "== Recent crash/constraint log scan"
recent_issues="$(
  /usr/bin/log show \
    --predicate "process == \"${APP_NAME}\" AND (eventMessage CONTAINS \"Update Constraints in Window\" OR eventMessage CONTAINS \"NSGenericException\")" \
    --last 3m \
    --info \
    --debug \
    --style compact 2>/dev/null | tail -n 20
)"

if [[ -n "${recent_issues}" && "${recent_issues}" != "Timestamp"* ]]; then
  echo "${recent_issues}" >&2
  exit 1
fi

echo "QA smoke passed"
