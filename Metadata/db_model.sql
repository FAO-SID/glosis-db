-- DROP SCHEMA IF EXISTS metadata CASCADE;
CREATE SCHEMA metadata;
ALTER SCHEMA metadata OWNER TO glosis;
COMMENT ON SCHEMA metadata IS 'Schema for glosis metadata';
GRANT USAGE ON SCHEMA metadata TO glosis_r;


--------------------------------
--     TRIGGER FUNCTION       --
--------------------------------

CREATE OR REPLACE FUNCTION metadata.class()
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

  -- Only when property_type is quantitative
  IF NEW.property_type = 'quantitative' THEN

    -- Validate num_intervals
    IF NEW.num_intervals <= 0 THEN
        RAISE EXCEPTION 'Number of intervals must be greater than 0.';
    END IF;

    -- Validate start_color and end_color
    IF NEW.start_color NOT LIKE '#______' OR NEW.end_color NOT LIKE '#______' THEN
        RAISE EXCEPTION 'Colors must be in HEX format (e.g., #F4E7D3).';
    END IF;

    -- Check if stats_minimum and max are valid
    IF NEW.min IS NULL OR NEW.max IS NULL THEN
        RAISE EXCEPTION 'min and max must not be NULL.';
    END IF;

    -- Calculate the range and interval size
    range := NEW.max - NEW.min;
    IF range = 0 THEN
        RAISE EXCEPTION 'Range is 0. Cannot create intervals for layer_id %.', NEW.layer_id;
    END IF;
    interval_size := range / NEW.num_intervals;
    current_min := NEW.min;
    current_max := NEW.min + interval_size;

    -- Delete existing rows for this property_id
    DELETE FROM metadata.class WHERE property_id = NEW.property_id;

    -- Extract RGB components from start_color and end_color
    start_r := ('x' || SUBSTRING(NEW.start_color FROM 2 FOR 2))::BIT(8)::INT;
    start_g := ('x' || SUBSTRING(NEW.start_color FROM 4 FOR 2))::BIT(8)::INT;
    start_b := ('x' || SUBSTRING(NEW.start_color FROM 6 FOR 2))::BIT(8)::INT;
    end_r := ('x' || SUBSTRING(NEW.end_color FROM 2 FOR 2))::BIT(8)::INT;
    end_g := ('x' || SUBSTRING(NEW.end_color FROM 4 FOR 2))::BIT(8)::INT;
    end_b := ('x' || SUBSTRING(NEW.end_color FROM 6 FOR 2))::BIT(8)::INT;

    -- Loop to create intervals
    WHILE i <= NEW.num_intervals LOOP
        -- Interpolate the color based on the interval index
        color := '#' || 
                LPAD(TO_HEX(start_r + (end_r - start_r) * (i - 1) / (NEW.num_intervals - 1)), 2, '0') ||
                LPAD(TO_HEX(start_g + (end_g - start_g) * (i - 1) / (NEW.num_intervals - 1)), 2, '0') ||
                LPAD(TO_HEX(start_b + (end_b - start_b) * (i - 1) / (NEW.num_intervals - 1)), 2, '0');

        -- Insert the class interval and color into the categories table
        INSERT INTO metadata.class (property_id, value, code, "label", color, opacity, publish)
        VALUES (NEW.property_id, current_min::numeric(10,2), 
              current_min::numeric(10,2) || ' - ' || current_max::numeric(10,2), 
              current_min::numeric(10,2) || ' - ' || current_max::numeric(10,2), 
              color, 1, 't')
        ON CONFLICT (property_id, value)
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
  rec_property RECORD;
  rec_layer RECORD;
BEGIN

SELECT 
	l.layer_id,
  CASE 
    WHEN l.distance_uom='m'  THEN 'METERS'
    WHEN l.distance_uom='km' THEN 'KILOMETERS'
    WHEN l.distance_uom='deg' THEN 'DD'
  END distance_uom,
  l.reference_system_identifier_code,
	l.extent,
	l.file_extension,
	l.stats_minimum,
	l.stats_maximum
INTO rec_layer
FROM metadata.layer l 
WHERE l.mapset_id = NEW.mapset_id;

SELECT m.mapset_id,
  p.start_color,
  p.end_color
INTO rec_property
FROM metadata.mapset m, metadata.property p
WHERE m.property_id = split_part(NEW.mapset_id,'-',3);

