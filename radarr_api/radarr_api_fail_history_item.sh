#!/usr/bin/bash
###############################
# Radarr API Script, Mark History Item as Failed
# radarr_api_fail_history_item.sh
###############################

#given an id, fail one item that came from history
id="$1"
if [ -z "$id" ] ; then
    echo "Missing id parameter, exiting"
    exit 1
fi

#CHANGE THE APIKEY, PORT AND BASE URL, IF USED
radarr_url="localhost:RADARRPORT/BASEURL/api/v3"
radarr_apikey="RADARR_APIKEY"

endpoint="history/failed/$id"
curl -X POST -s -H "X-API-KEY: $radarr_apikey" "http://$radarr_url/$endpoint?id=$id"
