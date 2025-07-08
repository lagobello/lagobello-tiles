###############################################
# convert_tif_to_kml.sh
# Convert a GeoTIFF into a Google‑Earth super‑overlay (doc.kml + tiles).
# • Always forces the -k flag.
# • Works directly in DEST_DIR: reprojected.tif + tiles are written there.
# • Handles spaces in paths via proper quoting.
#
# Usage:
#   TILEDRIVER=PNG  ZOOM=0-18  ./convert_tif_to_kml.sh <source.tif> <dest_dir>
# Defaults: TILEDRIVER=JPEG  ZOOM=auto
###############################################
#!/usr/bin/env bash
[ -z "$BASH_VERSION" ] && exec /usr/bin/env bash "$0" "$@"
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <source.tif> <dest_dir>" >&2
  exit 1
fi

SRC_TIF="$1"
DEST_DIR="$2"
mkdir -p "$DEST_DIR"

TILEDRIVER="${TILEDRIVER:-JPEG}"   # PNG or JPEG (WEBP if GDAL supports)
ZOOM="${ZOOM:-auto}"               # e.g. 0-18, 12-18, or auto

# ---------- Dependency checks ----------
command -v gdalwarp >/dev/null 2>&1 || { echo 'ERROR: gdalwarp not in PATH.' >&2; exit 1; }
GDAL2TILES=$(command -v gdal2tiles.py || command -v gdal2tiles || true)
[[ -n "$GDAL2TILES" ]] || { echo 'ERROR: gdal2tiles(.py) not found in PATH.' >&2; exit 1; }

echo "[convert_tif_to_kml] Using gdal2tiles → $GDAL2TILES"

# ---------- Reprojection ----------
# Create a temporary file *inside* DEST_DIR so input & output live on same FS
REPROJ_TIF=$(mktemp --suffix=.tif -p "$DEST_DIR" reprojected.XXXXXX)
trap 'rm -f "$REPROJ_TIF"' EXIT

echo "[convert_tif_to_kml] Reprojecting to EPSG:4326 → $REPROJ_TIF …"
gdalwarp -multi -wo NUM_THREADS=ALL_CPUS -t_srs EPSG:4326 "$SRC_TIF" "$REPROJ_TIF"

# ---------- Tile generation ----------
echo "[convert_tif_to_kml] Generating tiles in $DEST_DIR …"
CMD=("$GDAL2TILES" -p geodetic -k)
[[ "$TILEDRIVER" != JPEG ]] && CMD+=("--tiledriver=$TILEDRIVER")
[[ "$ZOOM" != auto ]] && CMD+=( -z "$ZOOM" )
CMD+=( "$REPROJ_TIF" "$DEST_DIR" )

# Execute with proper quoting
"${CMD[@]}"

# ---------- Cleanup ----------
rm -f "$REPROJ_TIF"
echo "[convert_tif_to_kml] ✅  Complete. Root KML → $DEST_DIR/doc.kml"
