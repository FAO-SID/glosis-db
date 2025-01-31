psql -h localhost -p 5432 -d iso28258 -U glosis -c 'CREATE EXTENSION IF NOT EXISTS "uuid-ossp"'
psql -h localhost -p 5432 -d iso28258 -U glosis -f /home/carva014/Work/Code/FAO/glosis-db/Metadata/db_model.sql
