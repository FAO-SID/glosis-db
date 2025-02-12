-- DROP SCHEMA IF EXISTS metadata CASCADE;
CREATE SCHEMA metadata;
ALTER SCHEMA metadata OWNER TO glosis;
COMMENT ON SCHEMA metadata IS 'Schema for glosis metadata';
GRANT USAGE ON SCHEMA metadata TO glosis_r;


--------------------------
--      FUNCTION        --
--------------------------

-- CREATE OR REPLACE FUNCTION metadata.create_category(
--     mapset TEXT, 
--     num_intervals INT DEFAULT 10, 
--     start_color TEXT DEFAULT '#F4E7D3', 
--     end_color TEXT DEFAULT '#5C4033'
-- )
-- RETURNS VOID AS $$
-- DECLARE
--     min_value FLOAT;
--     max_value FLOAT;
--     range FLOAT;
--     interval_size FLOAT;
--     current_min FLOAT;
--     current_max FLOAT;
--     i INT := 1;
--     start_r INT;
--     start_g INT;
--     start_b INT;
--     end_r INT;
--     end_g INT;
--     end_b INT;
--     color TEXT;
-- BEGIN
--     -- Validate num_intervals
--     IF num_intervals <= 0 THEN
--         RAISE EXCEPTION 'Number of intervals must be greater than 0.';
--     END IF;

--     -- Validate start_color and end_color
--     IF start_color NOT LIKE '#______' OR end_color NOT LIKE '#______' THEN
--         RAISE EXCEPTION 'Colors must be in HEX format (e.g., #F4E7D3).';
--     END IF;

--     -- Fetch min_value and max_value from the observations table for the given mapset_id
--     SELECT min(stats_minimum), max(stats_maximum) INTO min_value, max_value
--     FROM metadata.layer
--     WHERE mapset_id = mapset
--     GROUP BY mapset_id;

--     -- Check if mapset_id exists
--     IF min_value IS NULL OR max_value IS NULL THEN
--         RAISE EXCEPTION 'mapset_id % does not exist or has no data.', mapset;
--     END IF;

--     -- Calculate the range and interval size
--     range := max_value - min_value;
--     IF range = 0 THEN
--         RAISE EXCEPTION 'Range is 0. Cannot create intervals for mapset_id %.', mapset;
--     END IF;
--     interval_size := range / num_intervals;
--     current_min := min_value;
--     current_max := min_value + interval_size;

--     -- Extract RGB components from start_color and end_color
--     start_r := ('x' || SUBSTRING(start_color FROM 2 FOR 2))::BIT(8)::INT;
--     start_g := ('x' || SUBSTRING(start_color FROM 4 FOR 2))::BIT(8)::INT;
--     start_b := ('x' || SUBSTRING(start_color FROM 6 FOR 2))::BIT(8)::INT;
--     end_r := ('x' || SUBSTRING(end_color FROM 2 FOR 2))::BIT(8)::INT;
--     end_g := ('x' || SUBSTRING(end_color FROM 4 FOR 2))::BIT(8)::INT;
--     end_b := ('x' || SUBSTRING(end_color FROM 6 FOR 2))::BIT(8)::INT;

--     -- Loop to create intervals
--     WHILE i <= num_intervals LOOP
--         -- Interpolate the color based on the interval index
--         color := '#' || 
--                  LPAD(TO_HEX(start_r + (end_r - start_r) * (i - 1) / (num_intervals - 1)), 2, '0') ||
--                  LPAD(TO_HEX(start_g + (end_g - start_g) * (i - 1) / (num_intervals - 1)), 2, '0') ||
--                  LPAD(TO_HEX(start_b + (end_b - start_b) * (i - 1) / (num_intervals - 1)), 2, '0');

--         -- Insert the class interval and color into the categories table
--         INSERT INTO metadata.layer_category (mapset_id, value, code, "label", color, opacity, publish)
--         VALUES (mapset, current_min::numeric(10,2), 
--                current_min::numeric(10,2) || ' - ' || current_max::numeric(10,2), 
--                current_min::numeric(10,2) || ' - ' || current_max::numeric(10,2), 
--                color, 1, 't');

--         -- Update the current_min and current_max for the next interval
--         current_min := current_max;
--         current_max := current_max + interval_size;
--         i := i + 1;
--     END LOOP;
-- END;
-- $$ LANGUAGE plpgsql;


