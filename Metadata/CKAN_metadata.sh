#!/bin/bash

# vars
DB_HOST="localhost"
DB_PORT="5432"
DB_NAME="iso19139"
DB_USER="glosis"
BASE_URL=https://data.apps.fao.org/catalog/api
WORKSPACE="GLOSIS"
API_KEY=$(cat /home/carva014/Downloads/FAO/API_KEY_CKAN.txt)
FILE_JSON="/home/carva014/Downloads/data.json"


# Function to create or update (if existis) metadata in GISMGR
update_metadata() {

    # Read ID_TOKEN
    source "$TOKEN_CACHE_FILE"

    # Loop soil properties
    psql -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -U "$DB_USER" -t -A -F"|" -c \
    "SELECT m.metadata_id,
        'SOIL-'|| pp.property_id style_code,
        UPPER(REPLACE(c.en,' ','_')) country,
        UPPER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(pp.name,' - ','_'),' ','_'),'(',''),')',''),'+','')) property,
        m.title,
        m.abstract,
        COALESCE(pp.unit_id,'unknown') unit_id
    FROM metadata.project pj
    LEFT JOIN metadata.country c ON c.country_id = pj.country_id
    LEFT JOIN metadata.metadata m ON m.project_id = pj.project_id
    LEFT JOIN metadata.layer l ON l.metadata_id = m.metadata_id
    LEFT JOIN metadata.property pp ON pp.property_id = m.property_id
    WHERE pp.min IS NOT NULL 
    AND pp.property_type='quantitative'
    AND m.metadata_id IN (SELECT metadata_id FROM metadata.layer GROUP BY metadata_id HAVING count(*)>1)
    ORDER BY pp.property_id;" | \
    while IFS="|" read -r MAP_CODE STYLE_CODE COUNTRY PROPERTY TITLE ABSTRACT UNIT; do
        > "$FILE_JSON"
        echo ""
        echo $MAP_CODE

        # Check if metadata exists
        RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $ID_TOKEN" \
            "${BASE_URL}/catalog/workspaces/${WORKSPACE}/metadatas/${MAP_CODE}")
        if [ "$RESPONSE" -eq 200 ]; then
            echo "Exists. Updating..."
            HTTP_METHOD="PUT"
            URL="${BASE_URL}/catalog/workspaces/${WORKSPACE}/metadatas/${MAP_CODE}"
        elif [ "$RESPONSE" -eq 404 ]; then
            echo "Does not exist. Creating..."
            HTTP_METHOD="POST"
            URL="${BASE_URL}/catalog/workspaces/${WORKSPACE}/package_create"
        else
            echo "Error checking mapet ${MAP_CODE}, HTTP response: $RESPONSE"
            continue
        fi

        # Upload or Update metadata
        curl -X $HTTP_METHOD \
            -H "Content-Type: application/json" \
            -H "Accept: application/json" \
            -H "Authorization: Bearer $ID_TOKEN" \
            -d @$FILE_JSON \
            "$URL"

        if [ $? -eq 0 ]; then
            echo "Successfully processed mapet: $MAP_CODE"
        else
            echo "Failed to process mapet: $MAP_CODE"
        fi

    done
}


curl -X POST http://data.apps.fao.org/api/action/package_create \
-H "Authorization: API-KEY" \
-H "Content-Type: application/json" \
--data-binary @/home/carva014/Downloads/FAO/SIS/PH/Processed/PH-GSAS-SALT-2020.json



