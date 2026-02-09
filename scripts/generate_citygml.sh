#!/bin/bash
# Generate a large synthetic CityGML 3.0 dataset with N buildings.
# Usage: generate_citygml.sh [BUILDING_COUNT] [OUTPUT_FILE]
#
# Each building has 4 WallSurfaces + 1 RoofSurface with unique geometry.
# Buildings are placed on a grid to produce spatially distributed data.
set -e

BUILDING_COUNT="${1:-10000}"
OUTPUT_FILE="${2:-/data/synthetic/large_dataset.gml}"

# Grid layout parameters
COLS=100
SPACING=20
BASE_X=458000
BASE_Y=5438000

# Compute envelope bounds
if [ "$BUILDING_COUNT" -le "$COLS" ]; then
  MAX_COL=$((BUILDING_COUNT - 1))
  MAX_ROW=0
else
  MAX_COL=$((COLS - 1))
  MAX_ROW=$(( (BUILDING_COUNT - 1) / COLS ))
fi
ENV_MAX_X=$(( BASE_X + MAX_COL * SPACING + 15 ))
ENV_MAX_Y=$(( BASE_Y + MAX_ROW * SPACING + 15 ))

echo "Generating $BUILDING_COUNT buildings to $OUTPUT_FILE..." >&2

{
  # --- XML Header + Envelope ---
  echo '<?xml version="1.0" encoding="UTF-8"?>
<core:CityModel
  xmlns:core="http://www.opengis.net/citygml/3.0"
  xmlns:bldg="http://www.opengis.net/citygml/building/3.0"
  xmlns:con="http://www.opengis.net/citygml/construction/3.0"
  xmlns:gml="http://www.opengis.net/gml/3.2"
  gml:id="CM_PERF_TEST">
  <gml:boundedBy>
    <gml:Envelope srsName="urn:ogc:def:crs:EPSG::25832" srsDimension="3">
      <gml:lowerCorner>'"$BASE_X"'.0 '"$BASE_Y"'.0 0.0</gml:lowerCorner>
      <gml:upperCorner>'"$ENV_MAX_X"'.0 '"$ENV_MAX_Y"'.0 15.0</gml:upperCorner>
    </gml:Envelope>
  </gml:boundedBy>'

  # --- Generate Buildings ---
  for (( i=0; i<BUILDING_COUNT; i++ )); do
    # Progress reporting to stderr (every 1000 buildings)
    if (( i > 0 && i % 1000 == 0 )); then
      echo "  Progress: $i / $BUILDING_COUNT buildings..." >&2
    fi

    # Grid position
    COL=$(( i % COLS ))
    ROW=$(( i / COLS ))
    X=$(( BASE_X + COL * SPACING ))
    Y=$(( BASE_Y + ROW * SPACING ))

    # Varied dimensions based on index
    W=$(( 8 + i % 5 ))        # 8-12m width
    D=$(( 8 + (i * 3) % 5 ))  # 8-12m depth
    H=$(( 5 + i % 11 ))       # 5-15m height

    XW=$(( X + W ))
    YD=$(( Y + D ))

    # Zero-padded ID (avoids subshell via printf -v)
    printf -v ID "%06d" "$i"

    echo '  <core:cityObjectMember>
    <bldg:Building gml:id="BLDG_PERF_'"$ID"'">
      <gml:name>Performance Test Building '"$ID"'</gml:name>
      <core:boundary>
        <con:WallSurface gml:id="WALL_S_'"$ID"'">
          <core:lod2MultiSurface>
            <gml:MultiSurface>
              <gml:surfaceMember>
                <gml:Polygon gml:id="POLY_WS_'"$ID"'">
                  <gml:exterior>
                    <gml:LinearRing>
                      <gml:posList srsDimension="3">'"$X"'.0 '"$Y"'.0 0.0 '"$XW"'.0 '"$Y"'.0 0.0 '"$XW"'.0 '"$Y"'.0 '"$H"'.0 '"$X"'.0 '"$Y"'.0 '"$H"'.0 '"$X"'.0 '"$Y"'.0 0.0</gml:posList>
                    </gml:LinearRing>
                  </gml:exterior>
                </gml:Polygon>
              </gml:surfaceMember>
            </gml:MultiSurface>
          </core:lod2MultiSurface>
        </con:WallSurface>
      </core:boundary>
      <core:boundary>
        <con:WallSurface gml:id="WALL_N_'"$ID"'">
          <core:lod2MultiSurface>
            <gml:MultiSurface>
              <gml:surfaceMember>
                <gml:Polygon gml:id="POLY_WN_'"$ID"'">
                  <gml:exterior>
                    <gml:LinearRing>
                      <gml:posList srsDimension="3">'"$XW"'.0 '"$YD"'.0 0.0 '"$X"'.0 '"$YD"'.0 0.0 '"$X"'.0 '"$YD"'.0 '"$H"'.0 '"$XW"'.0 '"$YD"'.0 '"$H"'.0 '"$XW"'.0 '"$YD"'.0 0.0</gml:posList>
                    </gml:LinearRing>
                  </gml:exterior>
                </gml:Polygon>
              </gml:surfaceMember>
            </gml:MultiSurface>
          </core:lod2MultiSurface>
        </con:WallSurface>
      </core:boundary>
      <core:boundary>
        <con:WallSurface gml:id="WALL_W_'"$ID"'">
          <core:lod2MultiSurface>
            <gml:MultiSurface>
              <gml:surfaceMember>
                <gml:Polygon gml:id="POLY_WW_'"$ID"'">
                  <gml:exterior>
                    <gml:LinearRing>
                      <gml:posList srsDimension="3">'"$X"'.0 '"$YD"'.0 0.0 '"$X"'.0 '"$Y"'.0 0.0 '"$X"'.0 '"$Y"'.0 '"$H"'.0 '"$X"'.0 '"$YD"'.0 '"$H"'.0 '"$X"'.0 '"$YD"'.0 0.0</gml:posList>
                    </gml:LinearRing>
                  </gml:exterior>
                </gml:Polygon>
              </gml:surfaceMember>
            </gml:MultiSurface>
          </core:lod2MultiSurface>
        </con:WallSurface>
      </core:boundary>
      <core:boundary>
        <con:WallSurface gml:id="WALL_E_'"$ID"'">
          <core:lod2MultiSurface>
            <gml:MultiSurface>
              <gml:surfaceMember>
                <gml:Polygon gml:id="POLY_WE_'"$ID"'">
                  <gml:exterior>
                    <gml:LinearRing>
                      <gml:posList srsDimension="3">'"$XW"'.0 '"$Y"'.0 0.0 '"$XW"'.0 '"$YD"'.0 0.0 '"$XW"'.0 '"$YD"'.0 '"$H"'.0 '"$XW"'.0 '"$Y"'.0 '"$H"'.0 '"$XW"'.0 '"$Y"'.0 0.0</gml:posList>
                    </gml:LinearRing>
                  </gml:exterior>
                </gml:Polygon>
              </gml:surfaceMember>
            </gml:MultiSurface>
          </core:lod2MultiSurface>
        </con:WallSurface>
      </core:boundary>
      <core:boundary>
        <con:RoofSurface gml:id="ROOF_'"$ID"'">
          <core:lod2MultiSurface>
            <gml:MultiSurface>
              <gml:surfaceMember>
                <gml:Polygon gml:id="POLY_RF_'"$ID"'">
                  <gml:exterior>
                    <gml:LinearRing>
                      <gml:posList srsDimension="3">'"$X"'.0 '"$Y"'.0 '"$H"'.0 '"$XW"'.0 '"$Y"'.0 '"$H"'.0 '"$XW"'.0 '"$YD"'.0 '"$H"'.0 '"$X"'.0 '"$YD"'.0 '"$H"'.0 '"$X"'.0 '"$Y"'.0 '"$H"'.0</gml:posList>
                    </gml:LinearRing>
                  </gml:exterior>
                </gml:Polygon>
              </gml:surfaceMember>
            </gml:MultiSurface>
          </core:lod2MultiSurface>
        </con:RoofSurface>
      </core:boundary>
    </bldg:Building>
  </core:cityObjectMember>'
  done

  # --- Close CityModel ---
  echo '</core:CityModel>'

} > "$OUTPUT_FILE"

# Report results
FILE_SIZE=$(stat -c %s "$OUTPUT_FILE" 2>/dev/null || stat -f %z "$OUTPUT_FILE")
FILE_SIZE_MB=$(( FILE_SIZE / 1048576 ))
echo "Generation complete: $BUILDING_COUNT buildings, ${FILE_SIZE_MB} MB ($FILE_SIZE bytes)" >&2