--------------------------------
--     TRIGGER FUNCTION       --
--------------------------------

CREATE OR REPLACE FUNCTION metadata.category()
RETURNS TRIGGER AS $$
DECLARE
    range FLOAT;
    interval_size FLOAT;
    current_min FLOAT;
    current_max FLOAT;
    i INT := 1;
    start_r INT;
    start_g INT;
    start_b INT;
    end_r INT;
    end_g INT;
    end_b INT;
    color TEXT;
BEGIN

  -- Only when variable_type is quantitative
  IF NEW.variable_type = 'quantitative' THEN

    -- Validate num_intervals
    IF NEW.category_num_intervals <= 0 THEN
        RAISE EXCEPTION 'Number of intervals must be greater than 0.';
    END IF;

    -- Validate category_start_color and category_end_color
    IF NEW.category_start_color NOT LIKE '#______' OR NEW.category_end_color NOT LIKE '#______' THEN
        RAISE EXCEPTION 'Colors must be in HEX format (e.g., #F4E7D3).';
    END IF;

    -- Check if stats_minimum and max_stats_maximum are valid
    IF NEW.min_stats_minimum IS NULL OR NEW.max_stats_maximum IS NULL THEN
        RAISE EXCEPTION 'min_stats_minimum and max_stats_maximum must not be NULL.';
    END IF;

    -- Calculate the range and interval size
    range := NEW.max_stats_maximum - NEW.min_stats_minimum;
    IF range = 0 THEN
        RAISE EXCEPTION 'Range is 0. Cannot create intervals for layer_id %.', NEW.layer_id;
    END IF;
    interval_size := range / NEW.category_num_intervals;
    current_min := NEW.min_stats_minimum;
    current_max := NEW.min_stats_minimum + interval_size;

    -- Delete existing rows for this mapset_id
    DELETE FROM metadata.layer_category WHERE mapset_id = NEW.mapset_id;

    -- Extract RGB components from category_start_color and category_end_color
    start_r := ('x' || SUBSTRING(NEW.category_start_color FROM 2 FOR 2))::BIT(8)::INT;
    start_g := ('x' || SUBSTRING(NEW.category_start_color FROM 4 FOR 2))::BIT(8)::INT;
    start_b := ('x' || SUBSTRING(NEW.category_start_color FROM 6 FOR 2))::BIT(8)::INT;
    end_r := ('x' || SUBSTRING(NEW.category_end_color FROM 2 FOR 2))::BIT(8)::INT;
    end_g := ('x' || SUBSTRING(NEW.category_end_color FROM 4 FOR 2))::BIT(8)::INT;
    end_b := ('x' || SUBSTRING(NEW.category_end_color FROM 6 FOR 2))::BIT(8)::INT;

    -- Loop to create intervals
    WHILE i <= NEW.category_num_intervals LOOP
        -- Interpolate the color based on the interval index
        color := '#' || 
                LPAD(TO_HEX(start_r + (end_r - start_r) * (i - 1) / (NEW.category_num_intervals - 1)), 2, '0') ||
                LPAD(TO_HEX(start_g + (end_g - start_g) * (i - 1) / (NEW.category_num_intervals - 1)), 2, '0') ||
                LPAD(TO_HEX(start_b + (end_b - start_b) * (i - 1) / (NEW.category_num_intervals - 1)), 2, '0');

        -- Insert the class interval and color into the categories table
        INSERT INTO metadata.layer_category (mapset_id, value, code, "label", color, opacity, publish)
        VALUES (NEW.mapset_id, current_min::numeric(10,2), 
              current_min::numeric(10,2) || ' - ' || current_max::numeric(10,2), 
              current_min::numeric(10,2) || ' - ' || current_max::numeric(10,2), 
              color, 1, 't')
        ON CONFLICT (mapset_id, value)
        DO UPDATE SET
            code = EXCLUDED.code,
            label = EXCLUDED.label,
            color = EXCLUDED.color,
            opacity = EXCLUDED.opacity,
            publish = EXCLUDED.publish;

        -- Update the current_min and current_max for the next interval
        current_min := current_max;
        current_max := current_max + interval_size;
        i := i + 1;
    END LOOP;
  END IF;
  -- Return the NEW row for the trigger
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;


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
    FOR rec IN SELECT project_id, version, title, epsg::text, units, extent FROM metadata.version ORDER BY project_id, version
    LOOP
	
      FOR sub_rec IN SELECT value, color, (opacity*100)::int AS opacity, label FROM metadata.layer_category WHERE project_id = rec.project_id AND version = rec.version AND publish IS TRUE ORDER BY value
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
												  , 'LAYER_PROJECT', rec.project_id)
												  , 'LAYER_ID', rec.layer_id) || part_2 || part_3
			WHERE project_id = rec.project_id AND version = rec.version;
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
    FOR rec IN SELECT mapset_id FROM metadata.layer ORDER BY mapset_id
    LOOP
	
      FOR sub_rec IN SELECT code, value, color, (opacity*255)::int AS alpha, label FROM metadata.layer_category WHERE mapset_id = rec.mapset_id AND publish IS TRUE ORDER BY value
    	LOOP

			SELECT E'\n        <paletteEntry value="' ||sub_rec.value|| '" color="' ||sub_rec.color|| '" alpha="' ||sub_rec.alpha|| '" label="' ||sub_rec.label|| '"/>' INTO new_row;

			SELECT part_2 || new_row INTO part_2;
		
		END LOOP;
		
		  UPDATE metadata.mapset SET qml = part_1 || part_2 || part_3 WHERE mapset_id = rec.mapset_id;
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
            <sld:ColorMap type="VARIABLE_TYPE">';
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
    FOR rec IN SELECT mapset_id, 
                CASE WHEN variable_type='categorical'  THEN 'values'
                    WHEN variable_type='quantitative' THEN 'intervals'
                    END variable_type
                FROM metadata.mapset ORDER BY mapset_id
    LOOP
	
      FOR sub_rec IN SELECT code, value, color, opacity, label FROM metadata.layer_category WHERE mapset_id = rec.mapset_id AND publish IS TRUE ORDER BY value
    	LOOP
		
			SELECT E'\n             <sld:ColorMapEntry quantity="' ||sub_rec.value|| '" color="' ||sub_rec.color|| '" opacity="' ||sub_rec.opacity|| '" label="' ||sub_rec.label|| '"/>' INTO new_row;

			SELECT part_2 || new_row INTO part_2;
		
		END LOOP;
		
		  UPDATE metadata.mapset SET sld = replace(replace(part_1,'LAYER_NAME',rec.mapset_id),'VARIABLE_TYPE',rec.variable_type) || part_2 || part_3 WHERE mapset_id = rec.mapset_id;
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

