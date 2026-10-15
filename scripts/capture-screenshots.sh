#!/usr/bin/env bash
# Captures the README screenshots from PaymentLab's UI tests on an iPhone simulator, in light
# and dark appearance:
#
#   store      Pro unlocked after a subscription bought through StoreKit testing in Xcode
#   checkout   the cart with two delivery choices and the Apple Pay button
#   apple-pay  the real Apple Pay sheet with the cart's total
#   card       the card form with an error under each field
#
# Usage: scripts/capture-screenshots.sh [simulator name or UDID]
# Without an argument it uses the first available iPhone simulator. Output: docs/images/
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
project="$repo_root/Examples/PaymentLab/PaymentLab.xcodeproj"
bundle_id="io.github.muhittincamdali.PaymentLab"
output_dir="$repo_root/docs/images"
shots=(store checkout apple-pay card)
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
mkdir -p "$output_dir" "$work/shots"

device="${1:-}"
if [[ -z "$device" ]]; then
  device="$(xcrun simctl list devices available | grep -m1 -oE 'iPhone [^(]+' | sed 's/ *$//')"
fi
if [[ "$device" =~ ^[0-9A-F-]{36}$ ]]; then
  udid="$device"
else
  udid="$(xcrun simctl list devices available | grep -m1 -F "$device (" | grep -oE '[0-9A-F-]{36}' || true)"
fi
if [[ -z "$udid" ]]; then
  echo "No available iPhone simulator found." >&2
  exit 1
fi

echo "Building PaymentLab for $udid"
xcodebuild build-for-testing -project "$project" -scheme PaymentLab \
  -destination "id=$udid" -derivedDataPath "$work/build" -quiet

# StoreKit testing reads the configuration's prices with the device locale, and the Apple Pay
# sheet is system UI, so the simulator runs in English (US).
xcrun simctl boot "$udid" 2>/dev/null || true
xcrun simctl bootstatus "$udid" -b >/dev/null
if [[ "$(xcrun simctl spawn "$udid" defaults read -g AppleLocale 2>/dev/null || true)" != "en_US" ]]; then
  echo "Switching the simulator to English (US)"
  xcrun simctl spawn "$udid" defaults write -g AppleLanguages -array en
  xcrun simctl spawn "$udid" defaults write -g AppleLocale -string en_US
  xcrun simctl shutdown "$udid"
  xcrun simctl boot "$udid"
  xcrun simctl bootstatus "$udid" -b >/dev/null
fi
xcrun simctl status_bar "$udid" override --time 9:41 --batteryState charged --batteryLevel 100 \
  --cellularBars 4 --wifiBars 3 --operatorName ""

for appearance in light dark; do
  xcrun simctl ui "$udid" appearance "$appearance"
  xcrun simctl uninstall "$udid" "$bundle_id" 2>/dev/null || true
  TEST_RUNNER_SCREENSHOT_DIR="$work/shots" TEST_RUNNER_APPEARANCE="$appearance" \
    xcodebuild test-without-building -project "$project" -scheme PaymentLab \
      -destination "id=$udid" -derivedDataPath "$work/build" -only-testing:PaymentLabUITests \
      > "$work/test-$appearance.log" 2>&1 \
    || { grep -E "error:|failed" "$work/test-$appearance.log" >&2; exit 1; }
done

for appearance in light dark; do
  for shot in "${shots[@]}"; do
    file="$output_dir/$shot-$appearance.png"
    cp "$work/shots/$shot-$appearance.png" "$file"
    # Half the width of an iPhone 17 Pro screenshot keeps the README light.
    sips --resampleWidth 603 "$file" >/dev/null
    echo "$file"
  done
done

xcrun simctl status_bar "$udid" clear
xcrun simctl terminate "$udid" "$bundle_id" 2>/dev/null || true
