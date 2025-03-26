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
API_KEY_CKAN=$(cat /home/carva014/Downloads/FAO/API_KEY_CKAN.txt)


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


create_metadata() {
    # Read ID_TOKEN
    source "$TOKEN_CACHE_FILE"
    source "$API_KEY_CKAN"

    # Loop soil properties
    psql -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -U "$DB_USER" -t -A -F"|" -c \
    "SELECT DISTINCT
        m.file_identifier,
        m.mapset_id,
        l.case,
        v.organisation_id,
        i.email,
        o.country,
        o.postal_code,
        o.city,
        o.delivery_point,
        i.individual_id
    FROM metadata.mapset m 
    LEFT JOIN metadata.ver_x_org_x_ind v ON v.mapset_id = m.mapset_id
    LEFT JOIN metadata.individual i ON i.individual_id = v.individual_id
    LEFT JOIN metadata.organisation o ON o.organisation_id = v.organisation_id
    LEFT JOIN (
                SELECT mapset_id, 
                    CASE count(*) WHEN 1 THEN 'map'
                            WHEN 2 THEN 'mapset'
                    END
                FROM metadata.layer
                GROUP BY mapset_id
    ) l ON l.mapset_id = m.mapset_id
    ORDER BY m.mapset_id, v.organisation_id" | \
    while IFS="|" read -r FILE_IDENTIFIER MAP_CODE CASE ORGANISATION_ID EMAIL COUNTRY POSTAL_CODE CITY DELIVERY_POINT INDIVIDUAL_ID; do
        > "$FILE_JSON"
        echo $MAP_CODE

        # Create JSON file
        echo "{" >> "$FILE_JSON"
        echo "\"fileIdentifier\": \"${FILE_IDENTIFIER}\"," >> "$FILE_JSON"
        echo "\"workspace_id\": \"${WORKSPACE}\"," >> "$FILE_JSON"
        echo "\"map_id\": \"${MAP_CODE}\"," >> "$FILE_JSON"
        echo "\"owner_org\": \"glosis\"," >> "$FILE_JSON"
        echo "\"map_type\":\"${CASE}\"," >> "$FILE_JSON"
        echo "\"ckan_url\": \"https://data.apps.fao.org/catalog\"," >> "$FILE_JSON"
        echo "\"user_api_key\": \"${API_KEY_CKAN}\"," >> "$FILE_JSON"
        echo "\"resources\": [" >> "$FILE_JSON"
        echo "    {" >> "$FILE_JSON"
        echo "    \"jsonschema_body\": {" >> "$FILE_JSON"
        echo "        \"organisationName\": \"${ORGANISATION_ID}\"," >> "$FILE_JSON"
        echo "        \"role\": \"pointOfContact\"," >> "$FILE_JSON"
        echo "        \"contactInfo\": {" >> "$FILE_JSON"
        echo "       \"phone\": {" >> "$FILE_JSON"
        echo "            \"voice\": \"\"" >> "$FILE_JSON"
        echo "        }," >> "$FILE_JSON"
        echo "        \"address\": {" >> "$FILE_JSON"
        echo "            \"electronicMailAddress\": \"${EMAIL}\"," >> "$FILE_JSON"
        echo "            \"country\": \"${COUNTRY}\"," >> "$FILE_JSON"
        echo "            \"postalCode\": \"${POSTAL_CODE}\"," >> "$FILE_JSON"
        echo "            \"city\": \"${CITY}\"," >> "$FILE_JSON"
        echo "            \"deliveryPoint\": \"${DELIVERY_POINT}\"" >> "$FILE_JSON"
        echo "        }" >> "$FILE_JSON"
        echo "        }," >> "$FILE_JSON"
        echo "        \"individualName\": \"${INDIVIDUAL_ID}\"" >> "$FILE_JSON"
        echo "    }," >> "$FILE_JSON"
        echo "    \"description\": \"pointOfContact: ${ORGANISATION_ID}\"," >> "$FILE_JSON"
        echo "    \"jsonschema_opt\": {}," >> "$FILE_JSON"
        echo "    \"jsonschema_type\": \"metadata-contact\"," >> "$FILE_JSON"
        echo "    \"name\": \"${ORGANISATION_ID}\"" >> "$FILE_JSON"
        echo "    }" >> "$FILE_JSON"
        echo "]" >> "$FILE_JSON"
        echo "}" >> "$FILE_JSON"

        # Upload or Update metadata
        curl -X POST \
            -H "Content-Type: application/json" \
            -H "Accept: application/json" \
            -H "Authorization: Bearer $ID_TOKEN" \
            -d @$FILE_JSON \
            "https://data.review.fao.org/geospatial/etl/ckan/gismgr"

        if [ $? -eq 0 ]; then
            echo "Successfully processed mapet: $MAP_CODE"
        else
            echo "Failed to process mapet: $MAP_CODE"
        fi

    done
}


# Main script logic
if token=$(is_token_valid); then
    echo "Using cached ID_TOKEN."
    create_metadata
else
    token=$(request_new_token)
    echo "New ID_TOKEN requested."
    create_metadata
fi
