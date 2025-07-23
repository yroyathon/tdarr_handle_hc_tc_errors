#!/usr/bin/bash
###############################
# Radarr API Script, Get History
# radarr_api_get_history.sh
###############################

movieId="$1"
eventType="$2"
includeMovie="$3"

#Required param
if [ -z "$movieId" ] ; then
    echo "Missing movieId parameter, exiting"
    exit 1
fi

params="movieId=${movieId}"

if ! [ -z "$eventType" ] ; then
    params="${params}&eventType=${eventType}"
fi
if ! [ -z "$includeMovie" ] ; then
    params="${params}&includeMovie=${includeMovie}"
fi

if ! [ -z "$params" ] ; then
    params="?${params}"
fi

#CHANGE THE APIKEY, PORT AND BASE URL, IF USED
radarr_url="localhost:RADARRPORT/BASEURL/api/v3"
radarr_apikey="RADARR_APIKEY"

endpoint="history/movie"
curl -s -H "X-API-KEY: $radarr_apikey" "http://$radarr_url/$endpoint${params}"
