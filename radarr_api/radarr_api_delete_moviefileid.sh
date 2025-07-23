#!/usr/bin/bash
###############################
# Radarr API Script, Delete Movie by Movie File Id
# radarr_api_delete_moviefileid.sh
###############################

id="$1"

#delete a movie file, given its id
if [ -z "$id" ] ; then
    echo "missing MovieFileId parameter, exiting"
    exit 1
fi

#CHANGE THE APIKEY, PORT AND BASE URL, IF USED
radarr_url="localhost:RADARRPORT/BASEURL/api/v3"
radarr_apikey="RADARR_APIKEY"

endpoint="moviefile/$id"

#just...leave all fields as is
curl -X DELETE -H "X-API-KEY: $radarr_apikey" "$radarr_url/$endpoint?id=$id"
