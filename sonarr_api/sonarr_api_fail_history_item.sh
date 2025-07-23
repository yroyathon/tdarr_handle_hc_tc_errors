#!/usr/bin/bash
###############################
# Sonarr API Script, Mark History Item as Failed
# sonarr_api_fail_history_item.sh
###############################

#given an id, fail one item that came from history
id="$1"

if [ -z "$id" ] ; then
    echo "Missing id parameter, exiting"
    exit 1
fi

#CHANGE THE APIKEY, PORT AND BASE URL, IF USED
sonarr_url="localhost:SONARRPORT/BASEURL/api/v3"
sonarr_apikey="SONARR_APIKEY"

endpoint="history/failed/$id"
curl -X POST -s -H "X-API-KEY: $sonarr_apikey" "http://$sonarr_url/$endpoint?id=$id"
