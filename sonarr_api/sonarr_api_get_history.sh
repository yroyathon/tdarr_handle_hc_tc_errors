#!/usr/bin/bash
###############################
# Sonarr API Script, Get History
# sonarr_api_get_history.sh
###############################

seriesId="$1"
seasonNumber="$2"
eventType="$3"
includeSeries="$4"
includeEpisode="$5"

#i need series...everything else...can i leave blank?
if [ -z "$seriesId" ] ; then
    echo "Missing seriesId parameter, exiting"
    exit 1
fi

params="seriesId=${seriesId}"

if ! [ -z "$seasonNumber" ] ; then
    params="${params}&seasonNumber=${seasonNumber}"
fi
if ! [ -z "$eventType" ] ; then
    params="${params}&eventType=${eventType}"
fi
if ! [ -z "$includeSeries" ] ; then
    params="${params}&includeSeries=${includeSeries}"
fi
if ! [ -z "$includeEpisode" ] ; then
    params="${params}&includeEpisode=${includeEpisode}"
fi

if ! [ -z "$params" ] ; then
    params="?${params}"
fi

#CHANGE THE APIKEY, PORT AND BASE URL, IF USED
sonarr_url="localhost:SONARRPORT/BASEURL/api/v3"
sonarr_apikey="SONARR_APIKEY"

endpoint="history/series"
curl -s -H "X-API-KEY: $sonarr_apikey" "http://$sonarr_url/$endpoint${params}"
