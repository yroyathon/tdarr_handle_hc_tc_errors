#!/usr/bin/bash
###############################
# Sonarr API Script, Delete Episode by Episode File Id
# sonarr_api_delete_episodefileid.sh
###############################

id="$1"

#given an id, delete one episode file
if [ -z "$id" ] ; then
    echo "missing episodeFileId parameter, exiting"
    exit 1
fi

#CHANGE THE APIKEY, PORT AND BASE URL, IF USED
sonarr_url="localhost:SONARRPORT/BASEURL/api/v3"
sonarr_apikey="SONARR_APIKEY"

endpoint="episodefile/$id"

curl -X DELETE -s -H "X-API-KEY: $sonarr_apikey" "$sonarr_url/$endpoint?id=$id"
