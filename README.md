# tdarr_handle_hc_tc_errors
The longer that you use Tdarr, eventually you begin to see items pile up in the health check and transcode error/cancelled queues.  This script keeps those queues clear by deleting the failed file in Sonarr/Radarr, and failing the most recent matching download in Sonarr/Radarr history.  This triggers Sonarr/Radarr to download a replacement file.  I recommend adding the tdarr script in a cronjob or other service, so that it can run repeatedly (every hour or every 6 hours).

# Files
Files include the tdarr script(handle_healthcheck_transcode_failures.sh), 4 radarr api scripts(radarr_api_get_all_movies.sh, radarr_api_get_history.sh, radarr_api_delete_moviefileid.sh, radarr_api_fail_history_item.sh) and 5 sonarr api scripts(sonarr_api_get_all_shows.sh, sonarr_api_get_episode_data.sh, sonarr_api_get_history.sh, sonarr_api_delete_episodefileid.sh, sonarr_api_fail_history_item.sh).

These scripts will not run as-is.  Once you place the scripts on your system, you **must** make a few changes.  In the tdarr script, you'll need to update the GLOBAL SETTINGS variables (paths, ports, apikeys, etc.).  In the sonarr/radarr api scripts, you'll need to update the urls and the apikeys.

## Note
For sonarr/radarr api scripts: I use a Url Base in Sonarr and Radarr.  If you do Not use a Url Base, then the radarr_url (or sonarr_url) should be changed to: radarr_url="localhost:RADARRPORT/api/v3" .
