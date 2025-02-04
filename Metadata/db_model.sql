-- DROP SCHEMA IF EXISTS metadata CASCADE;
CREATE SCHEMA metadata;
ALTER SCHEMA metadata OWNER TO glosis;
COMMENT ON SCHEMA metadata IS 'Schema for glosis metadata';
GRANT USAGE ON SCHEMA metadata TO glosis_r;


--------------------------
--      FUNCTION        --
--------------------------

CREATE OR REPLACE FUNCTION metadata.map()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE
    rec RECORD;
	sub_rec RECORD;
    part_1 text := 'MAP
  NAME "LAYER_ID"
  EXTENT LAYER_EXTENT
  UNITS LAYER_UNITS
  SHAPEPATH "./"
  SIZE 800 600
  IMAGETYPE "PNG24"
  PROJECTION
      "init=epsg:LAYER_EPSG"
  END # PROJECTION
  WEB
      METADATA
          "ows_title" "LAYER_PROJECT web-service" 
          "ows_enable_request" "*" 
          "ows_srs" "EPSG:4326 EPSG:28992 EPSG:3857"
          "ows_getfeatureinfo_formatlist" "text/plain,text/html,application/json,geojson,application/vnd.ogc.gml,gml"
		  "wms_feature_info_mime_type" "text/plain,text/html"
      END # METADATA
  END # WEB
  LAYER
      TEMPLATE "getfeatureinfo_template.tmpl"
      NAME "LAYER_ID"
      DATA "LAYER_ID.tif"
      TYPE RASTER
      STATUS ON';
    part_2 text :='';
    part_3 text := '
  END # LAYER
END # MAP';
    new_row text;

BEGIN
    FOR rec IN SELECT dataset_id, version, title, epsg::text, units, extent FROM metadata.version ORDER BY dataset_id, version
    LOOP
	
      FOR sub_rec IN SELECT value, color, (opacity*100)::int AS opacity, label FROM metadata.layer_category WHERE dataset_id = rec.dataset_id AND version = rec.version AND publish IS TRUE ORDER BY value
    	LOOP

    		SELECT E'\n      CLASS
          NAME "' ||sub_rec.value||' - '||sub_rec.label|| '"
          EXPRESSION "' ||sub_rec.value|| '"
          STYLE
              COLOR "' ||sub_rec.color|| '"
			  OPACITY ' ||sub_rec.opacity|| '
          END # STYLE
      END # CLASS' INTO new_row;
	
            SELECT part_2 || new_row INTO part_2;
		
		END LOOP;
		
		  UPDATE metadata.version 
		    SET map = replace(
						replace(
							replace(
								replace(
									replace(
										replace(
											part_1,'LAYER_NAME', rec.title)
												  , 'LAYER_EXTENT', rec.extent)
												  , 'LAYER_UNITS', rec.units)
												  , 'LAYER_EPSG', rec.epsg)
												  , 'LAYER_PROJECT', rec.dataset_id)
												  , 'LAYER_ID', rec.layer_id) || part_2 || part_3
			WHERE dataset_id = rec.dataset_id AND version = rec.version;
		  SELECT '' INTO part_2;
		  SELECT '' INTO new_row;
		  
	END LOOP;
    RETURN NEW;
END
$BODY$;
ALTER FUNCTION metadata.map() OWNER TO glosis;


CREATE OR REPLACE FUNCTION metadata.qml()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE
    rec RECORD;
	sub_rec RECORD;
    part_1 text := '<!DOCTYPE qgis PUBLIC "http://mrcc.com/qgis.dtd" "SYSTEM">
