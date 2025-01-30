Dependencies

sudo apt update

sudo apt install curl jq


permissions

chmod +x /path/to/delete_old_torrents.sh


add to crontab

0 3 * * * /path/to/delete_old_torrents.sh