UPDATE metadata.layer l SET map = 'MAP
  NAME "'||rec_layer.layer_id||'"
  EXTENT '||rec_layer.extent||'
  UNITS '||rec_layer.distance_uom||'
  SHAPEPATH "./"
  SIZE 800 600
  IMAGETYPE "PNG24"
  PROJECTION
      "init=epsg:'||rec_layer.reference_system_identifier_code||'"
  END # PROJECTION
  WEB
      METADATA
          "ows_title" "'||rec_property.mapset_id||' web-service" 
          "ows_enable_request" "*" 
          "ows_srs" "EPSG:'||rec_layer.reference_system_identifier_code||' EPSG:4326 EPSG:3857"
          "ows_getfeatureinfo_formatlist" "text/plain,text/html,application/json,geojson,application/vnd.ogc.gml,gml"
		  "wms_feature_info_mime_type" "text/plain,text/html"
      END # METADATA
  END # WEB
  LAYER
      TEMPLATE "getfeatureinfo_template.tmpl"
      NAME "'||rec_property.mapset_id||'"
      DATA "'||rec_layer.layer_id||'.'||rec_layer.file_extension||'"
      TYPE RASTER
      STATUS ON
      CLASS
        NAME "'||rec_layer.layer_id||'"
        STYLE
            COLORRANGE "'||rec_property.start_color||'" "'||rec_property.end_color||'"  # Start and end colors (blue to brown)
            DATARANGE '||rec_layer.stats_minimum||' '||rec_layer.stats_maximum||'
            RANGEITEM "pixel"
          END # STYLE
      END # CLASS
  END # LAYER
END # MAP'
WHERE l.mapset_id = NEW.mapset_id;

  RETURN NEW;
END
$BODY$;
ALTER FUNCTION metadata.map() OWNER TO glosis;


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
            <sld:ColorMap type="property_type">';
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
    FOR rec IN SELECT property_id, 
                CASE WHEN property_type='categorical'  THEN 'values'
                    WHEN property_type='quantitative' THEN 'intervals'
                    END property_type
                FROM metadata.property ORDER BY property_id
    LOOP
	
      FOR sub_rec IN SELECT code, value, color, opacity, label FROM metadata.class WHERE property_id = rec.property_id AND publish IS TRUE ORDER BY value
    	LOOP
		
			SELECT E'\n             <sld:ColorMapEntry quantity="' ||sub_rec.value|| '" color="' ||sub_rec.color|| '" opacity="' ||sub_rec.opacity|| '" label="' ||sub_rec.label|| '"/>' INTO new_row;

			SELECT part_2 || new_row INTO part_2;
		
		END LOOP;
		
		  UPDATE metadata.property SET sld = replace(replace(part_1,'LAYER_NAME',rec.property_id),'property_type',rec.property_type) || part_2 || part_3 WHERE property_id = rec.property_id;
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

CREATE TABLE metadata.country (
	country_id bpchar(2) NOT NULL,
	iso3_code bpchar(3) NULL,
	gaul_code int4 NULL,
	color_code bpchar(3) NULL,
	ar text NULL,
	en text NULL,
	es text NULL,
	fr text NULL,
	pt text NULL,
	ru text NULL,
	zh text NULL,
	status text NULL,
	disp_area varchar(3) NULL,
	capital text NULL,
	continent text NULL,
	un_reg text NULL,
	unreg_note text NULL,
	continent_custom text NULL
);
ALTER TABLE metadata.country OWNER TO glosis;
GRANT SELECT ON TABLE metadata.country TO glosis_r;


CREATE TABLE metadata.project (
  country_id text NOT NULL,
  project_id text NOT NULL,
  project_name text,
  project_description text
);
ALTER TABLE metadata.project OWNER TO glosis;
GRANT SELECT ON TABLE metadata.project TO glosis_r;


CREATE TABLE metadata.mapset (
  country_id text NOT NULL,
  project_id text NOT NULL,
  property_id text NOT NULL,
  mapset_id text NOT NULL,
  dimension text DEFAULT 'depth',
  parent_identifier uuid,
  file_identifier uuid DEFAULT public.uuid_generate_v1(),
  language_code text DEFAULT 'eng',
  metadata_standard_name text DEFAULT 'ISO 19115/19139',
  metadata_standard_version text DEFAULT '1.0',
  reference_system_identifier_code_space text DEFAULT 'EPSG',
  title text,
  unit_id text,
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
  topic_category text[] DEFAULT '{geoscientificInformation,environment}'::text[],
  time_period_begin date,
  time_period_end date,
  scope_code text DEFAULT 'dataset',
  lineage_statement text,
  lineage_source_uuidref text,
  lineage_source_title text,
  -- property_type text DEFAULT 'quantitative',
  -- num_intervals INT DEFAULT 10, 
  -- start_color text DEFAULT '#F4E7D3', 
  -- end_color text DEFAULT '#5C4033',
  -- min real DEFAULT -12345,
  -- max real DEFAULT 12345,
  -- sld text,
  xml text,
  CONSTRAINT mapset_dimension_check CHECK ((dimension = ANY (ARRAY['depth', 'time']))),
  CONSTRAINT mapset_citation_md_identifier_code_space_check CHECK ((citation_md_identifier_code_space = ANY (ARRAY['doi', 'uuid']))),
  CONSTRAINT mapset_status_check CHECK ((status = ANY (ARRAY['completed', 'historicalArchive', 'obsolete', 'onGoing', 'planned', 'required', 'underDevelopment']))),
  CONSTRAINT mapset_update_frequency_check CHECK ((update_frequency = ANY (ARRAY['continual', 'daily', 'weekly', 'fortnightly', 'monthly', 'quarterly', 'biannually','annually','asNeeded','irregular','notPlanned','unknown']))),
  CONSTRAINT mapset_access_constraints_check CHECK ((access_constraints = ANY (ARRAY['copyright', 'patent', 'patentPending', 'trademark', 'license', 'intellectualPropertyRights', 'restricted','otherRestrictions']))),
  CONSTRAINT mapset_use_constraints_check CHECK ((use_constraints = ANY (ARRAY['copyright', 'patent', 'patentPending', 'trademark', 'license', 'intellectualPropertyRights', 'restricted','otherRestrictions']))),
  CONSTRAINT mapset_spatial_representation_type_code_check CHECK ((spatial_representation_type_code = ANY (ARRAY['grid', 'vector', 'textTable', 'tin', 'stereoModel', 'video']))),
  CONSTRAINT mapset_presentation_form_check CHECK ((presentation_form = ANY (ARRAY['mapDigital', 'tableDigital', 'mapHardcopy', 'atlasHardcopy'])))
);
ALTER TABLE metadata.mapset OWNER TO glosis;
GRANT SELECT ON TABLE metadata.mapset TO glosis_r;

