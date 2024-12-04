-- OBJECT: observation_phys_chem
-- ISSUE: add min and max values


psql -h localhost -p 5432 -d postgres -U glosis -c "DROP DATABASE IF EXISTS tmp"
psql -h localhost -p 5432 -d postgres -U glosis -c "CREATE DATABASE tmp WITH OWNER = glosis TABLESPACE = database"
psql -h localhost -p 5432 -d tmp -U glosis -c "CREATE EXTENSION postgis"

pg_restore -h localhost \
           -p 5432 \
           -d tmp \
           -U glosis \
           -O \
           -v \
           -j 2 \
           /home/carva014/Documents/Arquivo/Trabalho/isric.backup





psql -h localhost -p 5432 -d tmp -U glosis

SELECT desc_attribute_standard_id,
    phys_chem,
	desc_unit_id,
	decimals,
	minimum,
	maximum,
	accuracy
FROM wosis.desc_attribute_standard
WHERE attribute_type='Layer'
  AND phys_chem IN ('Chemical', 'Physical')
ORDER BY 1,2;



SELECT DISTINCT desc_unit_id
FROM wosis.desc_attribute_standard
WHERE attribute_type='Layer'
  AND phys_chem IN ('Chemical', 'Physical');