<qgis version="3.30.0-s-Hertogenbosch" styleCategories="AllStyleCategories" hasScaleBasedVisibilityFlag="0" minScale="1e+08" maxScale="0">
  <flags>
    <Identifiable>1</Identifiable>
    <Removable>1</Removable>
    <Searchable>1</Searchable>
    <Private>0</Private>
  </flags>
  <temporal fetchMode="0" enabled="0" mode="0">
    <fixedRange>
      <start></start>
      <end></end>
    </fixedRange>
  </temporal>
  <elevation enabled="0" zscale="1" symbology="Line" zoffset="0" band="1">
    <data-defined-properties>
      <Option type="Map">
        <Option type="QString" value="" name="name"/>
        <Option name="properties"/>
        <Option type="QString" value="collection" name="type"/>
      </Option>
    </data-defined-properties>
    <profileLineSymbol>
      <symbol clip_to_extent="1" is_animated="0" type="line" alpha="1" frame_rate="10" force_rhr="0" name="">
        <data_defined_properties>
          <Option type="Map">
            <Option type="QString" value="" name="name"/>
            <Option name="properties"/>
            <Option type="QString" value="collection" name="type"/>
          </Option>
        </data_defined_properties>
        <layer enabled="1" locked="0" id="{d6f70729-1f8d-44fd-bf2d-05fbfa3ba0ef}" class="SimpleLine" pass="0">
          <Option type="Map">
            <Option type="QString" value="0" name="align_dash_pattern"/>
            <Option type="QString" value="square" name="capstyle"/>
            <Option type="QString" value="5;2" name="customdash"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="customdash_map_unit_scale"/>
            <Option type="QString" value="MM" name="customdash_unit"/>
            <Option type="QString" value="0" name="dash_pattern_offset"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="dash_pattern_offset_map_unit_scale"/>
            <Option type="QString" value="MM" name="dash_pattern_offset_unit"/>
            <Option type="QString" value="0" name="draw_inside_polygon"/>
            <Option type="QString" value="bevel" name="joinstyle"/>
            <Option type="QString" value="141,90,153,255" name="line_color"/>
            <Option type="QString" value="solid" name="line_style"/>
            <Option type="QString" value="0.6" name="line_width"/>
            <Option type="QString" value="MM" name="line_width_unit"/>
            <Option type="QString" value="0" name="offset"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="offset_map_unit_scale"/>
            <Option type="QString" value="MM" name="offset_unit"/>
            <Option type="QString" value="0" name="ring_filter"/>
            <Option type="QString" value="0" name="trim_distance_end"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="trim_distance_end_map_unit_scale"/>
            <Option type="QString" value="MM" name="trim_distance_end_unit"/>
            <Option type="QString" value="0" name="trim_distance_start"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="trim_distance_start_map_unit_scale"/>
            <Option type="QString" value="MM" name="trim_distance_start_unit"/>
            <Option type="QString" value="0" name="tweak_dash_pattern_on_corners"/>
            <Option type="QString" value="0" name="use_custom_dash"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="width_map_unit_scale"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option type="QString" value="" name="name"/>
              <Option name="properties"/>
              <Option type="QString" value="collection" name="type"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
    </profileLineSymbol>
    <profileFillSymbol>
      <symbol clip_to_extent="1" is_animated="0" type="fill" alpha="1" frame_rate="10" force_rhr="0" name="">
        <data_defined_properties>
          <Option type="Map">
            <Option type="QString" value="" name="name"/>
            <Option name="properties"/>
            <Option type="QString" value="collection" name="type"/>
          </Option>
        </data_defined_properties>
        <layer enabled="1" locked="0" id="{6217b42c-d842-4c0d-9824-1f6d3f88597a}" class="SimpleFill" pass="0">
          <Option type="Map">
            <Option type="QString" value="3x:0,0,0,0,0,0" name="border_width_map_unit_scale"/>
            <Option type="QString" value="141,90,153,255" name="color"/>
            <Option type="QString" value="bevel" name="joinstyle"/>
            <Option type="QString" value="0,0" name="offset"/>
            <Option type="QString" value="3x:0,0,0,0,0,0" name="offset_map_unit_scale"/>
            <Option type="QString" value="MM" name="offset_unit"/>
            <Option type="QString" value="35,35,35,255" name="outline_color"/>
            <Option type="QString" value="no" name="outline_style"/>
            <Option type="QString" value="0.26" name="outline_width"/>
            <Option type="QString" value="MM" name="outline_width_unit"/>
            <Option type="QString" value="solid" name="style"/>
          </Option>
          <data_defined_properties>
            <Option type="Map">
              <Option type="QString" value="" name="name"/>
              <Option name="properties"/>
              <Option type="QString" value="collection" name="type"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
    </profileFillSymbol>
  </elevation>
  <customproperties>
    <Option type="Map">
      <Option type="bool" value="false" name="WMSBackgroundLayer"/>
      <Option type="bool" value="false" name="WMSPublishDataSourceUrl"/>
      <Option type="int" value="0" name="embeddedWidgets/count"/>
      <Option type="QString" value="Value" name="identify/format"/>
    </Option>
  </customproperties>
  <mapTip></mapTip>
  <pipe-data-defined-properties>
    <Option type="Map">
      <Option type="QString" value="" name="name"/>
      <Option name="properties"/>
      <Option type="QString" value="collection" name="type"/>
    </Option>
  </pipe-data-defined-properties>
  <pipe>
    <provider>
      <resampling enabled="false" zoomedOutResamplingMethod="nearestNeighbour" zoomedInResamplingMethod="nearestNeighbour" maxOversampling="2"/>
    </provider>
    <rasterrenderer type="paletted" nodataColor="" opacity="1" alphaBand="-1" band="1">
      <rasterTransparency/>
      <minMaxOrigin>
        <limits>None</limits>
        <extent>WholeRaster</extent>
        <statAccuracy>Estimated</statAccuracy>
        <cumulativeCutLower>0.02</cumulativeCutLower>
        <cumulativeCutUpper>0.98</cumulativeCutUpper>
        <stdDevFactor>2</stdDevFactor>
      </minMaxOrigin>
      <colorPalette>';
    part_2 text :='';
	  new_row text;
    part_3 text := '
      </colorPalette>
      <colorramp type="randomcolors" name="[source]">
        <Option/>
      </colorramp>
    </rasterrenderer>
    <brightnesscontrast contrast="0" brightness="0" gamma="1"/>
    <huesaturation colorizeOn="0" colorizeBlue="128" colorizeStrength="100" invertColors="0" saturation="0" colorizeRed="255" grayscaleMode="0" colorizeGreen="128"/>
    <rasterresampler maxOversampling="2"/>
    <resamplingStage>resamplingFilter</resamplingStage>
  </pipe>
  <blendMode>0</blendMode>