CREATE TABLE metadata.property (
  property_id text NOT NULL,
  name text,
  unit_id text,
  min real,
  max real,
  uri text,
  property_type text NOT NULL,
  num_intervals smallint NOT NULL, 
  start_color text NOT NULL, 
  end_color text NOT NULL,
  sld text,
  CONSTRAINT property_property_type_check CHECK ((property_type = ANY (ARRAY['quantitative', 'categorical'])))
);
ALTER TABLE metadata.property OWNER TO glosis;
GRANT SELECT ON TABLE metadata.property TO glosis_r;


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
  distance_uom text,
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
  metadata text[],
  map text,
  CONSTRAINT layer_distance_uom_check CHECK ((distance_uom = ANY (ARRAY['m', 'km', 'deg'])))
);
ALTER TABLE metadata.layer OWNER TO glosis;
GRANT SELECT ON TABLE metadata.layer TO glosis_r;


CREATE TABLE metadata.metadata_manual (
  mapset_id	text,
  title text,
  unit_id text,
  creation_date text,
  revision_date text,
  publication_date text,
  abstract text,
  keyword_theme text[],
  keyword_place text[],
  access_constraints text,
  use_constraints text,
  other_constraints text,
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
ALTER TABLE metadata.metadata_manual OWNER TO glosis;
GRANT SELECT ON TABLE metadata.metadata_manual TO glosis_r;


CREATE TABLE IF NOT EXISTS metadata.class
(   
  property_id text NOT NULL,
  value real NOT NULL,
  code text COLLATE pg_catalog."default" NOT NULL,
  label text COLLATE pg_catalog."default" NOT NULL,
  color text COLLATE pg_catalog."default" NOT NULL,
  opacity real NOT NULL,
  publish boolean NOT NULL
);
ALTER TABLE metadata.class OWNER TO glosis;
GRANT SELECT ON TABLE metadata.class TO glosis_r;


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

ALTER TABLE metadata.country ADD PRIMARY KEY (country_id);
ALTER TABLE metadata.project ADD PRIMARY KEY (country_id, project_id);
ALTER TABLE metadata.mapset ADD PRIMARY KEY (mapset_id);
ALTER TABLE metadata.mapset ADD UNIQUE (file_identifier);
ALTER TABLE metadata.property ADD PRIMARY KEY (property_id);
ALTER TABLE metadata.layer ADD PRIMARY KEY (layer_id);
ALTER TABLE metadata.metadata_manual ADD PRIMARY KEY (mapset_id);
ALTER TABLE metadata.class ADD PRIMARY KEY (property_id, value);
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
ALTER TABLE metadata.class ADD FOREIGN KEY (property_id) REFERENCES metadata.property(property_id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE metadata.layer ADD FOREIGN KEY (mapset_id) REFERENCES metadata.mapset(mapset_id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE metadata.mapset ADD FOREIGN KEY (country_id, project_id) REFERENCES metadata.project(country_id, project_id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE metadata.mapset ADD FOREIGN KEY (property_id) REFERENCES metadata.property(property_id) ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE metadata.project ADD FOREIGN KEY (country_id) REFERENCES metadata.country(country_id) ON UPDATE CASCADE ON DELETE NO ACTION;


--------------------------
--       TRIGGER        --
--------------------------

CREATE TRIGGER class
  AFTER UPDATE OF property_type, num_intervals, start_color, end_color, min, max
  ON metadata.property
  FOR EACH ROW
  EXECUTE FUNCTION metadata.class();

CREATE TRIGGER sld
  AFTER INSERT OR UPDATE ON metadata.class
  FOR EACH STATEMENT
  EXECUTE FUNCTION metadata.sld();

CREATE TRIGGER map_layer
  AFTER UPDATE OF layer_id, mapset_id, distance_uom, reference_system_identifier_code, extent, file_extension, stats_minimum, stats_maximum
  ON metadata.layer
  FOR EACH ROW
  EXECUTE FUNCTION metadata.map();

-- CREATE TRIGGER map_property
-- AFTER UPDATE OF property_id, start_color, end_color
-- ON metadata.property
-- FOR EACH ROW
-- EXECUTE FUNCTION metadata.map();
