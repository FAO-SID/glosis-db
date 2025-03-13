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
FILE_SLD="/home/carva014/Downloads/data.sld"


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


# Function to create or update (if existis) style in GISMGR
update_style() {

    # Read ID_TOKEN
    source "$TOKEN_CACHE_FILE"
    echo "ID_TOKEN: $ID_TOKEN"

    # Loop soil properties
    psql -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -U "$DB_USER" -t -A -F"|" -c \
    "SELECT property_id, name, unit_id FROM metadata.property WHERE min IS NOT NULL AND property_type='quantitative' ORDER BY property_id" | \
    while IFS="|" read -r PROPERTY_ID NAME UNIT_ID; do
        > "$FILE_JSON"
        STYLE_CODE="SOIL-${PROPERTY_ID}"
        
        # JSON file
        echo "  {" >> "$FILE_JSON"
        echo "    \"workspaceCode\": \"${WORKSPACE}\"," >> "$FILE_JSON"
        echo "    \"code\": \"${STYLE_CODE}\"," >> "$FILE_JSON"
        echo "    \"caption\": \"${NAME} (${UNIT_ID})\"" >> "$FILE_JSON"
        echo "  }" >> "$FILE_JSON"

        # SLD file
        psql -q -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -U "$DB_USER" -t -A -c "SELECT sld FROM metadata.property WHERE property_id = '$PROPERTY_ID'" | sed 's/\\n/\n/g' > $FILE_SLD

        # Check if style exists
        RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $ID_TOKEN" \
            "${BASE_URL}/catalog/workspaces/${WORKSPACE}/styles/${STYLE_CODE}")

        if [ "$RESPONSE" -eq 200 ]; then
            echo "Style ${STYLE_CODE} exists. Updating..."
            HTTP_METHOD="PUT"
            URL="${BASE_URL}/catalog/workspaces/${WORKSPACE}/styles/${STYLE_CODE}"
        elif [ "$RESPONSE" -eq 404 ]; then
            echo "Style ${STYLE_CODE} does not exist. Creating..."
            HTTP_METHOD="POST"
            URL="${BASE_URL}/catalog/workspaces/${WORKSPACE}/styles"
        else
            echo "Error checking style ${STYLE_CODE}, HTTP response: $RESPONSE"
            continue
        fi

        # Upload or Update the style
        curl -X $HTTP_METHOD \
            -H "Content-Type: multipart/form-data" \
            -H "Accept: application/json" \
            -H "Authorization: Bearer $ID_TOKEN" \
            -F "style=@$FILE_JSON; type=application/json" \
            -F "file=@$FILE_SLD" \
            "$URL"

        if [ $? -eq 0 ]; then
            echo "Successfully processed style: $STYLE_CODE"
        else
            echo "Failed to process style: $STYLE_CODE"
        fi

    done
}


# Main script logic
if token=$(is_token_valid); then
    echo "Using cached ID_TOKEN."
    update_style
else
    token=$(request_new_token)
    echo "New ID_TOKEN requested."
    update_style
fi

# Cleanup temp files
rm -f "$JSON_FILE" "$SLD_FILE"
