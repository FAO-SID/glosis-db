# Set db
psql -h localhost -p 5432 -d postgres -U postgres -c "DROP DATABASE IF EXISTS sislac"
psql -h localhost -p 5432 -d postgres -U eloi -c "CREATE DATABASE sislac"
psql -h localhost -p 5432 -d sislac -U eloi -c "CREATE EXTENSION postgis"


# Data from GDocs
pg_restore -h localhost -p 5432 -d sislac -U eloi -O -x -v -j 2 /home/carva014/Downloads/FAO/SISLAC/Deliverables/Anexos_PrimerInforme/1_BaseDeDatos/bdSISLAC_v2.backup


# Data from https://zenodo.org/records/7876731
psql -h localhost -p 5432 -d sislac -U eloi -c "DROP TABLE IF EXISTS sislac_zenodo"
psql -h localhost -p 5432 -d sislac -U eloi -c "CREATE TABLE sislac_zenodo (
	profile_id int4 NOT NULL,
	profile_identifier text NOT NULL,
	latitude float8 NULL,
	longitude float8 NULL,
	country_code text NULL,
	tipo text NULL,
	fecha text NULL,
	orden text NULL,
	"source" text NULL,
	contact text NULL,
	license text NULL,
	perfil_duplicado bool DEFAULT false NULL,
	tier int4 NULL,
	s_vegetacion text NULL,
	s_observaciones text NULL,
	s_uso_tierra text NULL,
	s_relieve text NULL,
	s_permeabilidad text NULL,
	s_escurrimiento text NULL,
	s_pendiente text NULL,
	s_drenaje text NULL,
	layer_id int4 NOT NULL,
	profile_identifier2 text NULL,
	layer_identifier text NULL,
	top int4 NULL,
	bottom int4 NULL,
	designation text NULL,
	bulk_density float8 NULL,
	ca_co3 float8 NULL,
	coarse_fragments float8 NULL,
	ecec float8 NULL,
	conductivity float8 NULL,
	organic_carbon float8 NULL,
	ph float8 NULL,
	clay int4 NULL,
	silt int4 NULL,
	sand int4 NULL,
	water_retention float8 NULL,
	n float8 NULL,
	p float8 NULL,
	k float8 NULL,
	ca float8 NULL,
	mg float8 NULL,
	s float8 NULL,
	fe float8 NULL,
	mn float8 NULL,
	zn float8 NULL,
	cu float8 NULL,
	b float8 NULL,
	mo float8 NULL,
	cl float8 NULL,
	co3 float8 NULL,
	humedad text NULL,
	textura text NULL,
	cons_seco text NULL,
	cons_humedo text NULL,
	estruc_tipo text NULL,
	estruc_clase text NULL,
	estruc_grado text NULL,
	CONSTRAINT sislac_zenodo_pkey PRIMARY KEY (profile_id, layer_id));"

cat /home/carva014/Downloads/FAO/SISLAC/From_Zenodo/sislac_v2.csv | psql -h localhost -p 5432 -d sislac -U eloi -c "COPY sislac_zenodo FROM STDIN WITH (FORMAT CSV, HEADER, NULL '')"


psql -h localhost -p 5432 -d sislac -U eloi -c "
        SELECT count(*) AS n_rows_gdocs FROM sislac_horizontes_v2;
        SELECT count(*) AS n_rows_zenodo FROM sislac_zenodo;"
#  n_rows_gdocs 
# --------------
#        213630

#  n_rows_zenodo 
# ---------------
#         192568


# Add geometry to table
psql -h localhost -p 5432 -d sislac -U eloi -c "ALTER TABLE sislac_zenodo ADD COLUMN geom geometry(point, 4326);
                                                UPDATE sislac_zenodo SET geom = ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)"


# Mexico data duplicated in GDocs dataset but not in the Zenodo datase
psql -h localhost -p 5432 -d sislac -U eloi -c "
        SELECT country_code, source, contact, count(*)
        FROM sislac_perfiles_v2
        WHERE country_code ='MEX'
        GROUP BY country_code, source, contact
        ORDER BY country_code"
