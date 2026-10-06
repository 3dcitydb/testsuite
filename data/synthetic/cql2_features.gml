<?xml version="1.0" encoding="UTF-8"?>
<!-- Deterministic CityGML 3.0 dataset for CQL2 filter tests.
     8 buildings + 2 roads = 10 features (no nested sub-features).
     West cluster: BLDG_CQL2_01..04 + ROAD_CQL2_01 (x 458785..458855)
     East cluster: BLDG_CQL2_05..08 + ROAD_CQL2_02 (x 459035..459105)
     con:height value = storeys * 3.5; owner missing on B06..B08;
     bldg:function multi-valued (1010, 2000) on B07/B08.
     bldg:storeysAboveGround = storeys; bldg:roofType 1000 on B01..B04,
     3100/3200/3300 on B05..B07, 2100 on B08.
     bldg:address on B01..B03 (Karlsruhe) and B05 (Ettlingen);
     street Kaiser* on B01, B02, B05.
     Typed generic attributes on all buildings: area (double, n*100+0.5),
     constructionDate (date, 19(n+1)0-06-15), volume (measure, n*1000 m3),
     usageCode (code, A on B01..B04, B on B05..B06, C on B07..B08),
     Gemeindeschlüssel (08212000 on B01..B04, 08215017 on B05..B08);
     website (uri) on B01..B04; architect on B03 (O'Brien & Partner)
     and B04 (Müller-Lüdenscheidt); attribute set energy (rating = n,
     label = E0n) on B01..B03. -->
<core:CityModel
  xmlns:core="http://www.opengis.net/citygml/3.0"
  xmlns:bldg="http://www.opengis.net/citygml/building/3.0"
  xmlns:con="http://www.opengis.net/citygml/construction/3.0"
  xmlns:tran="http://www.opengis.net/citygml/transportation/3.0"
  xmlns:gen="http://www.opengis.net/citygml/generics/3.0"
  xmlns:gml="http://www.opengis.net/gml/3.2"
  xmlns:xAL="urn:oasis:names:tc:ciq:xal:3"
  gml:id="CM_CQL2_001">

  <gml:boundedBy>
    <gml:Envelope srsName="urn:ogc:def:crs:EPSG::25832" srsDimension="3">
      <gml:lowerCorner>458785.0 5438340.0 0.0</gml:lowerCorner>
      <gml:upperCorner>459105.0 5438362.5 28.0</gml:upperCorner>
    </gml:Envelope>
  </gml:boundedBy>

  <core:cityObjectMember>
    <bldg:Building gml:id="BLDG_CQL2_01">
      <gml:name>Building 01</gml:name>
      <core:genericAttribute>
        <gen:IntAttribute>
          <gen:name>storeys</gen:name>
          <gen:value>1</gen:value>
        </gen:IntAttribute>
      </core:genericAttribute>
      <core:genericAttribute>
        <gen:StringAttribute>
          <gen:name>district</gen:name>
          <gen:value>Mitte</gen:value>
        </gen:StringAttribute>
      </core:genericAttribute>
      <core:genericAttribute>
        <gen:StringAttribute>
          <gen:name>owner</gen:name>
          <gen:value>Owner A</gen:value>
        </gen:StringAttribute>
      </core:genericAttribute>
      <core:genericAttribute>
        <gen:StringAttribute>
          <gen:name>street</gen:name>
          <gen:value>Münchner Straße</gen:value>
        </gen:StringAttribute>
      </core:genericAttribute>
      <core:genericAttribute>
        <gen:DoubleAttribute>
          <gen:name>area</gen:name>
          <gen:value>100.5</gen:value>
        </gen:DoubleAttribute>
      </core:genericAttribute>
      <core:genericAttribute>
        <gen:DateAttribute>
          <gen:name>constructionDate</gen:name>
          <gen:value>1920-06-15</gen:value>
        </gen:DateAttribute>
      </core:genericAttribute>
      <core:genericAttribute>
        <gen:UriAttribute>
          <gen:name>website</gen:name>
          <gen:value>https://example.org/buildings/01</gen:value>
        </gen:UriAttribute>
      </core:genericAttribute>
      <core:genericAttribute>
        <gen:MeasureAttribute>
          <gen:name>volume</gen:name>
          <gen:value uom="m3">1000</gen:value>
        </gen:MeasureAttribute>
      </core:genericAttribute>
      <core:genericAttribute>
        <gen:CodeAttribute>
          <gen:name>usageCode</gen:name>
          <gen:value codeSpace="https://example.org/codes/usage">A</gen:value>
        </gen:CodeAttribute>
      </core:genericAttribute>
      <core:genericAttribute>
        <gen:StringAttribute>
          <gen:name>Gemeindeschlüssel</gen:name>
          <gen:value>08212000</gen:value>
        </gen:StringAttribute>
      </core:genericAttribute>
      <core:genericAttribute>
        <gen:GenericAttributeSet>
          <gen:name>energy</gen:name>
          <gen:genericAttribute>
            <gen:IntAttribute>
              <gen:name>rating</gen:name>
              <gen:value>1</gen:value>
            </gen:IntAttribute>
          </gen:genericAttribute>
          <gen:genericAttribute>
            <gen:StringAttribute>
              <gen:name>label</gen:name>
              <gen:value>E01</gen:value>
            </gen:StringAttribute>
          </gen:genericAttribute>
        </gen:GenericAttributeSet>
      </core:genericAttribute>
      <core:lod2MultiSurface>
        <gml:MultiSurface gml:id="MS_BLDG_CQL2_01">
          <gml:surfaceMember>
            <gml:Polygon gml:id="POLY_B01_BASE">
              <gml:exterior>
                <gml:LinearRing>
                  <gml:posList srsDimension="3">458790.0 5438340.0 0.0 458790.0 5438350.0 0.0 458800.0 5438350.0 0.0 458800.0 5438340.0 0.0 458790.0 5438340.0 0.0</gml:posList>
                </gml:LinearRing>
              </gml:exterior>
            </gml:Polygon>
          </gml:surfaceMember>
          <gml:surfaceMember>
            <gml:Polygon gml:id="POLY_B01_ROOF">
              <gml:exterior>
                <gml:LinearRing>
                  <gml:posList srsDimension="3">458790.0 5438340.0 3.5 458800.0 5438340.0 3.5 458800.0 5438350.0 3.5 458790.0 5438350.0 3.5 458790.0 5438340.0 3.5</gml:posList>
                </gml:LinearRing>
              </gml:exterior>
            </gml:Polygon>
          </gml:surfaceMember>
        </gml:MultiSurface>
      </core:lod2MultiSurface>
      <con:height>
        <con:Height>
          <con:highReference>highestRoofEdge</con:highReference>
          <con:lowReference>lowestGroundPoint</con:lowReference>
          <con:status>measured</con:status>
          <con:value uom="m">3.5</con:value>
        </con:Height>
      </con:height>
      <bldg:function codeSpace="https://www.sig3d.org/codelists/citygml/3.0/building/3.0/_AbstractBuilding_function.xml">1000</bldg:function>
      <bldg:roofType codeSpace="https://www.sig3d.org/codelists/citygml/3.0/building/3.0/_AbstractBuilding_roofType.xml">1000</bldg:roofType>
      <bldg:storeysAboveGround>1</bldg:storeysAboveGround>
      <bldg:address>
        <core:Address gml:id="ADDR_CQL2_01">
          <core:xalAddress>
            <xAL:Address>
              <xAL:Locality xAL:Type="Town">
                <xAL:NameElement xAL:NameType="Name">Karlsruhe</xAL:NameElement>
              </xAL:Locality>
              <xAL:Thoroughfare xAL:Type="Street">
                <xAL:NameElement xAL:NameType="NameAndType">Kaiserstraße</xAL:NameElement>
                <xAL:Number xAL:Type="Number">12</xAL:Number>
              </xAL:Thoroughfare>
              <xAL:PostCode>
                <xAL:Identifier>76133</xAL:Identifier>
              </xAL:PostCode>
            </xAL:Address>
          </core:xalAddress>
        </core:Address>
      </bldg:address>
    </bldg:Building>
  </core:cityObjectMember>

  <core:cityObjectMember>
    <bldg:Building gml:id="BLDG_CQL2_02">
      <gml:name>Building 02</gml:name>
      <core:genericAttribute>
        <gen:IntAttribute>
          <gen:name>storeys</gen:name>
          <gen:value>2</gen:value>
        </gen:IntAttribute>
      </core:genericAttribute>
      <core:genericAttribute>
        <gen:StringAttribute>
          <gen:name>district</gen:name>
          <gen:value>Mitte</gen:value>
        </gen:StringAttribute>
      </core:genericAttribute>
      <core:genericAttribute>
        <gen:StringAttribute>
          <gen:name>owner</gen:name>
          <gen:value>Owner B</gen:value>
        </gen:StringAttribute>
      </core:genericAttribute>
      <core:genericAttribute>
        <gen:DoubleAttribute>
          <gen:name>area</gen:name>
          <gen:value>200.5</gen:value>
        </gen:DoubleAttribute>
      </core:genericAttribute>
      <core:genericAttribute>
        <gen:DateAttribute>
          <gen:name>constructionDate</gen:name>
          <gen:value>1930-06-15</gen:value>
        </gen:DateAttribute>
      </core:genericAttribute>
      <core:genericAttribute>
        <gen:UriAttribute>
          <gen:name>website</gen:name>
          <gen:value>https://example.org/buildings/02</gen:value>
        </gen:UriAttribute>
      </core:genericAttribute>
      <core:genericAttribute>
        <gen:MeasureAttribute>
          <gen:name>volume</gen:name>
          <gen:value uom="m3">2000</gen:value>
        </gen:MeasureAttribute>
      </core:genericAttribute>
      <core:genericAttribute>
        <gen:CodeAttribute>
          <gen:name>usageCode</gen:name>
          <gen:value codeSpace="https://example.org/codes/usage">A</gen:value>
        </gen:CodeAttribute>
      </core:genericAttribute>
      <core:genericAttribute>
        <gen:StringAttribute>
          <gen:name>Gemeindeschlüssel</gen:name>
          <gen:value>08212000</gen:value>
        </gen:StringAttribute>
      </core:genericAttribute>
      <core:genericAttribute>
        <gen:GenericAttributeSet>
          <gen:name>energy</gen:name>
          <gen:genericAttribute>
            <gen:IntAttribute>
              <gen:name>rating</gen:name>
              <gen:value>2</gen:value>
            </gen:IntAttribute>
          </gen:genericAttribute>
          <gen:genericAttribute>
            <gen:StringAttribute>
              <gen:name>label</gen:name>
              <gen:value>E02</gen:value>
            </gen:StringAttribute>
          </gen:genericAttribute>
        </gen:GenericAttributeSet>
      </core:genericAttribute>
      <core:lod2MultiSurface>
        <gml:MultiSurface gml:id="MS_BLDG_CQL2_02">
          <gml:surfaceMember>
            <gml:Polygon gml:id="POLY_B02_BASE">
              <gml:exterior>
                <gml:LinearRing>
                  <gml:posList srsDimension="3">458805.0 5438340.0 0.0 458805.0 5438350.0 0.0 458815.0 5438350.0 0.0 458815.0 5438340.0 0.0 458805.0 5438340.0 0.0</gml:posList>
                </gml:LinearRing>
              </gml:exterior>
            </gml:Polygon>
          </gml:surfaceMember>
          <gml:surfaceMember>
            <gml:Polygon gml:id="POLY_B02_ROOF">
              <gml:exterior>
                <gml:LinearRing>
                  <gml:posList srsDimension="3">458805.0 5438340.0 7.0 458815.0 5438340.0 7.0 458815.0 5438350.0 7.0 458805.0 5438350.0 7.0 458805.0 5438340.0 7.0</gml:posList>
                </gml:LinearRing>
              </gml:exterior>
            </gml:Polygon>
          </gml:surfaceMember>
        </gml:MultiSurface>
      </core:lod2MultiSurface>
      <con:height>
        <con:Height>
          <con:highReference>highestRoofEdge</con:highReference>
          <con:lowReference>lowestGroundPoint</con:lowReference>
          <con:status>measured</con:status>
          <con:value uom="m">7.0</con:value>
        </con:Height>
      </con:height>
      <bldg:function codeSpace="https://www.sig3d.org/codelists/citygml/3.0/building/3.0/_AbstractBuilding_function.xml">1000</bldg:function>
      <bldg:roofType codeSpace="https://www.sig3d.org/codelists/citygml/3.0/building/3.0/_AbstractBuilding_roofType.xml">1000</bldg:roofType>
      <bldg:storeysAboveGround>2</bldg:storeysAboveGround>
      <bldg:address>
        <core:Address gml:id="ADDR_CQL2_02">
          <core:xalAddress>
            <xAL:Address>
              <xAL:Locality xAL:Type="Town">
                <xAL:NameElement xAL:NameType="Name">Karlsruhe</xAL:NameElement>
              </xAL:Locality>
              <xAL:Thoroughfare xAL:Type="Street">
                <xAL:NameElement xAL:NameType="NameAndType">Kaiserallee</xAL:NameElement>
                <xAL:Number xAL:Type="Number">5</xAL:Number>
              </xAL:Thoroughfare>
              <xAL:PostCode>
                <xAL:Identifier>76185</xAL:Identifier>
              </xAL:PostCode>
            </xAL:Address>
          </core:xalAddress>
        </core:Address>
      </bldg:address>
    </bldg:Building>
  </core:cityObjectMember>

  <core:cityObjectMember>
    <bldg:Building gml:id="BLDG_CQL2_03">
      <gml:name>Building 03</gml:name>
      <core:genericAttribute>
        <gen:IntAttribute>
          <gen:name>storeys</gen:name>
          <gen:value>3</gen:value>
        </gen:IntAttribute>
      </core:genericAttribute>
      <core:genericAttribute>
        <gen:StringAttribute>
          <gen:name>district</gen:name>
          <gen:value>Mitte</gen:value>
        </gen:StringAttribute>
      </core:genericAttribute>
      <core:genericAttribute>
        <gen:StringAttribute>
          <gen:name>owner</gen:name>
          <gen:value>Owner C</gen:value>
        </gen:StringAttribute>
      </core:genericAttribute>
      <core:genericAttribute>
        <gen:DoubleAttribute>
          <gen:name>area</gen:name>
          <gen:value>300.5</gen:value>
        </gen:DoubleAttribute>
      </core:genericAttribute>
      <core:genericAttribute>
        <gen:DateAttribute>
          <gen:name>constructionDate</gen:name>
          <gen:value>1940-06-15</gen:value>
        </gen:DateAttribute>
      </core:genericAttribute>
      <core:genericAttribute>
        <gen:UriAttribute>
          <gen:name>website</gen:name>
          <gen:value>https://example.org/buildings/03</gen:value>
        </gen:UriAttribute>
      </core:genericAttribute>
      <core:genericAttribute>
        <gen:MeasureAttribute>
          <gen:name>volume</gen:name>
          <gen:value uom="m3">3000</gen:value>
        </gen:MeasureAttribute>
      </core:genericAttribute>
      <core:genericAttribute>
        <gen:CodeAttribute>
          <gen:name>usageCode</gen:name>
          <gen:value codeSpace="https://example.org/codes/usage">A</gen:value>
        </gen:CodeAttribute>
      </core:genericAttribute>
      <core:genericAttribute>
        <gen:StringAttribute>
          <gen:name>Gemeindeschlüssel</gen:name>
          <gen:value>08212000</gen:value>
        </gen:StringAttribute>
      </core:genericAttribute>
      <core:genericAttribute>
        <gen:StringAttribute>
          <gen:name>architect</gen:name>
          <gen:value>O&apos;Brien &amp; Partner</gen:value>
        </gen:StringAttribute>
      </core:genericAttribute>
      <core:genericAttribute>
        <gen:GenericAttributeSet>
          <gen:name>energy</gen:name>
          <gen:genericAttribute>
            <gen:IntAttribute>
              <gen:name>rating</gen:name>
              <gen:value>3</gen:value>
            </gen:IntAttribute>
          </gen:genericAttribute>
          <gen:genericAttribute>
            <gen:StringAttribute>
              <gen:name>label</gen:name>
              <gen:value>E03</gen:value>
            </gen:StringAttribute>
          </gen:genericAttribute>
        </gen:GenericAttributeSet>
      </core:genericAttribute>
      <core:lod2MultiSurface>
        <gml:MultiSurface gml:id="MS_BLDG_CQL2_03">
          <gml:surfaceMember>
            <gml:Polygon gml:id="POLY_B03_BASE">
              <gml:exterior>
                <gml:LinearRing>
                  <gml:posList srsDimension="3">458820.0 5438340.0 0.0 458820.0 5438350.0 0.0 458830.0 5438350.0 0.0 458830.0 5438340.0 0.0 458820.0 5438340.0 0.0</gml:posList>
                </gml:LinearRing>
              </gml:exterior>
            </gml:Polygon>
          </gml:surfaceMember>
          <gml:surfaceMember>
            <gml:Polygon gml:id="POLY_B03_ROOF">
              <gml:exterior>
                <gml:LinearRing>
                  <gml:posList srsDimension="3">458820.0 5438340.0 10.5 458830.0 5438340.0 10.5 458830.0 5438350.0 10.5 458820.0 5438350.0 10.5 458820.0 5438340.0 10.5</gml:posList>
                </gml:LinearRing>
              </gml:exterior>
            </gml:Polygon>
          </gml:surfaceMember>
        </gml:MultiSurface>
      </core:lod2MultiSurface>
      <con:height>
        <con:Height>
          <con:highReference>highestRoofEdge</con:highReference>
          <con:lowReference>lowestGroundPoint</con:lowReference>
          <con:status>measured</con:status>
          <con:value uom="m">10.5</con:value>
        </con:Height>
      </con:height>
      <bldg:function codeSpace="https://www.sig3d.org/codelists/citygml/3.0/building/3.0/_AbstractBuilding_function.xml">1000</bldg:function>
      <bldg:roofType codeSpace="https://www.sig3d.org/codelists/citygml/3.0/building/3.0/_AbstractBuilding_roofType.xml">1000</bldg:roofType>
      <bldg:storeysAboveGround>3</bldg:storeysAboveGround>
      <bldg:address>
        <core:Address gml:id="ADDR_CQL2_03">
          <core:xalAddress>
            <xAL:Address>
              <xAL:Locality xAL:Type="Town">
                <xAL:NameElement xAL:NameType="Name">Karlsruhe</xAL:NameElement>
              </xAL:Locality>
              <xAL:Thoroughfare xAL:Type="Street">
                <xAL:NameElement xAL:NameType="NameAndType">Rheinstraße</xAL:NameElement>
                <xAL:Number xAL:Type="Number">40</xAL:Number>
              </xAL:Thoroughfare>
              <xAL:PostCode>
                <xAL:Identifier>76185</xAL:Identifier>
              </xAL:PostCode>
            </xAL:Address>
          </core:xalAddress>
        </core:Address>
      </bldg:address>
    </bldg:Building>
  </core:cityObjectMember>

  <core:cityObjectMember>
    <bldg:Building gml:id="BLDG_CQL2_04">
      <gml:name>Building 04</gml:name>
      <core:genericAttribute>
        <gen:IntAttribute>
          <gen:name>storeys</gen:name>
          <gen:value>4</gen:value>
        </gen:IntAttribute>
      </core:genericAttribute>
      <core:genericAttribute>
        <gen:StringAttribute>
          <gen:name>district</gen:name>
          <gen:value>Mitte</gen:value>
        </gen:StringAttribute>
      </core:genericAttribute>
      <core:genericAttribute>
        <gen:StringAttribute>
          <gen:name>owner</gen:name>
          <gen:value>Owner D</gen:value>
        </gen:StringAttribute>
      </core:genericAttribute>
      <core:genericAttribute>
        <gen:DoubleAttribute>
          <gen:name>area</gen:name>
          <gen:value>400.5</gen:value>
        </gen:DoubleAttribute>
      </core:genericAttribute>
      <core:genericAttribute>
        <gen:DateAttribute>
          <gen:name>constructionDate</gen:name>
          <gen:value>1950-06-15</gen:value>
        </gen:DateAttribute>
      </core:genericAttribute>
      <core:genericAttribute>
        <gen:UriAttribute>
          <gen:name>website</gen:name>
          <gen:value>https://example.org/buildings/04</gen:value>
        </gen:UriAttribute>
      </core:genericAttribute>
      <core:genericAttribute>
        <gen:MeasureAttribute>
          <gen:name>volume</gen:name>
          <gen:value uom="m3">4000</gen:value>
        </gen:MeasureAttribute>
      </core:genericAttribute>
      <core:genericAttribute>
        <gen:CodeAttribute>
          <gen:name>usageCode</gen:name>
          <gen:value codeSpace="https://example.org/codes/usage">A</gen:value>
        </gen:CodeAttribute>
      </core:genericAttribute>
      <core:genericAttribute>
        <gen:StringAttribute>
          <gen:name>Gemeindeschlüssel</gen:name>
          <gen:value>08212000</gen:value>
        </gen:StringAttribute>
      </core:genericAttribute>
      <core:genericAttribute>
        <gen:StringAttribute>
          <gen:name>architect</gen:name>
          <gen:value>Müller-Lüdenscheidt</gen:value>
        </gen:StringAttribute>
      </core:genericAttribute>
      <core:lod2MultiSurface>
        <gml:MultiSurface gml:id="MS_BLDG_CQL2_04">
          <gml:surfaceMember>
            <gml:Polygon gml:id="POLY_B04_BASE">
              <gml:exterior>
                <gml:LinearRing>
                  <gml:posList srsDimension="3">458835.0 5438340.0 0.0 458835.0 5438350.0 0.0 458845.0 5438350.0 0.0 458845.0 5438340.0 0.0 458835.0 5438340.0 0.0</gml:posList>
                </gml:LinearRing>
              </gml:exterior>
            </gml:Polygon>
          </gml:surfaceMember>
          <gml:surfaceMember>
            <gml:Polygon gml:id="POLY_B04_ROOF">
              <gml:exterior>
                <gml:LinearRing>
                  <gml:posList srsDimension="3">458835.0 5438340.0 14.0 458845.0 5438340.0 14.0 458845.0 5438350.0 14.0 458835.0 5438350.0 14.0 458835.0 5438340.0 14.0</gml:posList>
                </gml:LinearRing>
              </gml:exterior>
            </gml:Polygon>
          </gml:surfaceMember>
        </gml:MultiSurface>
      </core:lod2MultiSurface>
      <con:height>
        <con:Height>
          <con:highReference>highestRoofEdge</con:highReference>
          <con:lowReference>lowestGroundPoint</con:lowReference>
          <con:status>measured</con:status>
          <con:value uom="m">14.0</con:value>
        </con:Height>
      </con:height>
      <bldg:function codeSpace="https://www.sig3d.org/codelists/citygml/3.0/building/3.0/_AbstractBuilding_function.xml">1000</bldg:function>
      <bldg:roofType codeSpace="https://www.sig3d.org/codelists/citygml/3.0/building/3.0/_AbstractBuilding_roofType.xml">1000</bldg:roofType>
      <bldg:storeysAboveGround>4</bldg:storeysAboveGround>
    </bldg:Building>
  </core:cityObjectMember>

  <core:cityObjectMember>
    <bldg:Building gml:id="BLDG_CQL2_05">
      <gml:name>Building 05</gml:name>
      <core:genericAttribute>
        <gen:IntAttribute>
          <gen:name>storeys</gen:name>
          <gen:value>5</gen:value>
        </gen:IntAttribute>
      </core:genericAttribute>
      <core:genericAttribute>
        <gen:StringAttribute>
          <gen:name>district</gen:name>
          <gen:value>Nord</gen:value>
        </gen:StringAttribute>
      </core:genericAttribute>
      <core:genericAttribute>
        <gen:StringAttribute>
          <gen:name>owner</gen:name>
          <gen:value>Owner E</gen:value>
        </gen:StringAttribute>
      </core:genericAttribute>
      <core:genericAttribute>
        <gen:DoubleAttribute>
          <gen:name>area</gen:name>
          <gen:value>500.5</gen:value>
        </gen:DoubleAttribute>
      </core:genericAttribute>
      <core:genericAttribute>
        <gen:DateAttribute>
          <gen:name>constructionDate</gen:name>
          <gen:value>1960-06-15</gen:value>
        </gen:DateAttribute>
      </core:genericAttribute>
      <core:genericAttribute>
        <gen:MeasureAttribute>
          <gen:name>volume</gen:name>
          <gen:value uom="m3">5000</gen:value>
        </gen:MeasureAttribute>
      </core:genericAttribute>
      <core:genericAttribute>
        <gen:CodeAttribute>
          <gen:name>usageCode</gen:name>
          <gen:value codeSpace="https://example.org/codes/usage">B</gen:value>
        </gen:CodeAttribute>
      </core:genericAttribute>
      <core:genericAttribute>
        <gen:StringAttribute>
          <gen:name>Gemeindeschlüssel</gen:name>
          <gen:value>08215017</gen:value>
        </gen:StringAttribute>
      </core:genericAttribute>
      <core:lod2MultiSurface>
        <gml:MultiSurface gml:id="MS_BLDG_CQL2_05">
          <gml:surfaceMember>
            <gml:Polygon gml:id="POLY_B05_BASE">
              <gml:exterior>
                <gml:LinearRing>
                  <gml:posList srsDimension="3">459040.0 5438340.0 0.0 459040.0 5438350.0 0.0 459050.0 5438350.0 0.0 459050.0 5438340.0 0.0 459040.0 5438340.0 0.0</gml:posList>
                </gml:LinearRing>
              </gml:exterior>
            </gml:Polygon>
          </gml:surfaceMember>
          <gml:surfaceMember>
            <gml:Polygon gml:id="POLY_B05_ROOF">
              <gml:exterior>
                <gml:LinearRing>
                  <gml:posList srsDimension="3">459040.0 5438340.0 17.5 459050.0 5438340.0 17.5 459050.0 5438350.0 17.5 459040.0 5438350.0 17.5 459040.0 5438340.0 17.5</gml:posList>
                </gml:LinearRing>
              </gml:exterior>
            </gml:Polygon>
          </gml:surfaceMember>
        </gml:MultiSurface>
      </core:lod2MultiSurface>
      <con:height>
        <con:Height>
          <con:highReference>highestRoofEdge</con:highReference>
          <con:lowReference>lowestGroundPoint</con:lowReference>
          <con:status>measured</con:status>
          <con:value uom="m">17.5</con:value>
        </con:Height>
      </con:height>
      <bldg:function codeSpace="https://www.sig3d.org/codelists/citygml/3.0/building/3.0/_AbstractBuilding_function.xml">1000</bldg:function>
      <bldg:roofType codeSpace="https://www.sig3d.org/codelists/citygml/3.0/building/3.0/_AbstractBuilding_roofType.xml">3100</bldg:roofType>
      <bldg:storeysAboveGround>5</bldg:storeysAboveGround>
      <bldg:address>
        <core:Address gml:id="ADDR_CQL2_05">
          <core:xalAddress>
            <xAL:Address>
              <xAL:Locality xAL:Type="Town">
                <xAL:NameElement xAL:NameType="Name">Ettlingen</xAL:NameElement>
              </xAL:Locality>
              <xAL:Thoroughfare xAL:Type="Street">
                <xAL:NameElement xAL:NameType="NameAndType">Kaiserstraße</xAL:NameElement>
                <xAL:Number xAL:Type="Number">7</xAL:Number>
              </xAL:Thoroughfare>
              <xAL:PostCode>
                <xAL:Identifier>76275</xAL:Identifier>
              </xAL:PostCode>
            </xAL:Address>
          </core:xalAddress>
        </core:Address>
      </bldg:address>
    </bldg:Building>
  </core:cityObjectMember>

  <core:cityObjectMember>
    <bldg:Building gml:id="BLDG_CQL2_06">
      <gml:name>Building 06</gml:name>
      <core:genericAttribute>
        <gen:IntAttribute>
          <gen:name>storeys</gen:name>
          <gen:value>6</gen:value>
        </gen:IntAttribute>
      </core:genericAttribute>
      <core:genericAttribute>
        <gen:StringAttribute>
          <gen:name>district</gen:name>
          <gen:value>Nord</gen:value>
        </gen:StringAttribute>
      </core:genericAttribute>
      <core:genericAttribute>
        <gen:DoubleAttribute>
          <gen:name>area</gen:name>
          <gen:value>600.5</gen:value>
        </gen:DoubleAttribute>
      </core:genericAttribute>
      <core:genericAttribute>
        <gen:DateAttribute>
          <gen:name>constructionDate</gen:name>
          <gen:value>1970-06-15</gen:value>
        </gen:DateAttribute>
      </core:genericAttribute>
      <core:genericAttribute>
        <gen:MeasureAttribute>
          <gen:name>volume</gen:name>
          <gen:value uom="m3">6000</gen:value>
        </gen:MeasureAttribute>
      </core:genericAttribute>
      <core:genericAttribute>
        <gen:CodeAttribute>
          <gen:name>usageCode</gen:name>
          <gen:value codeSpace="https://example.org/codes/usage">B</gen:value>
        </gen:CodeAttribute>
      </core:genericAttribute>
      <core:genericAttribute>
        <gen:StringAttribute>
          <gen:name>Gemeindeschlüssel</gen:name>
          <gen:value>08215017</gen:value>
        </gen:StringAttribute>
      </core:genericAttribute>
      <core:lod2MultiSurface>
        <gml:MultiSurface gml:id="MS_BLDG_CQL2_06">
          <gml:surfaceMember>
            <gml:Polygon gml:id="POLY_B06_BASE">
              <gml:exterior>
                <gml:LinearRing>
                  <gml:posList srsDimension="3">459055.0 5438340.0 0.0 459055.0 5438350.0 0.0 459065.0 5438350.0 0.0 459065.0 5438340.0 0.0 459055.0 5438340.0 0.0</gml:posList>
                </gml:LinearRing>
              </gml:exterior>
            </gml:Polygon>
          </gml:surfaceMember>
          <gml:surfaceMember>
            <gml:Polygon gml:id="POLY_B06_ROOF">
              <gml:exterior>
                <gml:LinearRing>
                  <gml:posList srsDimension="3">459055.0 5438340.0 21.0 459065.0 5438340.0 21.0 459065.0 5438350.0 21.0 459055.0 5438350.0 21.0 459055.0 5438340.0 21.0</gml:posList>
                </gml:LinearRing>
              </gml:exterior>
            </gml:Polygon>
          </gml:surfaceMember>
        </gml:MultiSurface>
      </core:lod2MultiSurface>
      <con:height>
        <con:Height>
          <con:highReference>highestRoofEdge</con:highReference>
          <con:lowReference>lowestGroundPoint</con:lowReference>
          <con:status>measured</con:status>
          <con:value uom="m">21.0</con:value>
        </con:Height>
      </con:height>
      <bldg:function codeSpace="https://www.sig3d.org/codelists/citygml/3.0/building/3.0/_AbstractBuilding_function.xml">1000</bldg:function>
      <bldg:roofType codeSpace="https://www.sig3d.org/codelists/citygml/3.0/building/3.0/_AbstractBuilding_roofType.xml">3200</bldg:roofType>
      <bldg:storeysAboveGround>6</bldg:storeysAboveGround>
    </bldg:Building>
  </core:cityObjectMember>

  <core:cityObjectMember>
    <bldg:Building gml:id="BLDG_CQL2_07">
      <gml:name>Building 07</gml:name>
      <core:genericAttribute>
        <gen:IntAttribute>
          <gen:name>storeys</gen:name>
          <gen:value>7</gen:value>
        </gen:IntAttribute>
      </core:genericAttribute>
      <core:genericAttribute>
        <gen:StringAttribute>
          <gen:name>district</gen:name>
          <gen:value>Sued</gen:value>
        </gen:StringAttribute>
      </core:genericAttribute>
      <core:genericAttribute>
        <gen:DoubleAttribute>
          <gen:name>area</gen:name>
          <gen:value>700.5</gen:value>
        </gen:DoubleAttribute>
      </core:genericAttribute>
      <core:genericAttribute>
        <gen:DateAttribute>
          <gen:name>constructionDate</gen:name>
          <gen:value>1980-06-15</gen:value>
        </gen:DateAttribute>
      </core:genericAttribute>
      <core:genericAttribute>
        <gen:MeasureAttribute>
          <gen:name>volume</gen:name>
          <gen:value uom="m3">7000</gen:value>
        </gen:MeasureAttribute>
      </core:genericAttribute>
      <core:genericAttribute>
        <gen:CodeAttribute>
          <gen:name>usageCode</gen:name>
          <gen:value codeSpace="https://example.org/codes/usage">C</gen:value>
        </gen:CodeAttribute>
      </core:genericAttribute>
      <core:genericAttribute>
        <gen:StringAttribute>
          <gen:name>Gemeindeschlüssel</gen:name>
          <gen:value>08215017</gen:value>
        </gen:StringAttribute>
      </core:genericAttribute>
      <core:lod2MultiSurface>
        <gml:MultiSurface gml:id="MS_BLDG_CQL2_07">
          <gml:surfaceMember>
            <gml:Polygon gml:id="POLY_B07_BASE">
              <gml:exterior>
                <gml:LinearRing>
                  <gml:posList srsDimension="3">459070.0 5438340.0 0.0 459070.0 5438350.0 0.0 459080.0 5438350.0 0.0 459080.0 5438340.0 0.0 459070.0 5438340.0 0.0</gml:posList>
                </gml:LinearRing>
              </gml:exterior>
            </gml:Polygon>
          </gml:surfaceMember>
          <gml:surfaceMember>
            <gml:Polygon gml:id="POLY_B07_ROOF">
              <gml:exterior>
                <gml:LinearRing>
                  <gml:posList srsDimension="3">459070.0 5438340.0 24.5 459080.0 5438340.0 24.5 459080.0 5438350.0 24.5 459070.0 5438350.0 24.5 459070.0 5438340.0 24.5</gml:posList>
                </gml:LinearRing>
              </gml:exterior>
            </gml:Polygon>
          </gml:surfaceMember>
        </gml:MultiSurface>
      </core:lod2MultiSurface>
      <con:height>
        <con:Height>
          <con:highReference>highestRoofEdge</con:highReference>
          <con:lowReference>lowestGroundPoint</con:lowReference>
          <con:status>measured</con:status>
          <con:value uom="m">24.5</con:value>
        </con:Height>
      </con:height>
      <bldg:function codeSpace="https://www.sig3d.org/codelists/citygml/3.0/building/3.0/_AbstractBuilding_function.xml">1010</bldg:function>
      <bldg:function codeSpace="https://www.sig3d.org/codelists/citygml/3.0/building/3.0/_AbstractBuilding_function.xml">2000</bldg:function>
      <bldg:roofType codeSpace="https://www.sig3d.org/codelists/citygml/3.0/building/3.0/_AbstractBuilding_roofType.xml">3300</bldg:roofType>
      <bldg:storeysAboveGround>7</bldg:storeysAboveGround>
    </bldg:Building>
  </core:cityObjectMember>

  <core:cityObjectMember>
    <bldg:Building gml:id="BLDG_CQL2_08">
      <gml:name>Building 08</gml:name>
      <core:genericAttribute>
        <gen:IntAttribute>
          <gen:name>storeys</gen:name>
          <gen:value>8</gen:value>
        </gen:IntAttribute>
      </core:genericAttribute>
      <core:genericAttribute>
        <gen:StringAttribute>
          <gen:name>district</gen:name>
          <gen:value>Sued</gen:value>
        </gen:StringAttribute>
      </core:genericAttribute>
      <core:genericAttribute>
        <gen:DoubleAttribute>
          <gen:name>area</gen:name>
          <gen:value>800.5</gen:value>
        </gen:DoubleAttribute>
      </core:genericAttribute>
      <core:genericAttribute>
        <gen:DateAttribute>
          <gen:name>constructionDate</gen:name>
          <gen:value>1990-06-15</gen:value>
        </gen:DateAttribute>
      </core:genericAttribute>
      <core:genericAttribute>
        <gen:MeasureAttribute>
          <gen:name>volume</gen:name>
          <gen:value uom="m3">8000</gen:value>
        </gen:MeasureAttribute>
      </core:genericAttribute>
      <core:genericAttribute>
        <gen:CodeAttribute>
          <gen:name>usageCode</gen:name>
          <gen:value codeSpace="https://example.org/codes/usage">C</gen:value>
        </gen:CodeAttribute>
      </core:genericAttribute>
      <core:genericAttribute>
        <gen:StringAttribute>
          <gen:name>Gemeindeschlüssel</gen:name>
          <gen:value>08215017</gen:value>
        </gen:StringAttribute>
      </core:genericAttribute>
      <core:lod2MultiSurface>
        <gml:MultiSurface gml:id="MS_BLDG_CQL2_08">
          <gml:surfaceMember>
            <gml:Polygon gml:id="POLY_B08_BASE">
              <gml:exterior>
                <gml:LinearRing>
                  <gml:posList srsDimension="3">459085.0 5438340.0 0.0 459085.0 5438350.0 0.0 459095.0 5438350.0 0.0 459095.0 5438340.0 0.0 459085.0 5438340.0 0.0</gml:posList>
                </gml:LinearRing>
              </gml:exterior>
            </gml:Polygon>
          </gml:surfaceMember>
          <gml:surfaceMember>
            <gml:Polygon gml:id="POLY_B08_ROOF">
              <gml:exterior>
                <gml:LinearRing>
                  <gml:posList srsDimension="3">459085.0 5438340.0 28.0 459095.0 5438340.0 28.0 459095.0 5438350.0 28.0 459085.0 5438350.0 28.0 459085.0 5438340.0 28.0</gml:posList>
                </gml:LinearRing>
              </gml:exterior>
            </gml:Polygon>
          </gml:surfaceMember>
        </gml:MultiSurface>
      </core:lod2MultiSurface>
      <con:height>
        <con:Height>
          <con:highReference>highestRoofEdge</con:highReference>
          <con:lowReference>lowestGroundPoint</con:lowReference>
          <con:status>measured</con:status>
          <con:value uom="m">28.0</con:value>
        </con:Height>
      </con:height>
      <bldg:function codeSpace="https://www.sig3d.org/codelists/citygml/3.0/building/3.0/_AbstractBuilding_function.xml">1010</bldg:function>
      <bldg:function codeSpace="https://www.sig3d.org/codelists/citygml/3.0/building/3.0/_AbstractBuilding_function.xml">2000</bldg:function>
      <bldg:roofType codeSpace="https://www.sig3d.org/codelists/citygml/3.0/building/3.0/_AbstractBuilding_roofType.xml">2100</bldg:roofType>
      <bldg:storeysAboveGround>8</bldg:storeysAboveGround>
    </bldg:Building>
  </core:cityObjectMember>

  <core:cityObjectMember>
    <tran:Road gml:id="ROAD_CQL2_01">
      <gml:name>Road 01</gml:name>
      <core:genericAttribute>
        <gen:StringAttribute>
          <gen:name>district</gen:name>
          <gen:value>Mitte</gen:value>
        </gen:StringAttribute>
      </core:genericAttribute>
      <core:lod2MultiSurface>
        <gml:MultiSurface gml:id="MS_ROAD_CQL2_01">
          <gml:surfaceMember>
            <gml:Polygon gml:id="POLY_R01_SURF">
              <gml:exterior>
                <gml:LinearRing>
                  <gml:posList srsDimension="3">458785.0 5438357.5 0.0 458855.0 5438357.5 0.0 458855.0 5438362.5 0.0 458785.0 5438362.5 0.0 458785.0 5438357.5 0.0</gml:posList>
                </gml:LinearRing>
              </gml:exterior>
            </gml:Polygon>
          </gml:surfaceMember>
        </gml:MultiSurface>
      </core:lod2MultiSurface>
    </tran:Road>
  </core:cityObjectMember>

  <core:cityObjectMember>
    <tran:Road gml:id="ROAD_CQL2_02">
      <gml:name>Road 02</gml:name>
      <core:genericAttribute>
        <gen:StringAttribute>
          <gen:name>district</gen:name>
          <gen:value>Nord</gen:value>
        </gen:StringAttribute>
      </core:genericAttribute>
      <core:lod2MultiSurface>
        <gml:MultiSurface gml:id="MS_ROAD_CQL2_02">
          <gml:surfaceMember>
            <gml:Polygon gml:id="POLY_R02_SURF">
              <gml:exterior>
                <gml:LinearRing>
                  <gml:posList srsDimension="3">459035.0 5438357.5 0.0 459105.0 5438357.5 0.0 459105.0 5438362.5 0.0 459035.0 5438362.5 0.0 459035.0 5438357.5 0.0</gml:posList>
                </gml:LinearRing>
              </gml:exterior>
            </gml:Polygon>
          </gml:surfaceMember>
        </gml:MultiSurface>
      </core:lod2MultiSurface>
    </tran:Road>
  </core:cityObjectMember>

</core:CityModel>
