<?xml version="1.0" encoding="UTF-8"?>
<!-- Deterministic CityGML 3.0 dataset for spatial CQL2 filter tests.
     6 buildings + 1 road = 7 features, local origin O = (460000, 5439000),
     EPSG:25832; all coordinates below are offsets from O (x, y).
     SP_L          L-shape (0,0)-(20,0)-(20,10)-(10,10)-(10,20)-(0,20), h 10
                   -> envelope 0..20 x 0..20 covers the notch 10..20 x 10..20
     SP_NEIGHBOR   10 x 10 square 20..30 x 0..10, h 6; shares the edge
                   x = 20, y 0..10 with SP_L
     SP_COURTYARD  30 x 30 square 40..70 x 0..30 with courtyard (hole)
                   50..60 x 10..20, h 15
     SP_TWIN       two parts 100..110 x 0..10 and 130..140 x 0..10, h 8
                   -> envelope 100..140 x 0..10 covers the gap
     SP_TOWER      200..210 x 200..210, h 100
     SP_FAR        1000..1010 x 1000..1010, h 5 (about 1414 m from O)
     SP_ROAD       strip -10..150 x -8..-4 (south of all buildings)
     Generic attributes: kind (residential: L, NEIGHBOR, FAR; office:
     COURTYARD, TWIN, TOWER), storeys (3, 2, 5, 2, 30, 1). -->