CREATE TABLE metadata.project (
  project_id text NOT NULL,
  project_name text,
  project_description text
);
ALTER TABLE metadata.project OWNER TO glosis;
GRANT SELECT ON TABLE metadata.project TO glosis_r;


CREATE TABLE metadata.mapset (
  project_id text NOT NULL,
  mapset_id text NOT NULL,
  dimension text DEFAULT 'depth',
  parent_identifier uuid,
  file_identifier uuid DEFAULT public.uuid_generate_v1(),
  language_code text DEFAULT 'eng',
  metadata_standard_name text DEFAULT 'ISO 19115/19139',
  metadata_standard_version text DEFAULT '1.0',
  reference_system_identifier_code text,
  reference_system_identifier_code_space text DEFAULT 'EPSG',
  title text,
  creation_date date,
  publication_date date,
  revision_date date,
  edition text,
  citation_md_identifier_code text,
  citation_md_identifier_code_space text DEFAULT 'doi',
  abstract text,
  status text DEFAULT 'completed',
  update_frequency text DEFAULT 'asNeeded',
  md_browse_graphic text,
  keyword_theme text[],
  keyword_place text[],
  keyword_discipline text[] DEFAULT '{Soil science}'::text[],
  access_constraints text DEFAULT 'copyright',
  use_constraints text DEFAULT 'license',
  other_constraints text,
  spatial_representation_type_code text DEFAULT 'grid',
  presentation_form text DEFAULT 'mapDigital',
  distance_uom text,
  topic_category text[] DEFAULT '{geoscientificInformation,environment}'::text[],
  time_period_begin date,
  time_period_end date,
  scope_code text DEFAULT 'project',
  lineage_statement text,
  lineage_source_uuidref text,
  lineage_source_title text,
  variable_type text DEFAULT 'quantitative',
  category_num_intervals INT DEFAULT 10, 
  category_start_color text DEFAULT '#F4E7D3', 
  category_end_color text DEFAULT '#5C4033',
  min_stats_minimum real DEFAULT -12345,
  max_stats_maximum real DEFAULT 12345,
  map text,
  sld text,
  xml text,
  CONSTRAINT mapset_dimension_check CHECK ((dimension = ANY (ARRAY['depth', 'time']))),
  CONSTRAINT mapset_citation_md_identifier_code_space_check CHECK ((citation_md_identifier_code_space = ANY (ARRAY['doi', 'uuid']))),
  CONSTRAINT mapset_status_check CHECK ((status = ANY (ARRAY['completed', 'historicalArchive', 'obsolete', 'onGoing', 'planned', 'required', 'underDevelopment']))),
  CONSTRAINT mapset_update_frequency_check CHECK ((update_frequency = ANY (ARRAY['continual', 'daily', 'weekly', 'fortnightly', 'monthly', 'quarterly', 'biannually','annually','asNeeded','irregular','notPlanned','unknown']))),
  CONSTRAINT mapset_access_constraints_check CHECK ((access_constraints = ANY (ARRAY['copyright', 'patent', 'patentPending', 'trademark', 'license', 'intellectualPropertyRights', 'restricted','otherRestrictions']))),
  CONSTRAINT mapset_use_constraints_check CHECK ((use_constraints = ANY (ARRAY['copyright', 'patent', 'patentPending', 'trademark', 'license', 'intellectualPropertyRights', 'restricted','otherRestrictions']))),
  CONSTRAINT mapset_spatial_representation_type_code_check CHECK ((spatial_representation_type_code = ANY (ARRAY['grid', 'vector', 'textTable', 'tin', 'stereoModel', 'video']))),
  CONSTRAINT mapset_presentation_form_check CHECK ((presentation_form = ANY (ARRAY['mapDigital', 'tableDigital', 'mapHardcopy', 'atlasHardcopy']))),
  CONSTRAINT mapset_distance_uom_check CHECK ((distance_uom = ANY (ARRAY['m', 'km', 'deg']))),
  CONSTRAINT mapset_variable_type_check CHECK ((variable_type = ANY (ARRAY['quantitative', 'categorical'])))
);
ALTER TABLE metadata.mapset OWNER TO glosis;
GRANT SELECT ON TABLE metadata.mapset TO glosis_r;


