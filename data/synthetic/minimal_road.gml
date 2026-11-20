<?xml version="1.0" encoding="UTF-8"?>
<core:CityModel
  xmlns:core="http://www.opengis.net/citygml/3.0"
  xmlns:tran="http://www.opengis.net/citygml/transportation/3.0"
  xmlns:gml="http://www.opengis.net/gml/3.2"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  gml:id="CM_ROAD_001">

  <gml:boundedBy>
    <gml:Envelope srsName="urn:ogc:def:crs:EPSG::25832" srsDimension="3">
      <gml:lowerCorner>458850.0 5438340.0 0.0</gml:lowerCorner>
      <gml:upperCorner>458950.0 5438360.0 1.0</gml:upperCorner>
    </gml:Envelope>
  </gml:boundedBy>

  <core:cityObjectMember>
    <tran:Road gml:id="ROAD_TEST_001">
      <gml:description>Minimal test road for integration tests</gml:description>
      <gml:name>Test Road 001</gml:name>
      <tran:trafficSpace>
        <tran:TrafficSpace gml:id="TS_TEST_001">
          <core:boundary>
            <tran:TrafficArea gml:id="TA_TEST_001">
              <core:lod2MultiSurface>
                <gml:MultiSurface>
                  <gml:surfaceMember>
                    <gml:Polygon gml:id="POLY_ROAD_001">
                      <gml:exterior>
                        <gml:LinearRing>
                          <gml:posList srsDimension="3">
                            458860.0 5438345.0 0.0
                            458940.0 5438345.0 0.0
                            458940.0 5438355.0 0.0
                            458860.0 5438355.0 0.0
                            458860.0 5438345.0 0.0
                          </gml:posList>
                        </gml:LinearRing>
                      </gml:exterior>
                    </gml:Polygon>
                  </gml:surfaceMember>
                </gml:MultiSurface>
              </core:lod2MultiSurface>
            </tran:TrafficArea>
          </core:boundary>
          <tran:granularity>way</tran:granularity>
        </tran:TrafficSpace>
      </tran:trafficSpace>
    </tran:Road>
  </core:cityObjectMember>

</core:CityModel>
