#!/bin/bash

psql -h localhost -p 5432 -d postgres -U postgres -c "DROP DATABASE IF EXISTS iso28258"
# psql -h localhost -p 5432 -d postgres -U postgres -c "DROP ROLE IF EXISTS glosis"
# psql -h localhost -p 5432 -d postgres -U postgres -c "DROP ROLE IF EXISTS glosis_r"
# psql -h localhost -p 5432 -d postgres -U postgres -c "CREATE ROLE glosis WITH LOGIN SUPERUSER INHERIT CREATEDB CREATEROLE NOREPLICATION NOBYPASSRLS PASSWORD 'glosis'"
# psql -h localhost -p 5432 -d postgres -U postgres -c "CREATE ROLE glosis_r WITH LOGIN NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS PASSWORD 'glosis'"
psql -h localhost -p 5432 -d postgres -U glosis -c "CREATE DATABASE iso28258"
psql -h localhost -p 5432 -d iso28258 -U glosis -c "CREATE EXTENSION IF NOT EXISTS postgis"
psql -h localhost -p 5432 -d iso28258 -U glosis -f /home/carva014/Work/Code/FAO/glosis-db/GloSIS/ISO_28258_v1.5_changed.sql
psql -h localhost -p 5432 -d iso28258 -U glosis -f /home/carva014/Work/Code/FAO/glosis-db/GloSIS/Changes/mod_001.sql
psql -h localhost -p 5432 -d iso28258 -U glosis -f /home/carva014/Work/Code/FAO/glosis-db/GloSIS/Changes/mod_002.sql
psql -h localhost -p 5432 -d iso28258 -U glosis -f /home/carva014/Work/Code/FAO/glosis-db/GloSIS/Changes/mod_003.sql
psql -h localhost -p 5432 -d iso28258 -U glosis -f /home/carva014/Work/Code/FAO/glosis-db/GloSIS/Changes/mod_004.sql
psql -h localhost -p 5432 -d iso28258 -U glosis -f /home/carva014/Work/Code/FAO/glosis-db/GloSIS/Changes/mod_005.sql
psql -h localhost -p 5432 -d iso28258 -U glosis -f /home/carva014/Work/Code/FAO/glosis-db/GloSIS/Changes/mod_006.sql
psql -h localhost -p 5432 -d iso28258 -U glosis -f /home/carva014/Work/Code/FAO/glosis-db/GloSIS/Changes/mod_007.sql
psql -h localhost -p 5432 -d iso28258 -U glosis -f /home/carva014/Work/Code/FAO/glosis-db/GloSIS/Changes/mod_008.sql
psql -h localhost -p 5432 -d iso28258 -U glosis -f /home/carva014/Work/Code/FAO/glosis-db/GloSIS/Changes/mod_009.sql
psql -h localhost -p 5432 -d iso28258 -U glosis -f /home/carva014/Work/Code/FAO/glosis-db/GloSIS/Changes/mod_010.sql
psql -h localhost -p 5432 -d iso28258 -U glosis -f /home/carva014/Work/Code/FAO/glosis-db/GloSIS/Changes/mod_011.sql
psql -h localhost -p 5432 -d iso28258 -U glosis -f /home/carva014/Work/Code/FAO/glosis-db/GloSIS/Changes/mod_012.sql
psql -h localhost -p 5432 -d iso28258 -U glosis -f /home/carva014/Work/Code/FAO/glosis-db/GloSIS/Changes/mod_013.sql
psql -h localhost -p 5432 -d iso28258 -U glosis -f /home/carva014/Work/Code/FAO/glosis-db/GloSIS/Changes/mod_014.sql
psql -h localhost -p 5432 -d iso28258 -U glosis -f /home/carva014/Work/Code/FAO/glosis-db/GloSIS/Changes/mod_015.sql
psql -h localhost -p 5432 -d iso28258 -U glosis -f /home/carva014/Work/Code/FAO/glosis-db/GloSIS/Changes/mod_016.sql
psql -h localhost -p 5432 -d iso28258 -U glosis -f /home/carva014/Work/Code/FAO/glosis-db/GloSIS/Changes/mod_017.sql
psql -h localhost -p 5432 -d iso28258 -U glosis -f /home/carva014/Work/Code/FAO/glosis-db/GloSIS/Changes/mod_018.sql
psql -h localhost -p 5432 -d iso28258 -U glosis -f /home/carva014/Work/Code/FAO/glosis-db/GloSIS/Changes/mod_019.sql
psql -h localhost -p 5432 -d iso28258 -U glosis -f /home/carva014/Work/Code/FAO/glosis-db/GloSIS/Changes/mod_020.sql
psql -h localhost -p 5432 -d iso28258 -U glosis -f /home/carva014/Work/Code/FAO/glosis-db/GloSIS/Changes/mod_021.sql
psql -h localhost -p 5432 -d iso28258 -U glosis -f /home/carva014/Work/Code/FAO/glosis-db/GloSIS/Changes/mod_022.sql
psql -h localhost -p 5432 -d iso28258 -U glosis -f /home/carva014/Work/Code/FAO/glosis-db/GloSIS/Changes/mod_023.sql
psql -h localhost -p 5432 -d iso28258 -U glosis -f /home/carva014/Work/Code/FAO/glosis-db/GloSIS/Changes/mod_024.sql
psql -h localhost -p 5432 -d iso28258 -U glosis -f /home/carva014/Work/Code/FAO/glosis-db/GloSIS/Changes/mod_025.sql
/home/carva014/Work/Code/FAO/glosis-db/GloSIS/Changes/mod_026.sh

# Dump iso28258 database
date=`date +%Y-%m-%d`
pg_dump -h localhost \
        -p 5432 \
        -d iso28258 \
        -U glosis \
        -F plain \
        -v \
        -f /home/carva014/Work/Code/FAO/glosis-db/GloSIS/ISO_28258_v$date.sql

pg_dump -h localhost \
        -p 5432 \
        -d iso28258 \
        -U glosis \
        -F plain \
        -v \
        -f /home/carva014/Work/Code/FAO/glosis-db/GloSIS/ISO_28258_v_latest.sql

# Export table with codelists of properties, procedures, units and alowed valu range
psql -h localhost -p 5432 -d iso28258 -U glosis -c "\COPY (
        SELECT o.property_phys_chem_id, o.procedure_phys_chem_id, o.unit_of_measure_id, o.value_min, o.value_max, p.definition, p.citation, p.reference 
        FROM core.observation_phys_chem o
        LEFT JOIN core.procedure_phys_chem p ON p.procedure_phys_chem_id = o.procedure_phys_chem_id
        ORDER BY 1, 2) 
        TO '/home/carva014/Work/Code/FAO/glosis-db/GloSIS/observation_phys_chem_code_list.csv' WITH CSV HEADER"