<core:CityModel
  xmlns:core="http://www.opengis.net/citygml/3.0"
  xmlns:bldg="http://www.opengis.net/citygml/building/3.0"
  xmlns:tran="http://www.opengis.net/citygml/transportation/3.0"
  xmlns:gen="http://www.opengis.net/citygml/generics/3.0"
  xmlns:gml="http://www.opengis.net/gml/3.2"
  gml:id="CM_SPATIAL_001">

  <gml:boundedBy>
    <gml:Envelope srsName="urn:ogc:def:crs:EPSG::25832" srsDimension="3">
      <gml:lowerCorner>459990.0 5438992.0 0.0</gml:lowerCorner>
      <gml:upperCorner>461010.0 5440010.0 100.0</gml:upperCorner>
    </gml:Envelope>
  </gml:boundedBy>

  <core:cityObjectMember>
    <bldg:Building gml:id="SP_L">
      <gml:name>L-shaped building</gml:name>
      <core:genericAttribute>
        <gen:StringAttribute>
          <gen:name>kind</gen:name>
          <gen:value>residential</gen:value>
        </gen:StringAttribute>
      </core:genericAttribute>
      <core:genericAttribute>
        <gen:IntAttribute>
          <gen:name>storeys</gen:name>
          <gen:value>3</gen:value>
        </gen:IntAttribute>
      </core:genericAttribute>
      <core:lod2MultiSurface>
        <gml:MultiSurface gml:id="MS_SP_L">
          <gml:surfaceMember>
            <gml:Polygon gml:id="POLY_SP_L_BASE_1">
              <gml:exterior>
                <gml:LinearRing>
                  <gml:posList srsDimension="3">460000.0 5439000.0 0.0 460020.0 5439000.0 0.0 460020.0 5439010.0 0.0 460010.0 5439010.0 0.0 460010.0 5439020.0 0.0 460000.0 5439020.0 0.0 460000.0 5439000.0 0.0</gml:posList>
                </gml:LinearRing>
              </gml:exterior>
            </gml:Polygon>
          </gml:surfaceMember>
          <gml:surfaceMember>
            <gml:Polygon gml:id="POLY_SP_L_ROOF_1">
              <gml:exterior>
                <gml:LinearRing>
                  <gml:posList srsDimension="3">460000.0 5439000.0 10.0 460020.0 5439000.0 10.0 460020.0 5439010.0 10.0 460010.0 5439010.0 10.0 460010.0 5439020.0 10.0 460000.0 5439020.0 10.0 460000.0 5439000.0 10.0</gml:posList>
                </gml:LinearRing>
              </gml:exterior>
            </gml:Polygon>
          </gml:surfaceMember>
        </gml:MultiSurface>
      </core:lod2MultiSurface>
    </bldg:Building>
  </core:cityObjectMember>

  <core:cityObjectMember>
    <bldg:Building gml:id="SP_NEIGHBOR">
      <gml:name>Neighbor building</gml:name>
      <core:genericAttribute>
        <gen:StringAttribute>
          <gen:name>kind</gen:name>
          <gen:value>residential</gen:value>
        </gen:StringAttribute>
      </core:genericAttribute>
      <core:genericAttribute>
        <gen:IntAttribute>
          <gen:name>storeys</gen:name>
          <gen:value>2</gen:value>
        </gen:IntAttribute>
      </core:genericAttribute>
      <core:lod2MultiSurface>
        <gml:MultiSurface gml:id="MS_SP_NEIGHBOR">
          <gml:surfaceMember>
            <gml:Polygon gml:id="POLY_SP_NEIGHBOR_BASE_1">
              <gml:exterior>
                <gml:LinearRing>
                  <gml:posList srsDimension="3">460020.0 5439000.0 0.0 460030.0 5439000.0 0.0 460030.0 5439010.0 0.0 460020.0 5439010.0 0.0 460020.0 5439000.0 0.0</gml:posList>
                </gml:LinearRing>
              </gml:exterior>
            </gml:Polygon>
          </gml:surfaceMember>
          <gml:surfaceMember>
            <gml:Polygon gml:id="POLY_SP_NEIGHBOR_ROOF_1">
              <gml:exterior>
                <gml:LinearRing>
                  <gml:posList srsDimension="3">460020.0 5439000.0 6.0 460030.0 5439000.0 6.0 460030.0 5439010.0 6.0 460020.0 5439010.0 6.0 460020.0 5439000.0 6.0</gml:posList>
                </gml:LinearRing>
              </gml:exterior>
            </gml:Polygon>
          </gml:surfaceMember>
        </gml:MultiSurface>
      </core:lod2MultiSurface>
    </bldg:Building>
  </core:cityObjectMember>

  <core:cityObjectMember>
    <bldg:Building gml:id="SP_COURTYARD">
      <gml:name>Courtyard building</gml:name>
      <core:genericAttribute>
        <gen:StringAttribute>
          <gen:name>kind</gen:name>
          <gen:value>office</gen:value>
        </gen:StringAttribute>
      </core:genericAttribute>
      <core:genericAttribute>
        <gen:IntAttribute>
          <gen:name>storeys</gen:name>
          <gen:value>5</gen:value>
        </gen:IntAttribute>
      </core:genericAttribute>
      <core:lod2MultiSurface>
        <gml:MultiSurface gml:id="MS_SP_COURTYARD">
          <gml:surfaceMember>
            <gml:Polygon gml:id="POLY_SP_COURTYARD_BASE_1">
              <gml:exterior>
                <gml:LinearRing>
                  <gml:posList srsDimension="3">460040.0 5439000.0 0.0 460070.0 5439000.0 0.0 460070.0 5439030.0 0.0 460040.0 5439030.0 0.0 460040.0 5439000.0 0.0</gml:posList>
                </gml:LinearRing>
              </gml:exterior>
              <gml:interior>
                <gml:LinearRing>
                  <gml:posList srsDimension="3">460050.0 5439010.0 0.0 460060.0 5439010.0 0.0 460060.0 5439020.0 0.0 460050.0 5439020.0 0.0 460050.0 5439010.0 0.0</gml:posList>
                </gml:LinearRing>
              </gml:interior>
            </gml:Polygon>
          </gml:surfaceMember>
          <gml:surfaceMember>
            <gml:Polygon gml:id="POLY_SP_COURTYARD_ROOF_1">
              <gml:exterior>
                <gml:LinearRing>
                  <gml:posList srsDimension="3">460040.0 5439000.0 15.0 460070.0 5439000.0 15.0 460070.0 5439030.0 15.0 460040.0 5439030.0 15.0 460040.0 5439000.0 15.0</gml:posList>
                </gml:LinearRing>
              </gml:exterior>
              <gml:interior>
                <gml:LinearRing>
                  <gml:posList srsDimension="3">460050.0 5439010.0 15.0 460060.0 5439010.0 15.0 460060.0 5439020.0 15.0 460050.0 5439020.0 15.0 460050.0 5439010.0 15.0</gml:posList>
                </gml:LinearRing>
              </gml:interior>
            </gml:Polygon>
          </gml:surfaceMember>
        </gml:MultiSurface>
      </core:lod2MultiSurface>
    </bldg:Building>
  </core:cityObjectMember>

  <core:cityObjectMember>
    <bldg:Building gml:id="SP_TWIN">
      <gml:name>Twin building</gml:name>
      <core:genericAttribute>
        <gen:StringAttribute>
          <gen:name>kind</gen:name>
          <gen:value>office</gen:value>
        </gen:StringAttribute>
      </core:genericAttribute>
      <core:genericAttribute>
        <gen:IntAttribute>
          <gen:name>storeys</gen:name>
          <gen:value>2</gen:value>
        </gen:IntAttribute>
      </core:genericAttribute>
      <core:lod2MultiSurface>
        <gml:MultiSurface gml:id="MS_SP_TWIN">
          <gml:surfaceMember>
            <gml:Polygon gml:id="POLY_SP_TWIN_BASE_1">
              <gml:exterior>
                <gml:LinearRing>
                  <gml:posList srsDimension="3">460100.0 5439000.0 0.0 460110.0 5439000.0 0.0 460110.0 5439010.0 0.0 460100.0 5439010.0 0.0 460100.0 5439000.0 0.0</gml:posList>
                </gml:LinearRing>
              </gml:exterior>
            </gml:Polygon>
          </gml:surfaceMember>
          <gml:surfaceMember>
            <gml:Polygon gml:id="POLY_SP_TWIN_ROOF_1">
              <gml:exterior>
                <gml:LinearRing>
                  <gml:posList srsDimension="3">460100.0 5439000.0 8.0 460110.0 5439000.0 8.0 460110.0 5439010.0 8.0 460100.0 5439010.0 8.0 460100.0 5439000.0 8.0</gml:posList>
                </gml:LinearRing>
              </gml:exterior>
            </gml:Polygon>
          </gml:surfaceMember>
          <gml:surfaceMember>
            <gml:Polygon gml:id="POLY_SP_TWIN_BASE_2">
              <gml:exterior>
                <gml:LinearRing>
                  <gml:posList srsDimension="3">460130.0 5439000.0 0.0 460140.0 5439000.0 0.0 460140.0 5439010.0 0.0 460130.0 5439010.0 0.0 460130.0 5439000.0 0.0</gml:posList>
                </gml:LinearRing>
              </gml:exterior>
            </gml:Polygon>
          </gml:surfaceMember>
          <gml:surfaceMember>
            <gml:Polygon gml:id="POLY_SP_TWIN_ROOF_2">
              <gml:exterior>
                <gml:LinearRing>
                  <gml:posList srsDimension="3">460130.0 5439000.0 8.0 460140.0 5439000.0 8.0 460140.0 5439010.0 8.0 460130.0 5439010.0 8.0 460130.0 5439000.0 8.0</gml:posList>
                </gml:LinearRing>
              </gml:exterior>
            </gml:Polygon>
          </gml:surfaceMember>
        </gml:MultiSurface>
      </core:lod2MultiSurface>
    </bldg:Building>
  </core:cityObjectMember>

  <core:cityObjectMember>
    <bldg:Building gml:id="SP_TOWER">
      <gml:name>Tower</gml:name>
      <core:genericAttribute>
        <gen:StringAttribute>
          <gen:name>kind</gen:name>
          <gen:value>office</gen:value>
        </gen:StringAttribute>
      </core:genericAttribute>
      <core:genericAttribute>
        <gen:IntAttribute>
          <gen:name>storeys</gen:name>
          <gen:value>30</gen:value>
        </gen:IntAttribute>
      </core:genericAttribute>
      <core:lod2MultiSurface>
        <gml:MultiSurface gml:id="MS_SP_TOWER">
          <gml:surfaceMember>
            <gml:Polygon gml:id="POLY_SP_TOWER_BASE_1">
              <gml:exterior>
                <gml:LinearRing>
                  <gml:posList srsDimension="3">460200.0 5439200.0 0.0 460210.0 5439200.0 0.0 460210.0 5439210.0 0.0 460200.0 5439210.0 0.0 460200.0 5439200.0 0.0</gml:posList>
                </gml:LinearRing>
              </gml:exterior>
            </gml:Polygon>
          </gml:surfaceMember>
          <gml:surfaceMember>
            <gml:Polygon gml:id="POLY_SP_TOWER_ROOF_1">
              <gml:exterior>
                <gml:LinearRing>
                  <gml:posList srsDimension="3">460200.0 5439200.0 100.0 460210.0 5439200.0 100.0 460210.0 5439210.0 100.0 460200.0 5439210.0 100.0 460200.0 5439200.0 100.0</gml:posList>
                </gml:LinearRing>
              </gml:exterior>
            </gml:Polygon>
          </gml:surfaceMember>
        </gml:MultiSurface>
      </core:lod2MultiSurface>
    </bldg:Building>
  </core:cityObjectMember>

  <core:cityObjectMember>
    <bldg:Building gml:id="SP_FAR">
      <gml:name>Far building</gml:name>
      <core:genericAttribute>
        <gen:StringAttribute>
          <gen:name>kind</gen:name>
          <gen:value>residential</gen:value>
        </gen:StringAttribute>
      </core:genericAttribute>
      <core:genericAttribute>
        <gen:IntAttribute>
          <gen:name>storeys</gen:name>
          <gen:value>1</gen:value>
        </gen:IntAttribute>
      </core:genericAttribute>
      <core:lod2MultiSurface>
        <gml:MultiSurface gml:id="MS_SP_FAR">
          <gml:surfaceMember>
            <gml:Polygon gml:id="POLY_SP_FAR_BASE_1">
              <gml:exterior>
                <gml:LinearRing>
                  <gml:posList srsDimension="3">461000.0 5440000.0 0.0 461010.0 5440000.0 0.0 461010.0 5440010.0 0.0 461000.0 5440010.0 0.0 461000.0 5440000.0 0.0</gml:posList>
                </gml:LinearRing>
              </gml:exterior>
            </gml:Polygon>
          </gml:surfaceMember>
          <gml:surfaceMember>
            <gml:Polygon gml:id="POLY_SP_FAR_ROOF_1">
              <gml:exterior>
                <gml:LinearRing>
                  <gml:posList srsDimension="3">461000.0 5440000.0 5.0 461010.0 5440000.0 5.0 461010.0 5440010.0 5.0 461000.0 5440010.0 5.0 461000.0 5440000.0 5.0</gml:posList>
                </gml:LinearRing>
              </gml:exterior>
            </gml:Polygon>
          </gml:surfaceMember>
        </gml:MultiSurface>
      </core:lod2MultiSurface>
    </bldg:Building>
  </core:cityObjectMember>

  <core:cityObjectMember>
    <tran:Road gml:id="SP_ROAD">
      <gml:name>Road south</gml:name>
      <core:lod2MultiSurface>
        <gml:MultiSurface gml:id="MS_SP_ROAD">
          <gml:surfaceMember>
            <gml:Polygon gml:id="POLY_SP_ROAD">
              <gml:exterior>
                <gml:LinearRing>
                  <gml:posList srsDimension="3">459990.0 5438992.0 0.0 460150.0 5438992.0 0.0 460150.0 5438996.0 0.0 459990.0 5438996.0 0.0 459990.0 5438992.0 0.0</gml:posList>
                </gml:LinearRing>
              </gml:exterior>
            </gml:Polygon>
          </gml:surfaceMember>
        </gml:MultiSurface>
      </core:lod2MultiSurface>
    </tran:Road>
  </core:cityObjectMember>

</core:CityModel>
