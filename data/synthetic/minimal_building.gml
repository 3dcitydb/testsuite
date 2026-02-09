<?xml version="1.0" encoding="UTF-8"?>
<core:CityModel
  xmlns:core="http://www.opengis.net/citygml/3.0"
  xmlns:bldg="http://www.opengis.net/citygml/building/3.0"
  xmlns:con="http://www.opengis.net/citygml/construction/3.0"
  xmlns:gml="http://www.opengis.net/gml/3.2"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  gml:id="CM_TEST_001">

  <gml:boundedBy>
    <gml:Envelope srsName="urn:ogc:def:crs:EPSG::25832" srsDimension="3">
      <gml:lowerCorner>458868.0 5438340.0 0.0</gml:lowerCorner>
      <gml:upperCorner>458900.0 5438380.0 12.0</gml:upperCorner>
    </gml:Envelope>
  </gml:boundedBy>

  <core:cityObjectMember>
    <bldg:Building gml:id="BLDG_TEST_001">
      <gml:description>Minimal test building for integration tests</gml:description>
      <gml:name>Test Building 001</gml:name>
      <core:boundary>
        <con:WallSurface gml:id="WALL_TEST_001">
          <core:lod2MultiSurface>
            <gml:MultiSurface>
              <gml:surfaceMember>
                <gml:Polygon gml:id="POLY_WALL_001">
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
          </core:lod2MultiSurface>
        </con:WallSurface>
      </core:boundary>
      <core:boundary>
        <con:RoofSurface gml:id="ROOF_TEST_001">
          <core:lod2MultiSurface>
            <gml:MultiSurface>
              <gml:surfaceMember>
                <gml:Polygon gml:id="POLY_ROOF_001">
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
          </core:lod2MultiSurface>
        </con:RoofSurface>
      </core:boundary>
      <bldg:buildingPart>
        <bldg:BuildingPart gml:id="BLDG_PART_TEST_001">
          <core:boundary>
            <con:WallSurface gml:id="WALL_PART_001">
              <core:lod2MultiSurface>
                <gml:MultiSurface>
                  <gml:surfaceMember>
                    <gml:Polygon gml:id="POLY_WALL_PART_001">
                      <gml:exterior>
                        <gml:LinearRing>
                          <gml:posList srsDimension="3">
                            458882.0 5438350.0 0.0
                            458890.0 5438350.0 0.0
                            458890.0 5438350.0 4.0
                            458882.0 5438350.0 4.0
                            458882.0 5438350.0 0.0
                          </gml:posList>
                        </gml:LinearRing>
                      </gml:exterior>
                    </gml:Polygon>
                  </gml:surfaceMember>
                </gml:MultiSurface>
              </core:lod2MultiSurface>
            </con:WallSurface>
          </core:boundary>
          <core:boundary>
            <con:RoofSurface gml:id="ROOF_PART_001">
              <core:lod2MultiSurface>
                <gml:MultiSurface>
                  <gml:surfaceMember>
                    <gml:Polygon gml:id="POLY_ROOF_PART_001">
                      <gml:exterior>
                        <gml:LinearRing>
                          <gml:posList srsDimension="3">
                            458882.0 5438350.0 4.0
                            458890.0 5438350.0 4.0
                            458886.0 5438355.0 6.0
                            458882.0 5438350.0 4.0
                          </gml:posList>
                        </gml:LinearRing>
                      </gml:exterior>
                    </gml:Polygon>
                  </gml:surfaceMember>
                </gml:MultiSurface>
              </core:lod2MultiSurface>
            </con:RoofSurface>
          </core:boundary>
        </bldg:BuildingPart>
      </bldg:buildingPart>
    </bldg:Building>
  </core:cityObjectMember>

</core:CityModel>
