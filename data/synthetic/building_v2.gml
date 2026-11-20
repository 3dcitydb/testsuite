<?xml version="1.0" encoding="UTF-8"?>
<CityModel
  xmlns="http://www.opengis.net/citygml/2.0"
  xmlns:bldg="http://www.opengis.net/citygml/building/2.0"
  xmlns:gml="http://www.opengis.net/gml"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://www.opengis.net/citygml/2.0 http://schemas.opengis.net/citygml/2.0/cityGMLBase.xsd
    http://www.opengis.net/citygml/building/2.0 http://schemas.opengis.net/citygml/building/2.0/building.xsd"
  gml:id="CM_V2_001">

  <gml:boundedBy>
    <gml:Envelope srsName="urn:ogc:def:crs:EPSG::25832" srsDimension="3">
      <gml:lowerCorner>458868.0 5438340.0 0.0</gml:lowerCorner>
      <gml:upperCorner>458900.0 5438380.0 12.0</gml:upperCorner>
    </gml:Envelope>
  </gml:boundedBy>

  <cityObjectMember>
    <bldg:Building gml:id="BLDG_V2_001">
      <gml:description>CityGML 2.0 test building</gml:description>
      <gml:name>Test Building V2</gml:name>
      <bldg:boundedBy>
        <bldg:WallSurface gml:id="WALL_V2_001">
          <bldg:lod2MultiSurface>
            <gml:MultiSurface>
              <gml:surfaceMember>
                <gml:Polygon gml:id="POLY_WALL_V2_001">
                  <gml:exterior>
                    <gml:LinearRing>
                      <gml:posList srsDimension="3">
                        458870.0 5438350.0 0.0
                        458880.0 5438350.0 0.0
                        458880.0 5438350.0 6.0
                        458870.0 5438350.0 6.0
                        458870.0 5438350.0 0.0
                      </gml:posList>
                    </gml:LinearRing>
                  </gml:exterior>
                </gml:Polygon>
              </gml:surfaceMember>
            </gml:MultiSurface>
          </bldg:lod2MultiSurface>
        </bldg:WallSurface>
      </bldg:boundedBy>
      <bldg:boundedBy>
        <bldg:RoofSurface gml:id="ROOF_V2_001">
          <bldg:lod2MultiSurface>
            <gml:MultiSurface>
              <gml:surfaceMember>
                <gml:Polygon gml:id="POLY_ROOF_V2_001">
                  <gml:exterior>
                    <gml:LinearRing>
                      <gml:posList srsDimension="3">
                        458870.0 5438350.0 6.0
                        458880.0 5438350.0 6.0
                        458875.0 5438350.0 9.0
                        458870.0 5438350.0 6.0
                      </gml:posList>
                    </gml:LinearRing>
                  </gml:exterior>
                </gml:Polygon>
              </gml:surfaceMember>
            </gml:MultiSurface>
          </bldg:lod2MultiSurface>
        </bldg:RoofSurface>
      </bldg:boundedBy>
    </bldg:Building>
  </cityObjectMember>

</CityModel>
