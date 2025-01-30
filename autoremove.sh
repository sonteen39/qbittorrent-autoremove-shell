#!/bin/bash

# ตั้งค่าตัวแปร
QBITTORRENT_HOST="http://localhost:8080"  # แก้ไขเป็น host และ port ของ qBittorrent
QBITTORRENT_USERNAME="admin"              # ชื่อผู้ใช้ qBittorrent
QBITTORRENT_PASSWORD="adminadmin"         # รหัสผ่าน qBittorrent
COOKIE_FILE="/tmp/qbittorrent_cookie.txt" # ไฟล์เก็บคุกกี้
LOG_FILE="/var/log/qbittorrent_cleanup.log" # ไฟล์เก็บ log

# ล็อกอินและเก็บคุกกี้
curl -s -c "$COOKIE_FILE" -X POST "$QBITTORRENT_HOST/api/v2/auth/login" \
    -d "username=$QBITTORRENT_USERNAME" \
    -d "password=$QBITTORRENT_PASSWORD" > /dev/null

# ดึงรายการ torrent ทั้งหมด
TORRENT_LIST=$(curl -s -b "$COOKIE_FILE" "$QBITTORRENT_HOST/api/v2/torrents/info")

# วนลูปตรวจสอบแต่ละ torrent
echo "$TORRENT_LIST" | jq -c '.[]' | while read -r TORRENT; do
    HASH=$(echo "$TORRENT" | jq -r '.hash')
    NAME=$(echo "$TORRENT" | jq -r '.name')
    LAST_ACTIVITY=$(echo "$TORRENT" | jq -r '.last_activity')
    CURRENT_TIME=$(date +%s)
    LAST_ACTIVITY_TIME=$(date -d "$LAST_ACTIVITY" +%s)
    DIFF_DAYS=$(( (CURRENT_TIME - LAST_ACTIVITY_TIME) / 86400 ))

    # ถ้า last activity มากกว่า 10 วัน
    if [ "$DIFF_DAYS" -gt 10 ]; then
        echo "Deleting torrent: $NAME (Last activity: $LAST_ACTIVITY)" >> "$LOG_FILE"
        
        # ลบ torrent และไฟล์
        curl -s -b "$COOKIE_FILE" -X POST "$QBITTORRENT_HOST/api/v2/torrents/delete" \
            -d "hashes=$HASH" \
            -d "deleteFiles=true" >> "$LOG_FILE"
    fi
done

# ลบไฟล์คุกกี้
rm -f "$COOKIE_FILE"
