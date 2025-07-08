###############################################
# build_latest_orthophoto.sh
# Pick the newest flight folder (YYYYMMDD prefix) and tile its GeoTIFF.
# Usage: ./build_latest_orthophoto.sh  [flights-dir] [dest-root]
###############################################
#!/usr/bin/env bash
# re-exec with bash if started by sh/ash/dash
[ -z "$BASH_VERSION" ] && exec /usr/bin/env bash "$0" "$@"
set -euo pipefail

# ---- Default paths for *current* WSL mount ----
FLIGHTS_DIR="${1:-/mnt/c/Users/vitto/Dropbox/Projects/lagobello-orthophoto/flights}"
DEST_ROOT="${2:-/mnt/c/Users/vitto/Code/lagobello-tiles/kml}"
CONVERTER_SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/convert_tif_to_kml.sh"

printf '[build_latest_orthophoto] Scanning flights in %s …\n' "$FLIGHTS_DIR"
LATEST_FLIGHT_NAME=""
for dir in "$FLIGHTS_DIR"/*/; do
  [ -d "$dir" ] || continue
  name="$(basename "$dir")"
  [[ $name =~ ^[0-9]{8}\  ]] || continue
  [[ -z "$LATEST_FLIGHT_NAME" || "$name" > "$LATEST_FLIGHT_NAME" ]] && LATEST_FLIGHT_NAME="$name"
done

[[ -n "$LATEST_FLIGHT_NAME" ]] || { echo "No flight directories with YYYYMMDD prefix found in $FLIGHTS_DIR" >&2; exit 1; }

SRC_DIR="$FLIGHTS_DIR/$LATEST_FLIGHT_NAME"
printf '[build_latest_orthophoto] Latest flight → %s\n' "$LATEST_FLIGHT_NAME"

# ---- locate GeoTIFF (prefer odm/*.tif) ----
SRC_TIF=""
if [ -d "$SRC_DIR/odm" ]; then
  for tif in "$SRC_DIR"/odm/*.tif; do [ -e "$tif" ] && { SRC_TIF="$tif"; break; } done
fi
if [[ -z "$SRC_TIF" ]]; then
  for tif in "$SRC_DIR"/*.tif; do [ -e "$tif" ] && { SRC_TIF="$tif"; break; } done
fi
[[ -n "$SRC_TIF" ]] || { echo "No .tif found in $SRC_DIR" >&2; exit 1; }

# ---- convert ----
DEST_DIR="$DEST_ROOT/$LATEST_FLIGHT_NAME"
"$CONVERTER_SCRIPT" "$SRC_TIF" "$DEST_DIR" || { echo '[build_latest_orthophoto] 🚫  Conversion failed.' >&2; exit 1; }

# ---- symlink helper ----
ln -sfn "$DEST_DIR/doc.kml" "$DEST_ROOT/latest_doc.kml"

echo '[build_latest_orthophoto] ✅  Finished. Tiles live at' "$DEST_DIR"