DROP SCHEMA IF EXISTS metadata_iso CASCADE;
CREATE SCHEMA metadata_iso;
ALTER SCHEMA metadata_iso OWNER TO geodesk_geonetwork;
COMMENT ON SCHEMA metadata_iso IS 'Schema for GeoDesk metadata';
GRANT USAGE ON SCHEMA metadata_iso TO geodesk_r;


CREATE TABLE metadata_iso.dataset (
    dataset_id text NOT NULL,
    dataset_name text,
    complete boolean
);
ALTER TABLE metadata_iso.dataset OWNER TO geodesk_geonetwork;
GRANT SELECT ON TABLE metadata_iso.dataset TO geodesk_r;


CREATE TABLE metadata_iso.version (
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
    -- creation_date date,
    -- publication_date date,
    -- revision_date date,
    creation_date text,
    publication_date text,
    revision_date text,
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
    lineage_source_title text
    -- representation_type text,
    -- presentation_form text DEFAULT 'mapDigital'::text,
    -- CONSTRAINT version_status_check CHECK ((status = ANY (ARRAY['Completed'::text, 'Historical archive'::text, 'Obsolete'::text, 'On going'::text, 'Planned'::text, 'Required'::text, 'Under development'::text]))),
    -- CONSTRAINT version_representation_type_check CHECK ((representation_type = ANY (ARRAY['Grid'::text, 'Vector'::text, 'Tabular'::text])))
);
ALTER TABLE metadata_iso.version OWNER TO geodesk_geonetwork;
GRANT SELECT ON TABLE metadata_iso.version TO geodesk_r;


CREATE TABLE metadata_iso.layer (
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
ALTER TABLE metadata_iso.layer OWNER TO geodesk_geonetwork;
GRANT SELECT ON TABLE metadata_iso.layer TO geodesk_r;
COMMENT ON COLUMN metadata_iso.layer.geo_transform IS 'X Origin (top left corner), X pixel size (W-E pizel resolution), Rotation (0 if north is up), Y Origin (top left corner), Rotation (0 if north is up), -Y pixel size (N-S pixel resolution)';


CREATE TABLE metadata_iso.ver_x_org_x_ind (
    dataset_id text NOT NULL,
    version text NOT NULL,
    tag text,
    role text,
    position text,
    organisation_id text NOT NULL,
    individual_id text
    -- CONSTRAINT contact_tag_check CHECK ((tag = ANY (ARRAY['Author'::text, 'Custodian'::text, 'Distributor'::text, 'Originator'::text, 'Owner'::text, 'Point of contact'::text, 'Principal investigator'::text, 'Processor'::text, 'Publisher'::text, 'Resource provider'::text, 'User'::text])))
);
ALTER TABLE metadata_iso.ver_x_org_x_ind OWNER TO geodesk_geonetwork;
GRANT SELECT ON TABLE metadata_iso.ver_x_org_x_ind TO geodesk_r;


CREATE TABLE metadata_iso.organisation (
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
ALTER TABLE metadata_iso.organisation OWNER TO geodesk_geonetwork;
GRANT SELECT ON TABLE metadata_iso.organisation TO geodesk_r;


CREATE TABLE metadata_iso.individual (
    individual_id text NOT NULL,
    email text    
);
ALTER TABLE metadata_iso.individual OWNER TO geodesk_geonetwork;
GRANT SELECT ON TABLE metadata_iso.individual TO geodesk_r;


CREATE TABLE metadata_iso.url (
    url_id serial,
    dataset_id text NOT NULL,
    version text NOT NULL,
    protocol text,
    url text NOT NULL,
    url_name text,
    valid text
    -- CONSTRAINT url_protocol_check CHECK ((protocol = ANY (ARRAY['link'::text, 'ftp'::text, 'wms'::text, 'wcs'::text, 'wfs'::text])))
);
ALTER TABLE metadata_iso.url OWNER TO geodesk_geonetwork;
GRANT SELECT ON TABLE metadata_iso.url TO geodesk_r;


ALTER TABLE metadata_iso.dataset ADD PRIMARY KEY (dataset_id);
ALTER TABLE metadata_iso.version ADD PRIMARY KEY (dataset_id, version);
ALTER TABLE metadata_iso.version ADD UNIQUE (file_identifier);
ALTER TABLE metadata_iso.layer ADD PRIMARY KEY (dataset_id, version, layer);
ALTER TABLE metadata_iso.ver_x_org_x_ind ADD PRIMARY KEY (dataset_id, version, tag, role, position, organisation_id, individual_id);
ALTER TABLE metadata_iso.organisation ADD PRIMARY KEY (organisation_id);
ALTER TABLE metadata_iso.individual ADD PRIMARY KEY (individual_id);
ALTER TABLE metadata_iso.url ADD PRIMARY KEY (url_id);


ALTER TABLE metadata_iso.ver_x_org_x_ind ADD FOREIGN KEY (individual_id) REFERENCES metadata_iso.individual(individual_id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE metadata_iso.ver_x_org_x_ind ADD FOREIGN KEY (organisation_id) REFERENCES metadata_iso.organisation(organisation_id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE metadata_iso.ver_x_org_x_ind ADD FOREIGN KEY (dataset_id, version) REFERENCES metadata_iso.version(dataset_id, version) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE metadata_iso.url ADD FOREIGN KEY (dataset_id, version) REFERENCES metadata_iso.version(dataset_id, version) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE metadata_iso.layer ADD FOREIGN KEY (dataset_id, version) REFERENCES metadata_iso.version(dataset_id, version) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE metadata_iso.version ADD FOREIGN KEY (dataset_id) REFERENCES metadata_iso.dataset(dataset_id) ON UPDATE CASCADE ON DELETE CASCADE;