#  country_code |          source          |        contact        | count 
# --------------+--------------------------+-----------------------+-------
#  MEX          | México Serie-1           | Rocio Hernández Reyes |  3052
#  MEX          | México Serie-2           | Rocio Hernández Reyes |  4420
#  MEX          | WoSIS July 2016 Snapshot | niels.batjes@wur.nl   |  7274
# (3 rows)


psql -h localhost -p 5432 -d sislac -U eloi -c "
        SELECT country_code, source, contact, count(DISTINCT profile_identifier2)
        FROM sislac_zenodo
        WHERE country_code ='MEX'
        GROUP BY country_code, source, contact
        ORDER BY country_code"
#  country_code |     source     |        contact        | count 
# --------------+----------------+-----------------------+-------
#  MEX          | México Serie-1 | Rocio Hernández Reyes |  3052
#  MEX          | México Serie-2 | Rocio Hernández Reyes |  4420
# (2 rows)



psql -h localhost -p 5432 -d sislac -U eloi -c "
        DROP TABLE IF EXISTS result;
        DROP TABLE IF EXISTS layer;
        DROP TABLE IF EXISTS profile;
        DROP TABLE IF EXISTS dataset;
        
        -- Dataset
        CREATE TABLE dataset (
                dataset_id text NOT NULL,
                name text,
                description text,
	CONSTRAINT dataset_pkey PRIMARY KEY (dataset_id));

        INSERT INTO dataset (dataset_id, name, description)
        VALUES ('SISLAC', 'Soil Information System for Latin American and the Caribbean', 'https://doi.org/10.5194/essd-16-1229-2024');


        -- Profile
        CREATE TABLE profile (
                profile_id int4 NOT NULL,
                dataset_id text NOT NULL,
                profile_code text NOT NULL,
                country_code text NULL,
                profile_type text NULL,
                fecha text NULL,
                sampling_date date,
                usda_soil_taxonomy_order text NULL,
                dataset_source text NULL,
                dataset_contact text NULL,
                dataset_license text NULL,
                geom geometry(point, 4326),
	CONSTRAINT profile_pkey PRIMARY KEY (profile_id),
        CONSTRAINT fk_dataset FOREIGN KEY (dataset_id) REFERENCES dataset(dataset_id));

        INSERT INTO profile (profile_id, dataset_id, profile_code, country_code, profile_type, fecha, sampling_date, usda_soil_taxonomy_order, dataset_source, dataset_contact, dataset_license, geom)
        SELECT DISTINCT profile_id, 'SISLAC', profile_identifier, country_code, tipo, fecha, NULL::date, orden, "source", contact, license, geom
        FROM sislac_zenodo;

        UPDATE profile SET sampling_date = (split_part(fecha,'/',3)||'-'||split_part(fecha,'/',2)||'-'||split_part(fecha,'/',1))::date WHERE fecha != '01/01/1900';
        ALTER TABLE profile DROP COLUMN fecha;
        UPDATE profile SET profile_type = 'TrialPit' WHERE profile_type ILIKE 'perfil de suelo';
        UPDATE profile SET profile_type = 'Borehole' WHERE profile_type ILIKE 'barrenada';
        UPDATE profile SET usda_soil_taxonomy_order = NULL WHERE usda_soil_taxonomy_order IN ('NA','S/D');
        UPDATE profile SET country_code = 'AN' WHERE country_code = 'ANT';
        UPDATE profile SET country_code = 'AR' WHERE country_code = 'ARG';
        UPDATE profile SET country_code = 'BZ' WHERE country_code = 'BLZ';
        UPDATE profile SET country_code = 'BO' WHERE country_code = 'BOL';
        UPDATE profile SET country_code = 'BR' WHERE country_code = 'BRA';
        UPDATE profile SET country_code = 'BB' WHERE country_code = 'BRB';
        UPDATE profile SET country_code = 'CL' WHERE country_code = 'CHL';
        UPDATE profile SET country_code = 'CO' WHERE country_code = 'COL';
        UPDATE profile SET country_code = 'CR' WHERE country_code = 'CRI';
        UPDATE profile SET country_code = 'CU' WHERE country_code = 'CUB';
        UPDATE profile SET country_code = 'DO' WHERE country_code = 'DOM';
        UPDATE profile SET country_code = 'EC' WHERE country_code = 'ECU';
        UPDATE profile SET country_code = 'GT' WHERE country_code = 'GTM';
        UPDATE profile SET country_code = 'GF' WHERE country_code = 'GUF';
        UPDATE profile SET country_code = 'GY' WHERE country_code = 'GUY';
        UPDATE profile SET country_code = 'HN' WHERE country_code = 'HND';
        UPDATE profile SET country_code = 'JM' WHERE country_code = 'JAM';
        UPDATE profile SET country_code = 'MX' WHERE country_code = 'MEX';
        UPDATE profile SET country_code = 'NI' WHERE country_code = 'NIC';
        UPDATE profile SET country_code = 'PA' WHERE country_code = 'PAN';
        UPDATE profile SET country_code = 'PE' WHERE country_code = 'PER';
        UPDATE profile SET country_code = 'PR' WHERE country_code = 'PRI';
        UPDATE profile SET country_code = 'SV' WHERE country_code = 'SLV';
        UPDATE profile SET country_code = 'SR' WHERE country_code = 'SUR';
        UPDATE profile SET country_code = 'TT' WHERE country_code = 'TTO';
        UPDATE profile SET country_code = 'UY' WHERE country_code = 'URY';
        UPDATE profile SET country_code = 'VE' WHERE country_code = 'VEN';
        UPDATE profile SET country_code = 'VI' WHERE country_code = 'VIR';


        -- Layer
        CREATE TABLE layer (
                layer_id int4 NOT NULL,
                profile_id int4 NOT NULL,
                layer_code text NULL,
                upper_depth int4 NULL,
                lower_depth int4 NULL,
                designation text NULL,
        CONSTRAINT layer_pkey PRIMARY KEY (layer_id),
        CONSTRAINT fk_profile FOREIGN KEY (profile_id) REFERENCES profile(profile_id));

        INSERT INTO layer
        SELECT layer_id, profile_id, layer_identifier, top, bottom, designation
        FROM sislac_zenodo;

        UPDATE layer SET designation = NULL WHERE designation IN ('S/D','Sin nombre');
        UPDATE layer SET designation = trim(designation) WHERE designation IS NOt NULL;


        -- Result
        CREATE TABLE result (
                result_id serial,
                layer_id int4 NOT NULL,
                property_source text NOT NULL,
                property_pretty_name text NULL,
                glosis_property_uri text NULL,
                glosis_procedure_uri text NULL,
                unit text NULL,
                value text NOT NULL,
        CONSTRAINT result_pkey PRIMARY KEY (result_id),
        CONSTRAINT fk_layer FOREIGN KEY (layer_id) REFERENCES layer(layer_id));

        INSERT INTO result (layer_id, glosis_property_uri, property_pretty_name, unit, glosis_procedure_uri, property_source, value) SELECT layer_id, NULL, 'Bulk density', NULL, NULL, 'bulk_density', bulk_density FROM sislac_zenodo WHERE bulk_density IS NOT NULL;
        INSERT INTO result (layer_id, glosis_property_uri, property_pretty_name, unit, glosis_procedure_uri, property_source, value) SELECT layer_id, 'http://w3id.org/glosis/model/layerhorizon/carbonInorganicProperty', 'Carbon (C) - inorganic', '%', NULL, 'ca_co3', ca_co3 FROM sislac_zenodo WHERE ca_co3 IS NOT NULL;
        INSERT INTO result (layer_id, glosis_property_uri, property_pretty_name, unit, glosis_procedure_uri, property_source, value) SELECT layer_id, 'http://w3id.org/glosis/model/layerhorizon/coarseFragmentsProperty', 'Coarse fragments', '%', NULL, 'coarse_fragments', coarse_fragments FROM sislac_zenodo WHERE coarse_fragments IS NOT NULL;
        INSERT INTO result (layer_id, glosis_property_uri, property_pretty_name, unit, glosis_procedure_uri, property_source, value) SELECT layer_id, 'http://w3id.org/glosis/model/layerhorizon/effectiveCecProperty', 'Effective CEC', NULL, NULL, 'ecec', ecec FROM sislac_zenodo WHERE ecec IS NOT NULL;
        INSERT INTO result (layer_id, glosis_property_uri, property_pretty_name, unit, glosis_procedure_uri, property_source, value) SELECT layer_id, 'http://w3id.org/glosis/model/layerhorizon/electricalConductivityProperty', 'Electrical conductivity', NULL, NULL, 'conductivity', conductivity FROM sislac_zenodo WHERE conductivity IS NOT NULL;
        INSERT INTO result (layer_id, glosis_property_uri, property_pretty_name, unit, glosis_procedure_uri, property_source, value) SELECT layer_id, 'http://w3id.org/glosis/model/codelists/physioChemicalPropertyCode-Carorg', 'Carbon (C) - organic', '%', NULL, 'organic_carbon', organic_carbon FROM sislac_zenodo WHERE organic_carbon IS NOT NULL;
        INSERT INTO result (layer_id, glosis_property_uri, property_pretty_name, unit, glosis_procedure_uri, property_source, value) SELECT layer_id, 'http://w3id.org/glosis/model/codelists/physioChemicalPropertyCode-pH', 'pH - Hydrogen potential', 'pH', NULL, 'ph', ph FROM sislac_zenodo WHERE ph IS NOT NULL;
        INSERT INTO result (layer_id, glosis_property_uri, property_pretty_name, unit, glosis_procedure_uri, property_source, value) SELECT layer_id, 'http://w3id.org/glosis/model/codelists/physioChemicalPropertyCode-Textclay', 'Clay texture fraction', '%', NULL, 'clay', clay FROM sislac_zenodo WHERE clay IS NOT NULL;
        INSERT INTO result (layer_id, glosis_property_uri, property_pretty_name, unit, glosis_procedure_uri, property_source, value) SELECT layer_id, 'http://w3id.org/glosis/model/codelists/physioChemicalPropertyCode-Textsilt', 'Silt texture fraction', '%', NULL, 'silt', silt FROM sislac_zenodo WHERE silt IS NOT NULL;
        INSERT INTO result (layer_id, glosis_property_uri, property_pretty_name, unit, glosis_procedure_uri, property_source, value) SELECT layer_id, 'http://w3id.org/glosis/model/codelists/physioChemicalPropertyCode-Textsand', 'Sand texture fraction', '%', NULL, 'sand', sand FROM sislac_zenodo WHERE sand IS NOT NULL;
        INSERT INTO result (layer_id, glosis_property_uri, property_pretty_name, unit, glosis_procedure_uri, property_source, value) SELECT layer_id, NULL, 'Water retention', '%', NULL, 'water_retention', water_retention FROM sislac_zenodo WHERE water_retention IS NOT NULL;
        INSERT INTO result (layer_id, glosis_property_uri, property_pretty_name, unit, glosis_procedure_uri, property_source, value) SELECT layer_id, NULL, 'Nitrogen (N)', NULL, NULL, 'n', n FROM sislac_zenodo WHERE n IS NOT NULL;
        INSERT INTO result (layer_id, glosis_property_uri, property_pretty_name, unit, glosis_procedure_uri, property_source, value) SELECT layer_id, NULL, 'Phosphorus (P)', NULL, NULL, 'p', p FROM sislac_zenodo WHERE p IS NOT NULL;
        INSERT INTO result (layer_id, glosis_property_uri, property_pretty_name, unit, glosis_procedure_uri, property_source, value) SELECT layer_id, NULL, 'Potassium (K)', NULL, NULL, 'k', k FROM sislac_zenodo WHERE k IS NOT NULL;
        INSERT INTO result (layer_id, glosis_property_uri, property_pretty_name, unit, glosis_procedure_uri, property_source, value) SELECT layer_id, NULL, 'Calcium (Ca++)', NULL, NULL, 'ca', ca FROM sislac_zenodo WHERE ca IS NOT NULL;
        INSERT INTO result (layer_id, glosis_property_uri, property_pretty_name, unit, glosis_procedure_uri, property_source, value) SELECT layer_id, NULL, 'Magnesium (Mg)', NULL, NULL, 'mg', mg FROM sislac_zenodo WHERE mg IS NOT NULL;
        INSERT INTO result (layer_id, glosis_property_uri, property_pretty_name, unit, glosis_procedure_uri, property_source, value) SELECT layer_id, NULL, 'Sulfur (S)', NULL, NULL, 's', s FROM sislac_zenodo WHERE s IS NOT NULL;
        INSERT INTO result (layer_id, glosis_property_uri, property_pretty_name, unit, glosis_procedure_uri, property_source, value) SELECT layer_id, NULL, 'Iron (Fe)', NULL, NULL, 'fe', fe FROM sislac_zenodo WHERE fe IS NOT NULL;
        INSERT INTO result (layer_id, glosis_property_uri, property_pretty_name, unit, glosis_procedure_uri, property_source, value) SELECT layer_id, NULL, 'Manganese (Mn)', NULL, NULL, 'mn', mn FROM sislac_zenodo WHERE mn IS NOT NULL;
        INSERT INTO result (layer_id, glosis_property_uri, property_pretty_name, unit, glosis_procedure_uri, property_source, value) SELECT layer_id, NULL, 'Zinc (Zn)', NULL, NULL, 'zn', zn FROM sislac_zenodo WHERE zn IS NOT NULL;
        INSERT INTO result (layer_id, glosis_property_uri, property_pretty_name, unit, glosis_procedure_uri, property_source, value) SELECT layer_id, NULL, 'Copper (Cu)', NULL, NULL, 'cu', cu FROM sislac_zenodo WHERE cu IS NOT NULL;
        INSERT INTO result (layer_id, glosis_property_uri, property_pretty_name, unit, glosis_procedure_uri, property_source, value) SELECT layer_id, NULL, 'Boron (B)', NULL, NULL, 'b', b FROM sislac_zenodo WHERE b IS NOT NULL;
        INSERT INTO result (layer_id, glosis_property_uri, property_pretty_name, unit, glosis_procedure_uri, property_source, value) SELECT layer_id, NULL, '?', NULL, NULL, 'mo', mo FROM sislac_zenodo WHERE mo IS NOT NULL; -- EMPTY COLUMN!
        INSERT INTO result (layer_id, glosis_property_uri, property_pretty_name, unit, glosis_procedure_uri, property_source, value) SELECT layer_id, NULL, '?', NULL, NULL, 'cl', cl FROM sislac_zenodo WHERE cl IS NOT NULL; -- EMPTY COLUMN!
        INSERT INTO result (layer_id, glosis_property_uri, property_pretty_name, unit, glosis_procedure_uri, property_source, value) SELECT layer_id, NULL, '?', NULL, NULL, 'co3', co3 FROM sislac_zenodo WHERE co3 IS NOT NULL;
        INSERT INTO result (layer_id, glosis_property_uri, property_pretty_name, unit, glosis_procedure_uri, property_source, value) SELECT layer_id, NULL, 'Humidity descriptive', NULL, NULL, 'humedad', humedad FROM sislac_zenodo WHERE humedad IS NOT NULL AND humedad != 'S/D';
        INSERT INTO result (layer_id, glosis_property_uri, property_pretty_name, unit, glosis_procedure_uri, property_source, value) SELECT layer_id, NULL, 'Texture descriptive', NULL, NULL, 'textura', textura FROM sislac_zenodo WHERE textura IS NOT NULL AND textura != 'S/D';
        INSERT INTO result (layer_id, glosis_property_uri, property_pretty_name, unit, glosis_procedure_uri, property_source, value) SELECT layer_id, NULL, 'Consistency dry descriptive', NULL, NULL, 'cons_seco', cons_seco FROM sislac_zenodo WHERE cons_seco IS NOT NULL AND cons_seco != 'S/D';
        INSERT INTO result (layer_id, glosis_property_uri, property_pretty_name, unit, glosis_procedure_uri, property_source, value) SELECT layer_id, NULL, 'Consistency wet descriptive', NULL, NULL, 'cons_humedo', cons_humedo FROM sislac_zenodo WHERE cons_humedo IS NOT NULL AND cons_humedo != 'S/D';
        INSERT INTO result (layer_id, glosis_property_uri, property_pretty_name, unit, glosis_procedure_uri, property_source, value) SELECT layer_id, NULL, 'Structure type descriptive', NULL, NULL, 'estruc_tipo', estruc_tipo FROM sislac_zenodo WHERE estruc_tipo IS NOT NULL AND estruc_tipo != 'S/D';
        INSERT INTO result (layer_id, glosis_property_uri, property_pretty_name, unit, glosis_procedure_uri, property_source, value) SELECT layer_id, NULL, 'Structure class descriptive', NULL, NULL, 'estruc_clase', estruc_clase FROM sislac_zenodo WHERE estruc_clase IS NOT NULL AND estruc_clase != 'S/D';
        INSERT INTO result (layer_id, glosis_property_uri, property_pretty_name, unit, glosis_procedure_uri, property_source, value) SELECT layer_id, NULL, 'Structure grade descriptive', NULL, NULL, 'estruc_grado', estruc_grado FROM sislac_zenodo WHERE estruc_grado IS NOT NULL AND estruc_grado != 'S/D';
        "