</qgis>';
BEGIN
    FOR rec IN SELECT dataset_id, version FROM metadata.version ORDER BY dataset_id, version
    LOOP
	
      FOR sub_rec IN SELECT code, value, color, (opacity*255)::int AS alpha, label FROM metadata.layer_category WHERE dataset_id = rec.dataset_id AND version = rec.version AND publish IS TRUE ORDER BY value
    	LOOP

			SELECT E'\n        <paletteEntry value="' ||sub_rec.value|| '" color="' ||sub_rec.color|| '" alpha="' ||sub_rec.alpha|| '" label="' ||sub_rec.code||' - '||sub_rec.label|| '"/>' INTO new_row;

			SELECT part_2 || new_row INTO part_2;
		
		END LOOP;
		
		  UPDATE metadata.version SET qml = part_1 || part_2 || part_3 WHERE dataset_id = rec.dataset_id AND version = rec.version;
		  SELECT '' INTO part_2;
		  SELECT '' INTO new_row;
		  
	END LOOP;
    RETURN NEW;
END
$BODY$;
ALTER FUNCTION metadata.qml() OWNER TO glosis;


CREATE OR REPLACE FUNCTION metadata.sld()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$
DECLARE
    rec RECORD;
	sub_rec RECORD;
    part_1 text := '<?xml version="1.0" encoding="UTF-8"?>
<StyledLayerDescriptor xmlns="http://www.opengis.net/sld" version="1.0.0" xmlns:sld="http://www.opengis.net/sld" xmlns:gml="http://www.opengis.net/gml" xmlns:ogc="http://www.opengis.net/ogc">
  <UserLayer>
    <sld:LayerFeatureConstraints>
      <sld:FeatureTypeConstraint/>
    </sld:LayerFeatureConstraints>
    <sld:UserStyle>
      <sld:Name>LAYER_NAME</sld:Name>
      <sld:FeatureTypeStyle>
        <sld:Rule>
          <sld:RasterSymbolizer>
            <sld:ChannelSelection>
              <sld:GrayChannel>
                <sld:SourceChannelName>1</sld:SourceChannelName>
              </sld:GrayChannel>
            </sld:ChannelSelection>
            <sld:ColorMap type="values">';
    part_2 text :='';
	  new_row text;
    part_3 text := '
            </sld:ColorMap>
          </sld:RasterSymbolizer>
        </sld:Rule>
      </sld:FeatureTypeStyle>
    </sld:UserStyle>
  </UserLayer>
</StyledLayerDescriptor>';
BEGIN
    FOR rec IN SELECT dataset_id, version FROM metadata.version ORDER BY dataset_id, version
    LOOP
	
      FOR sub_rec IN SELECT code, value, color, opacity, label FROM metadata.layer_category WHERE dataset_id = rec.dataset_id AND version = rec.version AND publish IS TRUE ORDER BY value
    	LOOP
		
			SELECT E'\n             <sld:ColorMapEntry quantity="' ||sub_rec.value|| '" color="' ||sub_rec.color|| '" opacity="' ||sub_rec.opacity|| '" label="' ||sub_rec.code||' - '||sub_rec.label|| '"/>' INTO new_row;

			SELECT part_2 || new_row INTO part_2;
		
		END LOOP;
		
		  UPDATE metadata.version SET sld = replace(part_1,'LAYER_NAME',rec.layer_id) || part_2 || part_3 WHERE dataset_id = rec.dataset_id AND version = rec.version;
		  SELECT '' INTO part_2;
		  SELECT '' INTO new_row;
		  
	END LOOP;
    RETURN NEW;
