#!/usr/bin/env bash
# Fetches the Tabler outline icons gen.sh draws from, at the version in vendor/VERSION, plus Tabler's LICENSE.
# Run once per version bump and commit the output; gen.sh never touches the network.
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION=$(tr -d '[:space:]' < vendor/VERSION)
BASE="https://cdn.jsdelivr.net/npm/@tabler/icons@${VERSION}"
DEST="vendor/tabler-${VERSION}"
NAMES="circle-x alert-triangle bulb help-circle history circle-check hourglass paperclip list-check robot"

# get <url> <file>: write only on success, so a failed run leaves no partial file behind.
get() {
  curl -fsS -o "$2.part" "$1" || { rm -f "$2.part"; echo "fetch failed: $1" >&2; exit 1; }
  mv "$2.part" "$2"
}

mkdir -p "$DEST"
for name in $NAMES; do
  get "${BASE}/icons/outline/${name}.svg" "${DEST}/${name}.svg"
done
get "${BASE}/LICENSE" LICENSE-tabler
echo "fetched $(ls "$DEST"/*.svg | wc -l | tr -d ' ') icons and LICENSE-tabler from @tabler/icons@${VERSION}"
