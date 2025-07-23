#!/usr/bin/bash
###############################
# Sonarr API Script, Get Episode data about a Show
# sonarr_api_get_episode_data.sh
###############################

if [ -z "$1" ] ; then
    echo "missing seriesId parameter, exiting"
    exit 1
fi
if [ -z "$2" ] ; then
    echo "missing season parameter, exiting"
    exit 1
fi

seriesId="$1"
seasonNumber="$2"
#new, optiional
includeEpisodeFile="$3"

#optional arg, is blank otherwise
if ! [ -z "$includeEpisodeFile" ] ; then
    if [ "$includeEpisodeFile" = "true" ] || [ "$includeEpisodeFile" = "false" ] ; then
        echo "adding optional include episode file parameter"
        includeEpisodeFile="&includeEpisodeFile=$includeEpisodeFile"
    fi
fi

#CHANGE THE APIKEY, PORT AND BASE URL, IF USED
sonarr_url="localhost:SONARRPORT/BASEURL/api/v3"
sonarr_apikey="SONARR_APIKEY"

#needs params, seriesId, seasonNumber, episodeField,
endpoint="episode"

#just...leave all fields as is
curl -s -H "X-API-KEY: $sonarr_apikey" "$sonarr_url/$endpoint?seriesId=${seriesId}&seasonNumber=${seasonNumber}${includeEpisodeFile}"