END
$BODY$;
ALTER FUNCTION metadata.sld() OWNER TO glosis;


--------------------------
--        TABLE         --
--------------------------

CREATE TABLE metadata.dataset (
    dataset_id text NOT NULL,
    dataset_name text,
    dataset_description text,
    complete boolean
);
ALTER TABLE metadata.dataset OWNER TO glosis;
GRANT SELECT ON TABLE metadata.dataset TO glosis_r;


CREATE TABLE metadata.version (
    dataset_id text NOT NULL,
    version text NOT NULL,
    folder text,
    file_identifier uuid DEFAULT public.uuid_generate_v1(),
    language_code text,
    parent_identifier uuid,
    metadata_standard_name text,
    metadata_standard_version text,
    reference_system_identifier_code text,
    reference_system_identifier_code_space text,
    title text,
    creation_date date,
    publication_date date,
    revision_date date,
    edition text,
    citation_rs_identifier_code text,
    citation_rs_identifier_code_space text,
    citation_md_identifier_code text,
    abstract text,
    status text,
    md_browse_graphic text,
    keyword_theme text[],
    keyword_place text[],
    keyword_stratum text[],
    access_constraints text,
    use_constraints text,
    other_constraints text,
    spatial_representation_type_code text,
    distance_uom text,
    distance text,
    topic_category text[],
    time_period_begin date,
    time_period_end date,
    west_bound_longitude numeric(4,1),
    east_bound_longitude numeric(4,1),
    south_bound_latitude numeric(4,1),
    north_bound_latitude numeric(4,1),
    distribution_format text,
    scope_code text DEFAULT 'dataset'::text,
    lineage_statement text,
    lineage_source_uuidref text,
    lineage_source_title text,
    representation_type text,
    presentation_form text DEFAULT 'mapDigital'::text,
    CONSTRAINT version_status_check CHECK ((status = ANY (ARRAY['Completed'::text, 'Historical archive'::text, 'Obsolete'::text, 'On going'::text, 'Planned'::text, 'Required'::text, 'Under development'::text]))),
    CONSTRAINT version_representation_type_check CHECK ((representation_type = ANY (ARRAY['Grid'::text, 'Vector'::text, 'Tabular'::text])))
);
ALTER TABLE metadata.version OWNER TO glosis;
GRANT SELECT ON TABLE metadata.version TO glosis_r;


CREATE TABLE metadata.layer (
    dataset_id text NOT NULL,
    version text NOT NULL,
    layer text NOT NULL,
    file_name text NOT NULL,
    file_mode text,
    file_ino integer,
    file_dev integer,
    file_nlink integer,
    file_uid integer,
    file_gid integer,
    file_size bigint,
    file_size_pretty text,
    file_atime timestamp without time zone,
    file_mtime timestamp without time zone,
    file_ctime timestamp without time zone,
    format text,
    raster_size_row integer,
    raster_size_col integer,
    coordinate_system smallint,
    spatial_reference text,
    spatial_reference_proj text,
    projection text,
    geo_transform text,
    origin_x text,
    pixel_size text,
    metadata text,
    compression text,
    corner_coordinates_center text,
    n_bands smallint,
    band_number smallint,
    band_block text,
    data_type_id text,
    band_size_row integer,
    band_size_col integer,
    scale text,
    stats_minimum numeric(10,3),
    stats_maximum numeric(10,3),
    stats_mean numeric(10,3),
    stats_std_dev numeric(10,3),
    no_data_value integer,
    overviews text,
    color_table text,
    root_file text,
    mask_value integer,
    resample_method text,
    json text
);
ALTER TABLE metadata.layer OWNER TO glosis;
GRANT SELECT ON TABLE metadata.layer TO glosis_r;
COMMENT ON COLUMN metadata.layer.geo_transform IS 'X Origin (top left corner), X pixel size (W-E pizel resolution), Rotation (0 if north is up), Y Origin (top left corner), Rotation (0 if north is up), -Y pixel size (N-S pixel resolution)';


CREATE TABLE IF NOT EXISTS metadata.layer_category
(   
    dataset_id text NOT NULL,
    version text NOT NULL,
    layer text NOT NULL,
    value smallint NOT NULL,
    code text COLLATE pg_catalog."default" NOT NULL,
    label text COLLATE pg_catalog."default" NOT NULL,
    color text COLLATE pg_catalog."default" NOT NULL,
    opacity real NOT NULL,
    publish boolean NOT NULL
);
ALTER TABLE metadata.layer_category OWNER TO glosis;
GRANT SELECT ON TABLE metadata.layer_category TO glosis_r;