CREATE TABLE metadata.layer (
  mapset_id text NOT NULL,
  dimension_des text,
  file_path text NOT NULL,
  layer_id text NOT NULL,
  file_extension text,
  file_size integer,
  file_size_pretty text,
  reference_layer boolean DEFAULT FALSE,
  -- from layer_scan.py
  reference_system_identifier_code text,
  distance text,
  extent text,
  west_bound_longitude numeric(4,1),
  east_bound_longitude numeric(4,1),
  south_bound_latitude numeric(4,1),
  north_bound_latitude numeric(4,1),
  distribution_format text,
  -- extra metadata
  compression text,
  raster_size_x real,
  raster_size_y real,
  pixel_size_x real,
  pixel_size_y real,
  origin_x real,
  origin_y real,
  spatial_reference text,
  data_type text,
  no_data_value float,
  stats_minimum real,
  stats_maximum real,
  stats_mean real,
  stats_std_dev real,
  scale text,
  n_bands integer,
  metadata text[]
);
ALTER TABLE metadata.layer OWNER TO glosis;
GRANT SELECT ON TABLE metadata.layer TO glosis_r;


CREATE TABLE metadata.layer_manual_metadata (
  mapset_id	text,
  title text,
  creation_date text,
  revision_date text,
  publication_date text,
  abstract text,
  keyword_theme text[],
  keyword_place text[],
  update_frequency text,
  access_constraints text,
  use_constraints text,
  other_constraints text,
  distance_uom text,
  time_period_begin text,
  time_period_end text,
  citation_md_identifier_code text,
  lineage_statement text,
  organisation_id text,
  url text,
  organisation_email text,
  country text,
  city text,
  postal_code text,
  delivery_point text,
  individual_id text,
  email text,
  position text,
  url_paper text,
  url_project text
);
ALTER TABLE metadata.layer_manual_metadata OWNER TO glosis;
GRANT SELECT ON TABLE metadata.layer_manual_metadata TO glosis_r;


CREATE TABLE IF NOT EXISTS metadata.layer_category
(   
  mapset_id text NOT NULL,
  value real NOT NULL,
  code text COLLATE pg_catalog."default" NOT NULL,
  label text COLLATE pg_catalog."default" NOT NULL,
  color text COLLATE pg_catalog."default" NOT NULL,
  opacity real NOT NULL,
  publish boolean NOT NULL
);
ALTER TABLE metadata.layer_category OWNER TO glosis;
GRANT SELECT ON TABLE metadata.layer_category TO glosis_r;


