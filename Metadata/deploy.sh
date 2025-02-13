# psql -h localhost -p 5432 -d postgres -U postgres -c "DROP DATABASE IF EXISTS iso19139"
# psql -h localhost -p 5432 -d postgres -U glosis -c "CREATE DATABASE iso19139"
# psql -h localhost -p 5432 -d iso19139 -U glosis -c "CREATE EXTENSION IF NOT EXISTS postgis"
# psql -h localhost -p 5432 -d iso19139 -U glosis -c 'CREATE EXTENSION IF NOT EXISTS "uuid-ossp"'
# psql -h localhost -p 5432 -d iso19139 -U glosis -c "DROP SCHEMA IF EXISTS metadata CASCADE"
# psql -h localhost -p 5432 -d iso19139 -U glosis -f /home/carva014/Work/Code/FAO/glosis-db/Metadata/db_model.sql
psql -h localhost -p 5432 -d iso19139 -U glosis -c "DELETE FROM metadata.project"
conda activate db
python /home/carva014/Work/Code/FAO/glosis-db/Metadata/scan.py
python /home/carva014/Work/Code/FAO/glosis-db/Metadata/table2xml.py
python /home/carva014/Work/Code/FAO/glosis-db/Metadata/export.py
