#!/usr/bin/env bash
set -euo pipefail

PROJECT="CommunityHub.xcodeproj"
SCHEME="CommunityHub"
BUNDLE_ID="com.example.CommunityHub"
SIM_NAME="${1:-iPhone 14}"
DERIVED_DATA_PATH="${PWD}/.derivedData"

echo "Opening Simulator..."
open -a Simulator

DEVICE_ID="$(xcrun simctl list devices available | awk -v name="$SIM_NAME" -F '[()]' '$0 ~ name && $0 ~ /Shutdown|Booted/ {print $2; exit}')"

if [[ -z "$DEVICE_ID" ]]; then
  echo "Simulator '$SIM_NAME' not found. Available devices:"
  xcrun simctl list devices available
  exit 1
fi

echo "Using simulator: $SIM_NAME ($DEVICE_ID)"
xcrun simctl boot "$DEVICE_ID" >/dev/null 2>&1 || true
xcrun simctl bootstatus "$DEVICE_ID" -b

echo "Building app..."
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "platform=iOS Simulator,id=$DEVICE_ID" \
  -sdk iphonesimulator \
  -configuration Debug \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  build >/dev/null

APP_PATH="$DERIVED_DATA_PATH/Build/Products/Debug-iphonesimulator/CommunityHub.app"

if [[ ! -d "$APP_PATH" ]]; then
  echo "App bundle not found at: $APP_PATH"
  exit 1
fi

echo "Installing app..."
xcrun simctl install "$DEVICE_ID" "$APP_PATH"

echo "Launching app..."
xcrun simctl launch "$DEVICE_ID" "$BUNDLE_ID" >/dev/null || true

echo "Done. If app is not foregrounded, open it from the Simulator home screen."
