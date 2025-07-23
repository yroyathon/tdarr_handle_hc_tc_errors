# tdarr_handle_hc_tc_errors
Handles Tdarr error/cancelled items in the health check and transcode queues, deletes the files in Sonarr/Radarr, fails the last download to trigger a new search and replacement.
