###############################################
# build_latest_orthophoto.sh
# Detect newest flight directory (YYYYMMDD‑prefixed), locate its GeoTIFF,
# call convert_tif_to_kml.sh to build Google‑Earth tiles, then copy
# doc.kml → latest_doc.kml.
###############################################
#!/usr/bin/env bash
[ -z "$BASH_VERSION" ] && exec /usr/bin/env bash "$0" "$@"
set -euo pipefail
shopt -s nullglob   # empty globs expand to nothing

# -------- Paths --------
FLIGHTS_DIR="${1:-/mnt/c/Users/vitto/Dropbox/Projects/lagobello-orthophoto/flights}"
DEST_ROOT="${2:-/mnt/c/Users/vitto/Code/lagobello-tiles/kml}"
CONVERTER_SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/convert_tif_to_kml.sh"

# Guard against missing converter or self‑recursion
if [[ "$CONVERTER_SCRIPT" == "$0" ]]; then
  echo "ERROR: CONVERTER_SCRIPT resolves to this build script. Check filename/path." >&2
  exit 1
fi
[[ -f "$CONVERTER_SCRIPT" && -x "$CONVERTER_SCRIPT" ]] || { echo "ERROR: Converter script $CONVERTER_SCRIPT not found or not executable" >&2; exit 1; }

# -------- Find latest flight --------
printf '[build_latest_orthophoto] Scanning flights in %s …\n' "$FLIGHTS_DIR"
LATEST=""
for d in "$FLIGHTS_DIR"/*/; do
  base="$(basename "$d")"
  [[ $base =~ ^[0-9]{8}\  ]] || continue  # require YYYYMMDD␠ prefix
  [[ -z "$LATEST" || "$base" > "$LATEST" ]] && LATEST="$base"
done
[[ -n "$LATEST" ]] || { echo "No flight directory found" >&2; exit 1; }
SRC_DIR="$FLIGHTS_DIR/$LATEST"
printf '[build_latest_orthophoto] Latest flight → %s\n' "$LATEST"

# -------- Locate GeoTIFF --------
SRC_TIF=""
if [[ -d "$SRC_DIR/odm" ]]; then
  for f in "$SRC_DIR"/odm/*.tif; do SRC_TIF="$f"; break; done
fi
if [[ -z "$SRC_TIF" ]]; then
  for f in "$SRC_DIR"/*.tif; do SRC_TIF="$f"; break; done
fi
[[ -n "$SRC_TIF" ]] || { echo "No .tif found in $SRC_DIR" >&2; exit 1; }
printf '[build_latest_orthophoto] Found GeoTIFF → %s\n' "$SRC_TIF"

# -------- Convert --------
printf '[build_latest_orthophoto] Using converter → %s
' "$CONVERTER_SCRIPT"
DEST_DIR="$DEST_ROOT/$LATEST"

"$CONVERTER_SCRIPT" "$SRC_TIF" "$DEST_DIR" || { echo "ERROR: Converter exited with status $?" >&2; exit 1; }
