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
        DROP TABLE IF EXISTS sislac_specimen_result;
        DROP TABLE IF EXISTS sislac_plot;
        
        CREATE TABLE sislac_plot (
                sislac_plot_id int4 NOT NULL,
                plot_identifier text NOT NULL,
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
                geom geometry(point, 4326),
	CONSTRAINT sislac_plot_pkey PRIMARY KEY (sislac_plot_id));

        CREATE TABLE sislac_specimen_result (
                sislac_specimen_result_id int4 NOT NULL,
                sislac_plot_id int4 NOT NULL,
                plot_identifier text NULL,
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
	CONSTRAINT sislac_specimen_result_pkey PRIMARY KEY (sislac_specimen_result_id),
        CONSTRAINT fk_sislac_plot FOREIGN KEY (sislac_plot_id) REFERENCES sislac_plot(sislac_plot_id));
        
        INSERT INTO sislac_plot
        SELECT DISTINCT profile_id, profile_identifier, country_code, tipo, fecha, orden, "source", contact, license, perfil_duplicado, tier, s_vegetacion, s_observaciones, s_uso_tierra, s_relieve, s_permeabilidad, s_escurrimiento, s_pendiente, s_drenaje, geom
        FROM sislac_zenodo;
        
        INSERT INTO sislac_specimen_result
        SELECT layer_id, profile_id, profile_identifier, layer_identifier, top, bottom, designation, bulk_density, 
                ca_co3, coarse_fragments, ecec, conductivity, organic_carbon, ph, clay, silt, sand, water_retention, 
                n, p, k, ca, mg, s, fe, mn, zn, cu, b, mo, cl, co3, 
                humedad, textura, cons_seco, cons_humedo, estruc_tipo, estruc_clase, estruc_grado
        FROM sislac_zenodo;"


# Export tables from PostgreSQL to gpkg
ogr2ogr -f GPKG /home/carva014/Work/Code/FAO/glosis-db/SISLAC/SISLAC.gpkg PG:'host=localhost user=eloi dbname=sislac' -nln sislac_plot sislac_plot
ogr2ogr -f GPKG /home/carva014/Work/Code/FAO/glosis-db/SISLAC/SISLAC.gpkg PG:'host=localhost user=eloi dbname=sislac' -update -nln sislac_specimen_result sislac_specimen_result