psql -h localhost -p 5432 -d sislac -U eloi -c "
        SELECT DISTINCT property_source, property_pretty_name, unit, glosis_property_uri
        FROM result
        ORDER BY property_pretty_name, property_source"

psql -h localhost -p 5432 -d sislac -U eloi -c "
        SELECT l.upper_depth AS top, l.lower_depth AS bottom, r.property_pretty_name AS property, r.unit, r.value
        FROM layer AS l
        LEFT JOIN result AS r ON r.layer_id = l.layer_id
        WHERE l.profile_id = 1    -- << the ID of the clicked point in the map by the user
        ORDER BY r.property_pretty_name, l.upper_depth"

psql -h localhost -p 5432 -d sislac -U eloi -c "
        SELECT count(*) FROM profile;
        SELECT dataset_source, count(*) FROM profile GROUP BY dataset_source ORDER BY count(*) DESC;
        SELECT country_code, count(*) FROM profile GROUP BY country_code ORDER BY count(*) DESC;"


# Export tables from PostgreSQL to gpkg
ogr2ogr -f GPKG /home/carva014/Downloads/SISLAC.gpkg PG:'host=localhost user=eloi dbname=sislac' -nln dataset dataset
ogr2ogr -f GPKG /home/carva014/Downloads/SISLAC.gpkg PG:'host=localhost user=eloi dbname=sislac' -update -nln profile profile
ogr2ogr -f GPKG /home/carva014/Downloads/SISLAC.gpkg PG:'host=localhost user=eloi dbname=sislac' -update -nln layer layer
ogr2ogr -f GPKG /home/carva014/Downloads/SISLAC.gpkg PG:'host=localhost user=eloi dbname=sislac' -update -nln result result
