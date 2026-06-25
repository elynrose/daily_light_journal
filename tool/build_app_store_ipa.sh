#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
export PATH="$ROOT/tool/xcode_wrappers:${PATH}"

echo "==> Resolving dependencies"
flutter pub get

echo "==> Running tests"
flutter test

echo "==> Checking code signing"
if ! security find-identity -v -p codesigning | grep -q "Apple Distribution"; then
  echo "WARNING: No Apple Distribution certificate found."
  echo "Create one in Xcode → Settings → Accounts → [your Apple ID] → Manage Certificates → + → Apple Distribution"
  echo "Also register com.churchjournal.app in App Store Connect before exporting the IPA."
  echo ""
fi

echo "==> Building App Store IPA (com.churchjournal.app)"
flutter build ipa \
  --release \
  --export-options-plist=ios/ExportOptions.plist

IPA_PATH="$(find build/ios/ipa -name '*.ipa' | head -n 1)"
if [[ -z "$IPA_PATH" ]]; then
  echo "ERROR: IPA not found under build/ios/ipa"
  exit 1
fi

echo ""
echo "Built: $IPA_PATH"
echo ""
echo "Next steps:"
echo "  1. Apple Developer → Identifiers → register App ID: com.churchjournal.app"
echo "  2. Create Apple Distribution certificate in Xcode (Manage Certificates)"
echo "  3. App Store Connect → Apps → + → New App"
echo "     - Name: Church Journal"
echo "     - Bundle ID: com.churchjournal.app"
echo "     - SKU: church-journal"
echo "  2. Upload the IPA:"
echo "     - Open Transporter (Mac App Store) and drag the IPA, or"
echo "     - Xcode → Window → Organizer → Distribute App, or"
echo "     - GitHub Actions: Release iOS workflow with upload_to_app_store=true"
echo "  3. Complete App Store listing (screenshots, description, privacy)."
echo "  4. Submit for review."
