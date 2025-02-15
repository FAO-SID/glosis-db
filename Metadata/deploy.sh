# psql -h localhost -p 5432 -d postgres -U postgres -c "DROP DATABASE IF EXISTS iso19139"
# psql -h localhost -p 5432 -d postgres -U glosis -c "CREATE DATABASE iso19139"
# psql -h localhost -p 5432 -d iso19139 -U glosis -c "CREATE EXTENSION IF NOT EXISTS postgis"
# psql -h localhost -p 5432 -d iso19139 -U glosis -c 'CREATE EXTENSION IF NOT EXISTS "uuid-ossp"'
# psql -h localhost -p 5432 -d iso19139 -U glosis -c "DROP SCHEMA IF EXISTS metadata CASCADE"
# psql -h localhost -p 5432 -d iso19139 -U glosis -f /home/carva014/Work/Code/FAO/glosis-db/Metadata/db_model.sql
psql -q -h localhost -p 5432 -d iso19139 -U glosis -c "DELETE FROM metadata.project"
psql -q -h localhost -p 5432 -d iso19139 -U glosis -c "DELETE FROM metadata.country"
psql -q -h localhost -p 5432 -d iso19139 -U glosis -c "DELETE FROM metadata.property"
psql -q -h localhost -p 5432 -d iso19139 -U glosis -c "DELETE FROM metadata.layer_manual_metadata"
cat FAO/glosis-db/Metadata/data_country.tsv | psql -q -h localhost -p 5432 -d iso19139 -U glosis -c "COPY metadata.country FROM STDIN WITH DELIMITER E'\t'"
cat FAO/glosis-db/Metadata/data_property.tsv | psql -q -h localhost -p 5432 -d iso19139 -U glosis -c "COPY metadata.property(property_id,name,uri) FROM STDIN WITH DELIMITER E'\t' CSV HEADER"
echo 'Adding manual metadata ...'
cat FAO/glosis-db/Metadata/data_PH_metadata.tsv | psql -q -h localhost -p 5432 -d iso19139 -U glosis -c "COPY metadata.layer_manual_metadata FROM STDIN WITH DELIMITER E'\t' CSV HEADER"
eval "$(conda shell.bash hook)"
conda activate db
python /home/carva014/Work/Code/FAO/glosis-db/Metadata/scan.py
python /home/carva014/Work/Code/FAO/glosis-db/Metadata/table2xml.py
python /home/carva014/Work/Code/FAO/glosis-db/Metadata/export.py