CREATE TABLE metadata.ver_x_org_x_ind (
  mapset_id text NOT NULL,
  tag text,
  role text,
  position text,
  organisation_id text NOT NULL,
  individual_id text
  CONSTRAINT ver_x_org_x_ind_tag_check CHECK ((tag = ANY (ARRAY['contact', 'pointOfContact'])))
  CONSTRAINT ver_x_org_x_ind_role_check CHECK ((role = ANY (ARRAY['author', 'custodian', 'distributor', 'originator', 'owner', 'pointOfContact', 'principalInvestigator', 'processor', 'publisher', 'resourceProvider', 'user'])))
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
  mapset_id text NOT NULL,
  protocol text NOT NULL,
  url text NOT NULL,
  url_name text NOT NULL
  CONSTRAINT url_protocol_check CHECK ((protocol = ANY (ARRAY['OGC:WMS','OGC:WMTS','WWW:LINK-1.0-http--link', 'WWW:LINK-1.0-http--related'])))
);
ALTER TABLE metadata.url OWNER TO glosis;
GRANT SELECT ON TABLE metadata.url TO glosis_r;


--------------------------
--     PRIMARY KEY      --
--------------------------

ALTER TABLE metadata.project ADD PRIMARY KEY (project_id);
ALTER TABLE metadata.mapset ADD PRIMARY KEY (mapset_id);
ALTER TABLE metadata.mapset ADD UNIQUE (file_identifier);
ALTER TABLE metadata.layer ADD PRIMARY KEY (layer_id);
ALTER TABLE metadata.layer_manual_metadata ADD PRIMARY KEY (mapset_id);
ALTER TABLE metadata.layer_category ADD PRIMARY KEY (mapset_id, value);
ALTER TABLE metadata.ver_x_org_x_ind ADD PRIMARY KEY (mapset_id, tag, role, position, organisation_id, individual_id);
ALTER TABLE metadata.organisation ADD PRIMARY KEY (organisation_id);
ALTER TABLE metadata.individual ADD PRIMARY KEY (individual_id);
ALTER TABLE metadata.url ADD PRIMARY KEY (mapset_id, protocol, url);


--------------------------
--     FOREIGN KEY      --
--------------------------

ALTER TABLE metadata.ver_x_org_x_ind ADD FOREIGN KEY (individual_id) REFERENCES metadata.individual(individual_id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE metadata.ver_x_org_x_ind ADD FOREIGN KEY (organisation_id) REFERENCES metadata.organisation(organisation_id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE metadata.ver_x_org_x_ind ADD FOREIGN KEY (mapset_id) REFERENCES metadata.mapset(mapset_id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE metadata.url ADD FOREIGN KEY (mapset_id) REFERENCES metadata.mapset(mapset_id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE metadata.layer_category ADD FOREIGN KEY (mapset_id) REFERENCES metadata.mapset(mapset_id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE metadata.layer ADD FOREIGN KEY (mapset_id) REFERENCES metadata.mapset(mapset_id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE metadata.mapset ADD FOREIGN KEY (project_id) REFERENCES metadata.project(project_id) ON UPDATE CASCADE ON DELETE CASCADE;


--------------------------
--       TRIGGER        --
--------------------------

CREATE TRIGGER category
  AFTER UPDATE OF variable_type, category_num_intervals, category_start_color, category_end_color, min_stats_minimum, max_stats_maximum 
  ON metadata.mapset
  FOR EACH ROW
  EXECUTE FUNCTION metadata.category();

-- CREATE TRIGGER map
--   AFTER INSERT OR DELETE OR UPDATE 
--   ON metadata.layer_category
--   FOR EACH STATEMENT
--   EXECUTE FUNCTION metadata.map();

-- CREATE TRIGGER qml
--   AFTER INSERT OR DELETE OR UPDATE 
--   ON metadata.layer_category
--   FOR EACH STATEMENT
--   EXECUTE FUNCTION metadata.qml();

CREATE TRIGGER sld
  AFTER INSERT OR DELETE OR UPDATE 
  ON metadata.layer_category
  FOR EACH STATEMENT
  EXECUTE FUNCTION metadata.sld();

