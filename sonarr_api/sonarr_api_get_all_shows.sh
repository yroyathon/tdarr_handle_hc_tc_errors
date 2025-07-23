#!/usr/bin/bash
###############################
# Sonarr API Script, Get All Shows Data
# sonarr_api_get_all_shows.sh
###############################

#CHANGE THE APIKEY, PORT AND BASE URL, IF USED
sonarr_url="localhost:SONARRPORT/BASEURL/api/v3"
sonarr_apikey="SONARR_APIKEY"

endpoint="series"
curl -s -H "X-API-KEY: $sonarr_apikey" "http://$sonarr_url/$endpoint"