CREATE TABLE metadata.ver_x_org_x_ind (
    dataset_id text NOT NULL,
    version text NOT NULL,
    tag text,
    role text,
    position text,
    organisation_id text NOT NULL,
    individual_id text
    CONSTRAINT contact_tag_check CHECK ((tag = ANY (ARRAY['Author'::text, 'Custodian'::text, 'Distributor'::text, 'Originator'::text, 'Owner'::text, 'Point of contact'::text, 'Principal investigator'::text, 'Processor'::text, 'Publisher'::text, 'Resource provider'::text, 'User'::text])))
);
ALTER TABLE metadata.ver_x_org_x_ind OWNER TO glosis;
GRANT SELECT ON TABLE metadata.ver_x_org_x_ind TO glosis_r;


CREATE TABLE metadata.organisation (
    organisation_id text NOT NULL,
    url text,
    email text,
    country text,
    city text,
    postal_code text,
    delivery_point text,
    phone text,
    facsimile text
);
ALTER TABLE metadata.organisation OWNER TO glosis;
GRANT SELECT ON TABLE metadata.organisation TO glosis_r;


CREATE TABLE metadata.individual (
    individual_id text NOT NULL,
    email text    
);
ALTER TABLE metadata.individual OWNER TO glosis;
GRANT SELECT ON TABLE metadata.individual TO glosis_r;


CREATE TABLE metadata.url (
    url_id serial,
    dataset_id text NOT NULL,
    version text NOT NULL,
    protocol text,
    url text NOT NULL,
    url_name text,
    valid text
    CONSTRAINT url_protocol_check CHECK ((protocol = ANY (ARRAY['link'::text, 'ftp'::text, 'wms'::text, 'wcs'::text, 'wfs'::text])))
);
ALTER TABLE metadata.url OWNER TO glosis;
GRANT SELECT ON TABLE metadata.url TO glosis_r;


--------------------------
--     PRIMARY KEY      --
--------------------------

ALTER TABLE metadata.dataset ADD PRIMARY KEY (dataset_id);
ALTER TABLE metadata.version ADD PRIMARY KEY (dataset_id, version);
ALTER TABLE metadata.version ADD UNIQUE (file_identifier);
ALTER TABLE metadata.layer ADD PRIMARY KEY (dataset_id, version, layer);
ALTER TABLE metadata.layer_category ADD PRIMARY KEY (dataset_id, version, layer, value);
ALTER TABLE metadata.ver_x_org_x_ind ADD PRIMARY KEY (dataset_id, version, tag, role, position, organisation_id, individual_id);
ALTER TABLE metadata.organisation ADD PRIMARY KEY (organisation_id);
ALTER TABLE metadata.individual ADD PRIMARY KEY (individual_id);
ALTER TABLE metadata.url ADD PRIMARY KEY (url_id);


--------------------------
--     FOREIGN KEY      --
--------------------------

ALTER TABLE metadata.ver_x_org_x_ind ADD FOREIGN KEY (individual_id) REFERENCES metadata.individual(individual_id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE metadata.ver_x_org_x_ind ADD FOREIGN KEY (organisation_id) REFERENCES metadata.organisation(organisation_id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE metadata.ver_x_org_x_ind ADD FOREIGN KEY (dataset_id, version) REFERENCES metadata.version(dataset_id, version) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE metadata.url ADD FOREIGN KEY (dataset_id, version) REFERENCES metadata.version(dataset_id, version) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE metadata.layer ADD FOREIGN KEY (dataset_id, version) REFERENCES metadata.version(dataset_id, version) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE metadata.layer_category ADD FOREIGN KEY (dataset_id, version, layer) REFERENCES metadata.layer(dataset_id, version, layer) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE metadata.version ADD FOREIGN KEY (dataset_id) REFERENCES metadata.dataset(dataset_id) ON UPDATE CASCADE ON DELETE CASCADE;


--------------------------
--       TRIGGER        --
--------------------------

CREATE TRIGGER map
    AFTER INSERT OR DELETE OR UPDATE 
    ON metadata.layer_category
    FOR EACH STATEMENT
    EXECUTE FUNCTION metadata.map();

CREATE TRIGGER qml
    AFTER INSERT OR DELETE OR UPDATE 
    ON metadata.layer_category
    FOR EACH STATEMENT
    EXECUTE FUNCTION metadata.qml();

CREATE TRIGGER sld
    AFTER INSERT OR DELETE OR UPDATE 
    ON metadata.layer_category
    FOR EACH STATEMENT
    EXECUTE FUNCTION metadata.sld();
