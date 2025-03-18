#!/bin/bash


# vars
DB_HOST="localhost"
DB_PORT="5432"
DB_NAME="iso19139"
DB_USER="glosis"


## Install gsutil
# cd /home/carva014/Downloads/
# curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-linux-x86_64.tar.gz
# tar -xf google-cloud-cli-linux-x86_64.tar.gz
# ./google-cloud-sdk/install.sh
# # Manually close and restart shell, init and login
# ./google-cloud-sdk/bin/gcloud init


# Copy MAPs
psql -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -U "$DB_USER" -t -A -F"|" -c \
    "SELECT m.mapset_id, l.layer_id||'.tif'
    FROM metadata.mapset m
    LEFT JOIN metadata.layer l ON l.mapset_id = m.mapset_id
    WHERE m.mapset_id IN (SELECT mapset_id FROM metadata.layer GROUP BY mapset_id HAVING count(*)=1)
    ORDER BY l.layer_id;" | \
while IFS="|" read -r MAPSET FILE_NAME; do
    echo $FILE_NAME
    gsutil -mq cp /home/carva014/Downloads/FAO/SIS/PH/Processed/${FILE_NAME}   gs://fao-gismgr-glosis-upload/MAP/${MAPSET}/
done


# Copy MAPSETs
echo ""
psql -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -U "$DB_USER" -t -A -F"|" -c \
    "SELECT m.mapset_id, l.layer_id||'.tif'
    FROM metadata.mapset m
    LEFT JOIN metadata.layer l ON l.mapset_id = m.mapset_id
    WHERE m.mapset_id IN (SELECT mapset_id FROM metadata.layer GROUP BY mapset_id HAVING count(*)>1)
    ORDER BY l.layer_id;" | \
while IFS="|" read -r MAPSET FILE_NAME; do
    echo $FILE_NAME
    gsutil -mq cp /home/carva014/Downloads/FAO/SIS/PH/Processed/${FILE_NAME}   gs://fao-gismgr-glosis-upload/MAPSET/${MAPSET}/
done
