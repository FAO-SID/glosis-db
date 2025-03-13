#!/bin/bash

# vars
DB_HOST="localhost"
DB_PORT="5432"
DB_NAME="iso19139"
DB_USER="glosis"
BASE_URL=https://data.apps.fao.org/gismgr/api/v2
WORKSPACE="GLOSIS"
API_KEY=$(cat /home/carva014/Downloads/FAO/API_KEY.txt)
TOKEN_CACHE_FILE="/home/carva014/Downloads/FAO/API_ID_TOKEN.txt"
FILE_JSON="/home/carva014/Downloads/data.json"


# Function to request a new ID_TOKEN
request_new_token() {
    echo "Requesting new ID_TOKEN..."
    response=$(curl -s -X "POST" \
        -H "X-GISMGR-API-KEY: ${API_KEY}" \
        -H "Accept: application/json" \
        -H "Content-Length: 0" \
        "${BASE_URL}/catalog/identity/accounts:signInWithApiKey")

    # Extract the ID_TOKEN and expiration time from the response
    id_token=$(echo "$response" | jq -r '.response.idToken')
    expires_in=$(echo "$response" | jq -r '.response.expiresIn')
    timestamp=$(echo "$response" | jq -r '.timestamp')

    # Calculate the expiration timestamp (current timestamp + expires_in)
    expires_at=$((timestamp + expires_in * 1000))  # Convert expires_in to milliseconds

    # Save the ID_TOKEN and expiration timestamp to the cache file
    echo "ID_TOKEN=${id_token}" > "$TOKEN_CACHE_FILE"
    echo "EXPIRES_AT=${expires_at}" >> "$TOKEN_CACHE_FILE"
    echo "New ID_TOKEN saved to cache."
}


# Function to check if the cached ID_TOKEN is still valid
is_token_valid() {
    if [[ ! -f "$TOKEN_CACHE_FILE" ]]; then
        return 1  # Cache file doesn't exist
    fi

    # Load the cached ID_TOKEN and expiration timestamp
    source "$TOKEN_CACHE_FILE"

    # Get the current timestamp in milliseconds
    current_timestamp=$(date +%s%3N)

    # Check if the token is still valid
    if [[ "$current_timestamp" -lt "$EXPIRES_AT" ]]; then
        echo "$ID_TOKEN"  # Token is valid
        return 0
    else
        return 1  # Token is expired
    fi
}


# Function to create or update (if existis) mapset in GISMGR
update_map() {

    # Read ID_TOKEN
    source "$TOKEN_CACHE_FILE"
    echo "ID_TOKEN: $ID_TOKEN"

    # Loop soil properties
    psql -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -U "$DB_USER" -t -A -F"|" -c \
    "SELECT pj.country_id ||'-'|| pj.project_id ||'-'|| pp.property_id map_code,
        'SOIL-'|| pp.property_id style_code,
        UPPER(REPLACE(c.en,' ','_')) country,
        UPPER(REPLACE(REPLACE(REPLACE(REPLACE(pp.name,' - ','_'),' ','_'),'(',''),')','')) property,
        m.title,
        m.abstract,
        COALESCE(pp.unit_id,'unknown') unit_id
    FROM metadata.project pj
    LEFT JOIN metadata.country c ON c.country_id = pj.country_id
    LEFT JOIN metadata.mapset m ON m.project_id = pj.project_id
    LEFT JOIN metadata.property pp ON pp.property_id = m.property_id
    WHERE pp.min IS NOT NULL 
    AND pp.property_type='quantitative'
    AND m.mapset_id IN (SELECT mapset_id FROM metadata.layer GROUP BY mapset_id HAVING count(*)=1)
    ORDER BY pp.property_id;" | \
    while IFS="|" read -r MAP_CODE STYLE_CODE COUNTRY PROPERTY TITLE ABSTRACT UNIT; do
        > "$FILE_JSON"
        echo $MAP_CODE

        # Create JSON file
        echo "{" >> "$FILE_JSON"
        echo "  \"workspaceCode\": \"${WORKSPACE}\"," >> "$FILE_JSON"
        echo "  \"code\": \"${MAP_CODE}\"," >> "$FILE_JSON"
        echo "  \"caption\": \"${TITLE}\"," >> "$FILE_JSON"
        echo "  \"description\": \"${ABSTRACT}\"," >> "$FILE_JSON"
        echo "  \"extensions\": [" >> "$FILE_JSON"
        echo "       \".tif\" " >> "$FILE_JSON"
        echo "  ], " >> "$FILE_JSON"
        echo "  \"styleCode\": \"${STYLE_CODE}\"," >> "$FILE_JSON"
        echo "  \"measureCaption\": null," >> "$FILE_JSON"
        echo "  \"measureUnit\": null," >> "$FILE_JSON"
        echo "  \"scale\": 1," >> "$FILE_JSON"
        echo "  \"offset\": 0," >> "$FILE_JSON"
        echo "  \"classes\": null," >> "$FILE_JSON"
        echo "  \"flags\": null," >> "$FILE_JSON"
        echo "  \"bigTiff\": null," >> "$FILE_JSON"
        echo "  \"tilesSize\": null," >> "$FILE_JSON"
        echo "  \"overviewsResamplingAlgorithm\": \"NEAREST\"," >> "$FILE_JSON"
        echo "  \"tags\": [" >> "$FILE_JSON"
        echo "      \"SOIL\"," >> "$FILE_JSON"
        echo "      \"DIGITAL_SOIL_MAPPING\", " >> "$FILE_JSON"
        echo "      \"${PROPERTY}\"," >> "$FILE_JSON"
        echo "      \"${COUNTRY}\"" >> "$FILE_JSON"
        echo "  ]" >> "$FILE_JSON"
        echo "}" >> "$FILE_JSON"

        # Check if map exists
        RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $ID_TOKEN" \
            "${BASE_URL}/catalog/workspaces/${WORKSPACE}/maps/${MAP_CODE}")
        if [ "$RESPONSE" -eq 200 ]; then
            echo "Map ${MAP_CODE} exists. Updating..."
            HTTP_METHOD="PUT"
            URL="${BASE_URL}/catalog/workspaces/${WORKSPACE}/maps/${MAP_CODE}"
        elif [ "$RESPONSE" -eq 404 ]; then
            echo "Map ${MAP_CODE} does not exist. Creating..."
            HTTP_METHOD="POST"
            URL="${BASE_URL}/catalog/workspaces/${WORKSPACE}/maps"
        else
            echo "Error checking map ${MAP_CODE}, HTTP response: $RESPONSE"
            continue
        fi

        # Upload or Update the map
        curl -X $HTTP_METHOD \
            -H "Content-Type: application/json" \
            -H "Accept: application/json" \
            -H "Authorization: Bearer $ID_TOKEN" \
            -d @$FILE_JSON \
            "$URL"

        if [ $? -eq 0 ]; then
            echo "Successfully processed map: $MAP_CODE"
        else
            echo "Failed to process map: $MAP_CODE"
        fi

    done
}


# Main script logic
if token=$(is_token_valid); then
    echo "Using cached ID_TOKEN."
    update_map
else
    token=$(request_new_token)
    echo "New ID_TOKEN requested."
    update_map
fi
