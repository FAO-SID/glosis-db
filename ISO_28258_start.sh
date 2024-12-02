# psql -h localhost -p 5432 -d postgres -U glosis -c "CREATE ROLE glosis WITH LOGIN SUPERUSER INHERIT CREATEDB CREATEROLE NOREPLICATION NOBYPASSRLS PASSWORD 'XXXXXXX' "
psql -h localhost -p 5432 -d postgres -U glosis -c "DROP DATABASE IF EXISTS iso28258"
psql -h localhost -p 5432 -d postgres -U glosis -c "CREATE DATABASE iso28258"
psql -h localhost -p 5432 -d iso28258 -U glosis -c "CREATE EXTENSION postgis"
psql -h localhost -p 5432 -d iso28258 -U glosis -f /home/carva014/Work/Code/FAO/ISO28258/ISO_28258_ISRIC_v1.5_changed.sql
psql -h localhost -p 5432 -d iso28258 -U glosis -f /home/carva014/Work/Code/FAO/ISO28258/Changes/ISO_28258_ISRIC_mod_001.sql
psql -h localhost -p 5432 -d iso28258 -U glosis -f /home/carva014/Work/Code/FAO/ISO28258/Changes/ISO_28258_ISRIC_mod_002.sql
psql -h localhost -p 5432 -d iso28258 -U glosis -f /home/carva014/Work/Code/FAO/ISO28258/Changes/ISO_28258_ISRIC_mod_003.sql
psql -h localhost -p 5432 -d iso28258 -U glosis -f /home/carva014/Work/Code/FAO/ISO28258/Changes/ISO_28258_ISRIC_mod_004.sql
psql -h localhost -p 5432 -d iso28258 -U glosis -f /home/carva014/Work/Code/FAO/ISO28258/Changes/ISO_28258_ISRIC_mod_005.sql
psql -h localhost -p 5432 -d iso28258 -U glosis -f /home/carva014/Work/Code/FAO/ISO28258/Changes/ISO_28258_ISRIC_mod_006.sql
psql -h localhost -p 5432 -d iso28258 -U glosis -f /home/carva014/Work/Code/FAO/ISO28258/Changes/ISO_28258_ISRIC_mod_007.sql
psql -h localhost -p 5432 -d iso28258 -U glosis -f /home/carva014/Work/Code/FAO/ISO28258/Changes/ISO_28258_ISRIC_mod_008.sql
psql -h localhost -p 5432 -d iso28258 -U glosis -f /home/carva014/Work/Code/FAO/ISO28258/Changes/ISO_28258_ISRIC_mod_009.sql
psql -h localhost -p 5432 -d iso28258 -U glosis -f /home/carva014/Work/Code/FAO/ISO28258/Changes/ISO_28258_ISRIC_mod_010.sql
psql -h localhost -p 5432 -d iso28258 -U glosis -f /home/carva014/Work/Code/FAO/ISO28258/Changes/ISO_28258_ISRIC_mod_011.sql
psql -h localhost -p 5432 -d iso28258 -U glosis -f /home/carva014/Work/Code/FAO/ISO28258/Changes/ISO_28258_ISRIC_mod_012.sql
psql -h localhost -p 5432 -d iso28258 -U glosis -f /home/carva014/Work/Code/FAO/ISO28258/Changes/ISO_28258_ISRIC_mod_013.sql
psql -h localhost -p 5432 -d iso28258 -U glosis -f /home/carva014/Work/Code/FAO/ISO28258/Changes/ISO_28258_ISRIC_mod_014.sql
