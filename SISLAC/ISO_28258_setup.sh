psql -h localhost -p 5432 -d postgres -U postgres -c "CREATE ROLE sislac WITH LOGIN SUPERUSER INHERIT CREATEDB CREATEROLE NOREPLICATION NOBYPASSRLS PASSWORD 'sislac' "
psql -h localhost -p 5432 -d postgres -U sislac -c "CREATE ROLE sislac_r WITH LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE INHERIT LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'sislac' "
psql -h localhost -p 5432 -d postgres -U sislac -c "DROP DATABASE IF EXISTS iso28258"
psql -h localhost -p 5432 -d postgres -U sislac -c "CREATE DATABASE iso28258"
psql -h localhost -p 5432 -d iso28258 -U sislac -c "CREATE EXTENSION postgis"
psql -h localhost -p 5432 -d iso28258 -U sislac -f /home/carva014/Work/Code/FAO/sislac-db/ISO_28258_v1.5_changed.sql
psql -h localhost -p 5432 -d iso28258 -U sislac -f /home/carva014/Work/Code/FAO/sislac-db/Changes/mod_001.sql
psql -h localhost -p 5432 -d iso28258 -U sislac -f /home/carva014/Work/Code/FAO/sislac-db/Changes/mod_002.sql
psql -h localhost -p 5432 -d iso28258 -U sislac -f /home/carva014/Work/Code/FAO/sislac-db/Changes/mod_003.sql
psql -h localhost -p 5432 -d iso28258 -U sislac -f /home/carva014/Work/Code/FAO/sislac-db/Changes/mod_004.sql
psql -h localhost -p 5432 -d iso28258 -U sislac -f /home/carva014/Work/Code/FAO/sislac-db/Changes/mod_005.sql
psql -h localhost -p 5432 -d iso28258 -U sislac -f /home/carva014/Work/Code/FAO/sislac-db/Changes/mod_006.sql
psql -h localhost -p 5432 -d iso28258 -U sislac -f /home/carva014/Work/Code/FAO/sislac-db/Changes/mod_007.sql
psql -h localhost -p 5432 -d iso28258 -U sislac -f /home/carva014/Work/Code/FAO/sislac-db/Changes/mod_008.sql
psql -h localhost -p 5432 -d iso28258 -U sislac -f /home/carva014/Work/Code/FAO/sislac-db/Changes/mod_009.sql
psql -h localhost -p 5432 -d iso28258 -U sislac -f /home/carva014/Work/Code/FAO/sislac-db/Changes/mod_010.sql
psql -h localhost -p 5432 -d iso28258 -U sislac -f /home/carva014/Work/Code/FAO/sislac-db/Changes/mod_011.sql
psql -h localhost -p 5432 -d iso28258 -U sislac -f /home/carva014/Work/Code/FAO/sislac-db/Changes/mod_012.sql
psql -h localhost -p 5432 -d iso28258 -U sislac -f /home/carva014/Work/Code/FAO/sislac-db/Changes/mod_013.sql
psql -h localhost -p 5432 -d iso28258 -U sislac -f /home/carva014/Work/Code/FAO/sislac-db/Changes/mod_014.sql
psql -h localhost -p 5432 -d iso28258 -U sislac -f /home/carva014/Work/Code/FAO/sislac-db/Changes/mod_015.sql
psql -h localhost -p 5432 -d iso28258 -U sislac -f /home/carva014/Work/Code/FAO/sislac-db/Changes/mod_016.sql
psql -h localhost -p 5432 -d iso28258 -U sislac -f /home/carva014/Work/Code/FAO/sislac-db/Changes/mod_017.sql
psql -h localhost -p 5432 -d iso28258 -U sislac -f /home/carva014/Work/Code/FAO/sislac-db/Changes/mod_018.sql
psql -h localhost -p 5432 -d iso28258 -U sislac -f /home/carva014/Work/Code/FAO/sislac-db/Changes/mod_019.sql
psql -h localhost -p 5432 -d iso28258 -U sislac -f /home/carva014/Work/Code/FAO/sislac-db/Changes/mod_020.sql
psql -h localhost -p 5432 -d iso28258 -U sislac -f /home/carva014/Work/Code/FAO/sislac-db/Changes/mod_021.sql


# dump iso28258 database per schema
date=`date +%Y-%m-%d`
pg_dump -h localhost \
        -p 5432 \
        -d iso28258 \
        -U sislac \
        -F plain \
        -v \
        -f /home/carva014/Work/Code/FAO/sislac-db/ISO_28258_v$date.sql

pg_dump -h localhost \
        -p 5432 \
        -d iso28258 \
        -U sislac \
        -F plain \
        -v \
        -f /home/carva014/Work/Code/FAO/sislac-db/ISO_28258_v_latest.sql
