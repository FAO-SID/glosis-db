<?xml version="1.0" encoding="UTF-8"?>
<StyledLayerDescriptor xmlns="http://www.opengis.net/sld" xmlns:sld="http://www.opengis.net/sld" xmlns:ogc="http://www.opengis.net/ogc" xmlns:gml="http://www.opengis.net/gml" version="1.0.0">
  <UserLayer>
    <sld:LayerFeatureConstraints>
      <sld:FeatureTypeConstraint/>
    </sld:LayerFeatureConstraints>
    <sld:UserStyle>
      <sld:Name>PH-Soil-OC-0_30</sld:Name>
      <sld:FeatureTypeStyle>
        <sld:Rule>
          <sld:RasterSymbolizer>
            <sld:ChannelSelection>
              <sld:GrayChannel>
                <sld:SourceChannelName>1</sld:SourceChannelName>
              </sld:GrayChannel>
            </sld:ChannelSelection>
            <sld:ColorMap type="intervals">
              <sld:ColorMapEntry color="#30123b" quantity="10" label="0 - 10"/>
              <sld:ColorMapEntry color="#4662d8" quantity="20" label="10 - 20"/>
              <sld:ColorMapEntry color="#35abf8" quantity="30" label="20 - 30"/>
              <sld:ColorMapEntry color="#1be5b5" quantity="40" label="30 - 40"/>
              <sld:ColorMapEntry color="#74fe5d" quantity="50" label="40 - 50"/>
              <sld:ColorMapEntry color="#c9ef34" quantity="60" label="50 - 60"/>
              <sld:ColorMapEntry color="#fbb938" quantity="70" label="60 - 70"/>
              <sld:ColorMapEntry color="#f56918" quantity="80" label="70 - 80"/>
              <sld:ColorMapEntry color="#c92903" quantity="90" label="80 - 90"/>
              <sld:ColorMapEntry color="#7a0403" quantity="100" label="90 - 100"/>
            </sld:ColorMap>
          </sld:RasterSymbolizer>
        </sld:Rule>
      </sld:FeatureTypeStyle>
    </sld:UserStyle>
  </UserLayer>
</StyledLayerDescriptor>
