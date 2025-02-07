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
            <sld:ColorMap type="ramp">
              <sld:ColorMapEntry color="#30123b" quantity="0" label="0"/>
              <sld:ColorMapEntry color="#4662d8" quantity="11.111111111111111" label="11"/>
              <sld:ColorMapEntry color="#35abf8" quantity="22.222222222222221" label="22"/>
              <sld:ColorMapEntry color="#1be5b5" quantity="33.333333333333329" label="33"/>
              <sld:ColorMapEntry color="#74fe5d" quantity="44.444444444444443" label="44"/>
              <sld:ColorMapEntry color="#c9ef34" quantity="55.555555555555557" label="56"/>
              <sld:ColorMapEntry color="#fbb938" quantity="66.666666666666657" label="67"/>
              <sld:ColorMapEntry color="#f56918" quantity="77.777777777777771" label="78"/>
              <sld:ColorMapEntry color="#c92903" quantity="88.888888888888886" label="89"/>
              <sld:ColorMapEntry color="#7a0403" quantity="100" label="100"/>
            </sld:ColorMap>
          </sld:RasterSymbolizer>
        </sld:Rule>
      </sld:FeatureTypeStyle>
    </sld:UserStyle>
  </UserLayer>
</StyledLayerDescriptor>
