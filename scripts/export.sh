#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────
# export.sh — Render source.html to PDF via Chrome headless
# Usage:  ./scripts/export.sh [input.html] [output.pdf]
# ──────────────────────────────────────────────────────────────
set -euo pipefail

INPUT="${1:-templates/source.html}"
OUTPUT="${2:-output.pdf}"

# ── Locate Chrome / Chromium ──────────────────────────────────
find_chrome() {
  # macOS locations
  local mac_paths=(
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
    "/Applications/Chromium.app/Contents/MacOS/Chromium"
    "/Applications/Google Chrome Canary.app/Contents/MacOS/Google Chrome Canary"
    "/Applications/Brave Browser.app/Contents/MacOS/Brave Browser"
  )
  # Linux locations
  local linux_paths=(
    "google-chrome"
    "google-chrome-stable"
    "chromium"
    "chromium-browser"
  )

  for path in "${mac_paths[@]}"; do
    if [[ -x "$path" ]]; then
      echo "$path"
      return 0
    fi
  done

  for cmd in "${linux_paths[@]}"; do
    if command -v "$cmd" &>/dev/null; then
      command -v "$cmd"
      return 0
    fi
  done

  return 1
}

CHROME=$(find_chrome) || {
  echo "Error: Chrome or Chromium not found."
  echo "Install Google Chrome or set the CHROME environment variable."
  exit 1
}

# Allow override via environment variable
CHROME="${CHROME_PATH:-$CHROME}"

# ── Resolve absolute path to input ────────────────────────────
INPUT_ABS="$(cd "$(dirname "$INPUT")" && pwd)/$(basename "$INPUT")"

if [[ ! -f "$INPUT_ABS" ]]; then
  echo "Error: Input file not found: $INPUT_ABS"
  exit 1
fi

# ── Run headless export ───────────────────────────────────────
echo "Exporting: $INPUT_ABS"
echo "Chrome:    $CHROME"
echo "Output:    $OUTPUT"

"$CHROME" \
  --headless \
  --disable-gpu \
  --virtual-time-budget=15000 \
  --run-all-compositor-stages-before-draw \
  --print-to-pdf="$OUTPUT" \
  --print-to-pdf-no-header \
  --no-margins \
  "file://$INPUT_ABS"

if [[ -f "$OUTPUT" ]]; then
  echo "Done. PDF saved to $OUTPUT ($(du -h "$OUTPUT" | cut -f1))"
else
  echo "Error: PDF was not created."
  exit 1
fi
