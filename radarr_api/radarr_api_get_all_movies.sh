#!/usr/bin/bash
###############################
# Radarr API Script, Get All Movies Data
# radarr_api_get_all_movies.sh
###############################

#CHANGE THE APIKEY, PORT AND BASE URL, IF USED
radarr_url="localhost:RADARRPORT/BASEURL/api/v3"
radarr_apikey="RADARR_APIKEY"

endpoint="movie"
curl -s -H "X-API-KEY: $radarr_apikey" "http://$radarr_url/$endpoint"
