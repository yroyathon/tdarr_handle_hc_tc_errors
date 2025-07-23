#!/usr/bin/bash
###############################
# Handle Healthcheck/Transcode Failures in Tdarr
# handle_healthcheck_transcode_failures.sh
###############################

set -e

echo "Tdarr Healthcheck Transcode Failure Handler STARTED at $(date)"

#GLOBAL SETTINGS, CHANGE ALL OF THESE
#where this script is, for creating temp files
working_dir="/PATH/TO/THIS/SCRIPT"
#tdarr api settings
tdarr_ip="localhost:TDARR_SERVER_PORT"
tdarr_apikey="TDARR_TOOLS_APIKEY"
#Several calls to radarr/sonarr api scripts are needed, this is where they live
radarr_api_scripts_dir="/PATH/TO/RADARR/SCRIPTS"
sonarr_api_scripts_dir="/PATH/TO/SONARR/SCRIPTS"

#tdarr api endpoint for grabbing stats and queue contents
endpoint="cruddb"

result=$(curl -s -X POST "http://${tdarr_ip}/api/v2/$endpoint" -d '{"data": {"collection": "StatisticsJSONDB", "mode": "getById", "docID": "statistics"}}' -H "x-api-key: ${tdarr_apikey}" -H "Content-Type: application/json")

hold_queue_count=$(echo "$result" | jq '.table0Count')
transcode_queue_count=$(echo "$result" | jq '.table1Count')
transcode_success_count=$(echo "$result" | jq '.table2Count')
transcode_error_count=$(echo "$result" | jq '.table3Count')
healthcheck_queue_count=$(echo "$result" | jq '.table4Count')
healthcheck_success_count=$(echo "$result" | jq '.table5Count')
healthcheck_error_count=$(echo "$result" | jq '.table6Count')

if [ "$hold_queue_count" -gt "0" ] ; then
    echo "hold_queue_count:$hold_queue_count"
fi
if [ "$transcode_queue_count" -gt "0" ] ; then
    echo "transcode_queue_count:$transcode_queue_count"
fi
if [ "$transcode_success_count" -gt "0" ] ; then
    echo "transcode_success_count:$transcode_success_count"
fi
if [ "$transcode_error_count" -gt "0" ] ; then
    echo "transcode_error_count:$transcode_error_count"
fi
if [ "$healthcheck_queue_count" -gt "0" ] ; then
    echo "healthcheck_queue_count:$healthcheck_queue_count"
fi
if [ "$healthcheck_success_count" -gt "0" ] ; then
    echo "healthcheck_success_count:$healthcheck_success_count"
fi
if [ "$healthcheck_error_count" -gt "0" ] ; then
    echo "healthcheck_error_count:$healthcheck_error_count"
fi

#early exit, no tc or hc errors
if [ "$transcode_error_count" -eq "0" ] && [ "$healthcheck_error_count" -eq "0" ] ; then
    echo "Tdarr Healthcheck Transcode Failure Handler FINISHED at $(date)"
    echo "----------------------------------"
    exit 0
fi

#query a different collection and mode to get all files...
result=$(curl -s -X POST "http://${tdarr_ip}/api/v2/$endpoint" -d '{"data": {"collection": "FileJSONDB", "mode": "getAll"}}' -H "x-api-key: ${tdarr_apikey}" -H "Content-Type: application/json")

#      1 "Error"
#      1 "Ignored"
#      1 "Queued"
#      1 "Success"
#unique hc values

#      1 "Ignored"
#      1 "Not required"
#      1 "Transcode error"
#      1 "Transcode success"
#unique tc values

#pull all movies and shows
all_movies=$(${radarr_api_scripts_dir}/radarr_api_get_all_movies.sh)
all_shows=$(${sonarr_api_scripts_dir}/sonarr_api_get_all_shows.sh)

#save all shows to a file, just the path
alltvshowpaths_filename="${working_dir}/tmp_allpaths.txt"
echo "$all_shows" | jq -c '.[] | .path' > $alltvshowpaths_filename

