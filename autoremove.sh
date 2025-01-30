#!/bin/bash


QBITTORRENT_HOST="http://localhost:8080"  
QBITTORRENT_USERNAME="admin"              
QBITTORRENT_PASSWORD="adminadmin"         
COOKIE_FILE="/tmp/qbittorrent_cookie.txt" 
LOG_FILE="/var/log/qbittorrent_cleanup.log" 


curl -s -c "$COOKIE_FILE" -X POST "$QBITTORRENT_HOST/api/v2/auth/login" \
    -d "username=$QBITTORRENT_USERNAME" \
    -d "password=$QBITTORRENT_PASSWORD" > /dev/null


TORRENT_LIST=$(curl -s -b "$COOKIE_FILE" "$QBITTORRENT_HOST/api/v2/torrents/info")


echo "$TORRENT_LIST" | jq -c '.[]' | while read -r TORRENT; do
    HASH=$(echo "$TORRENT" | jq -r '.hash')
    NAME=$(echo "$TORRENT" | jq -r '.name')
    LAST_ACTIVITY=$(echo "$TORRENT" | jq -r '.last_activity')
    CURRENT_TIME=$(date +%s)
    DIFF_DAYS=$(( (CURRENT_TIME - LAST_ACTIVITY) / 86400 ))

    
    if [ "$DIFF_DAYS" -gt 10 ]; then
        echo "Deleting torrent: $NAME (Last activity: $LAST_ACTIVITY)" >> "$LOG_FILE"
        
        
        curl -s -b "$COOKIE_FILE" -X POST "$QBITTORRENT_HOST/api/v2/torrents/delete" \
            -d "hashes=$HASH" \
            -d "deleteFiles=true" >> "$LOG_FILE"
    fi
done


rm -f "$COOKIE_FILE"
