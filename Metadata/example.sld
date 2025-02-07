<?xml version="1.0" encoding="UTF-8"?>
<StyledLayerDescriptor xmlns="http://www.opengis.net/sld" version="1.0.0" xmlns:sld="http://www.opengis.net/sld" xmlns:gml="http://www.opengis.net/gml" xmlns:ogc="http://www.opengis.net/ogc">
  <UserLayer>
    <sld:LayerFeatureConstraints>
      <sld:FeatureTypeConstraint/>
    </sld:LayerFeatureConstraints>
    <sld:UserStyle>
      <sld:Name>LGN2021_mskbrp</sld:Name>
      <sld:FeatureTypeStyle>
        <sld:Rule>
          <sld:RasterSymbolizer>
            <sld:ChannelSelection>
              <sld:GrayChannel>
                <sld:SourceChannelName>1</sld:SourceChannelName>
              </sld:GrayChannel>
            </sld:ChannelSelection>
            <sld:ColorMap type="values">
             <sld:ColorMapEntry quantity="1" color="#73df1f" opacity="1" label="1 - agrarisch gras"/>
             <sld:ColorMapEntry quantity="2" color="#e89919" opacity="1" label="2 - maïs"/>
             <sld:ColorMapEntry quantity="3" color="#b26600" opacity="1" label="3 - aardappelen"/>
             <sld:ColorMapEntry quantity="4" color="#e51f7f" opacity="1" label="4 - bieten"/>
             <sld:ColorMapEntry quantity="5" color="#ffff00" opacity="1" label="5 - granen"/>
             <sld:ColorMapEntry quantity="6" color="#ff00c5" opacity="1" label="6 - overige landbouwgewassen"/>
             <sld:ColorMapEntry quantity="9" color="#3cef45" opacity="1" label="9 - boomgaarden"/>
             <sld:ColorMapEntry quantity="10" color="#ac81a8" opacity="1" label="10 - bloembollen"/>
             <sld:ColorMapEntry quantity="11" color="#33c800" opacity="1" label="11 - loofbos"/>
             <sld:ColorMapEntry quantity="16" color="#2473ff" opacity="1" label="16 - zoet water"/>
             <sld:ColorMapEntry quantity="42" color="#ffa500" opacity="1" label="42 - rietvegetatie"/>
             <sld:ColorMapEntry quantity="45" color="#b6b639" opacity="1" label="45 - natuurgraslanden"/>
             <sld:ColorMapEntry quantity="61" color="#ffb3a8" opacity="1" label="61 - boomkwekerijen"/>
             <sld:ColorMapEntry quantity="62" color="#e3ff70" opacity="1" label="62 - fruitkwekerijen"/>
             <sld:ColorMapEntry quantity="451" color="#b6b639" opacity="1" label="451 - natuurgraslanden"/>
            </sld:ColorMap>
          </sld:RasterSymbolizer>
        </sld:Rule>
      </sld:FeatureTypeStyle>
    </sld:UserStyle>
  </UserLayer>
</StyledLayerDescriptor>