#save all shows to a file as well
alltvshows_filename="${working_dir}/tmp_allshows.txt"
echo "$all_shows" | jq -c '.[]' > $alltvshows_filename

#save all movies to a file
allmovies_filename="${working_dir}/tmp_allmovies.txt"
echo "$all_movies" | jq -c ".[]" > $allmovies_filename

hc_filename="${working_dir}/tmp_hcfiles.txt"
#first empty the healthcheck file
> $hc_filename

#if either healthcheck or transcode have errors...
if [ "$healthcheck_error_count" -gt "0" ] || [ "$transcode_error_count" -gt "0" ] ; then
    #collect healthcheck failures
    echo "$result" | jq -c '.[] | select( .HealthCheck == "Error") | .file' > $hc_filename

    #APPEND Transcode failures
    echo "$result" | jq -c '.[] | select( .TranscodeDecisionMaker == "Transcode error") | .file' >> $hc_filename

    #Make them unique, get rid of any dupes
    cat $hc_filename | sort -u > ${working_dir}/tmp_swap_data.txt
    mv ${working_dir}/tmp_swap_data.txt $hc_filename

    echo "final/unique transcode/healthcheck errors:"
    cat $hc_filename

    #for each healthcheck/transcode error...
    while IFS= read -r hc_line; do
        #return what meta we found
        found_result=""
        #movie or tvshow, dep if found in radarr or sonarr
        found_type=""

        #remove double quotes, when i goto compare
        hc_line_noquotes=$(echo "$hc_line" | tr -d '"')

        #confirm this is a file AND it exists, NOT a directory, safety precaution in case tdarr has stale items in its queue
        if [ -f "$hc_line_noquotes" ] ; then
            echo "HC line($hc_line) is a FILE."
        else
            echo "HC line($hc_line) is NOT a file, skipping..."
            continue
        fi

        #look for movie by path, just keep what i need downstream at this point
        movie_result=$(cat $allmovies_filename | jq "select( .movieFile.path == $hc_line) | .id, .movieFileId" | tr "\n" ',')
        if [ "$movie_result" != "" ] ; then
            #echo "Found match in movies, $movie_result"
            found_result="$movie_result"
            found_type="movie"
        fi

        #only look thru tv shows if i didn't find it in a movie
        if [ "$found_type" = "" ] ; then
            #iterate over each show path, this is the only way to make a match of hc_path ~= a_path + wildcard
            while IFS= read -r a_path; do
                #echo "a path:$a_path"
                a_path_noquotes=$(echo "$a_path" | tr -d '"')

                #does hc_line start with path? only matching to base show path and Not episode full path, the full episode json is Not well-formatted, cannot parse it
                if [[ $hc_line_noquotes == $a_path_noquotes* ]] ; then
                    #echo "found a match, $a_path_noquotes is in $hc_line_noquotes"
                    found_result="$a_path"
                    found_type="tvshow"
                    break
                fi
            done < "$alltvshowpaths_filename"
        fi

        #ACT ON THE INFO i have collected from the match, ie tell sonarr/radarr, kill the file, fail the last dl which matches movie/season and ep num
        if ! [ "$found_type" = "" ] ; then
            echo "Found ${found_type^^} match for $hc_line , match is $found_result"
            if [ "$found_type" = "tvshow" ] ; then
                echo "SONARR stuff"

                #try to extract season # from hc_line, trim off leading 0s in case i need to match against these
                season_number=$(echo "$hc_line" | sed -E "s:.*(s|S)([0-9]{1,3})(e|E)([0-9]{1,3})[^0-9].*:\2:" | sed -E "s:^0::g")
                episode_number=$(echo "$hc_line" | sed -E "s:.*(s|S)([0-9]{1,3})(e|E)([0-9]{1,3})[^0-9].*:\4:" | sed -E "s:^0::g")
                echo "Season number:$season_number"
                echo "Episode number:$episode_number"

                #SKIP if either season or epsiode number is blank
                if [ "$season_number" = "" ] ; then
                    echo "BLANK seaon number, skipping"
                    continue
                fi
                if [ "$episode_number" = "" ] ; then
                    echo "BLANK episode number, skipping"
                    continue
                fi

                #get the sonarr id, using the found path and the all tv shows file
                series_id=$(echo "$all_shows" | jq ".[] | select(.path == $found_result) | .id")
                echo "series_id:$series_id"

                #get sonarr series data just for this season
                episode_data=$(${sonarr_api_scripts_dir}/sonarr_api_get_episode_data.sh "$series_id" "$season_number")

                #filter series down to just this episode
                episode_id=$(echo "$episode_data" | jq ".[] | select(.episodeNumber == $episode_number) | .id")

                #is it blank? skip if so
                if [ -z "$episode_id" ] ; then
                    echo "Could not derive episode_id, skipping"
                    continue
                fi

                echo "episode_id:$episode_id"

                #get episode file id needed for deleting episode file using sonarr
                episode_file_id=$(echo "$episode_data" | jq ".[] | select(.episodeNumber == $episode_number) | .episodeFileId")

                #check if it's blank, if it is i can't delete it later
                if [ -z "$episode_file_id" ] ; then
                    echo "blank episode file id, skipping"
                    continue
                fi

                echo "episode_file_id:$episode_file_id"

                #get history episode id using episode_id, sort order here is naturally good, most recent at top which is what I want with grabbed, want to fail the last grabbed
                history_ep_id=$(${sonarr_api_scripts_dir}/sonarr_api_get_history.sh $series_id $season_number "grabbed" | jq ".[] | select(.episodeId == $episode_id) | .id" | head -1)
                echo "first_history_id_ep_id:$history_ep_id"

                #skip if history ep id is blank
                if [ -z "$history_ep_id" ] ; then
                    echo "History id blank, cannot mark as failed, skipping"
                    continue
                fi

                echo "history_ep_id:$history_ep_id"

                #delete file in sonarr
                ${sonarr_api_scripts_dir}/sonarr_api_delete_episodefileid.sh $episode_file_id
                echo "File deleted in Sonarr."

                #mark it as failed
                ${sonarr_api_scripts_dir}/sonarr_api_fail_history_item.sh $history_ep_id
                echo "Last DL marked as failed in Sonarr."
            elif [ "$found_type" = "movie" ] ; then
                echo "RADARR stuff"
                #get various ids from radarr for this movie, from the found_result
                movie_id=$(echo $found_result | cut -f1 -d,)
                movie_file_id=$(echo $found_result | cut -f2 -d,)

                echo "movie_id:$movie_id, movie_file_id:$movie_file_id"

                #skip if either movie_id or movie file id is blank
                if [ -z "$movie_id" ] ; then
                    echo "Blank movie id, skipping"
                    continue
                fi
                if [ -z "$movie_file_id" ] ; then
                    echo "Blank movie file id, skipping"
                    continue
                fi

                #find the most recent history grab for this movie
                history_movie_id=$(${radarr_api_scripts_dir}/radarr_api_get_history.sh $movie_id "grabbed" | jq ".[] | select(.movieId == $movie_id) | .id" | head -1)

                if [ -z "$history_movie_id" ] ; then
                    echo "Blank history movie id, skipping"
                    continue
                fi

                echo "history_movie_id:$history_movie_id"

                #delete the movie file in radarr
                ${radarr_api_scripts_dir}/radarr_api_delete_moviefileid.sh $movie_file_id
                echo "File deleted in Radarr."

                #mark it as failed
                ${radarr_api_scripts_dir}/radarr_api_fail_history_item.sh $history_movie_id
                echo "Last DL marked as failed in Radarr."
            else
                echo "BAD found_type, $found_type, exiting"
                exit 1
            fi
        else
            echo "No match found for $hc_line"
        fi
    done < "$hc_filename"
fi

echo "Tdarr Healthcheck Transcode Failure Handler FINISHED at $(date)"
echo "----------------------------------"
