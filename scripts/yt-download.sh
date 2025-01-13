#!/bin/bash
# Variables for the podcast script
if [ -z "${POETRY_HOME+x}" ]; then
  echo "Error: POETRY_HOME is not set."
  echo "be sure to SOURCE ./scripts/source.me"
  exit 1
fi

# Source the environment variables
if [[ ! -f "variables.env" ]]; then
  echo "Error: variables.env file not found. Please create it before running this script."
  exit 1
fi
source "variables.env"

should_stop=false

handle_sigint() {
  echo -e "\nCtrl+C detected. Stopping script..."
  should_stop=true
}
trap handle_sigint SIGINT

while IFS= read -r line || [[ -n "$line" ]]; do
  IFS=',' read -ra fields <<< "$line"

  if $should_stop; then
    echo "Processing stopped."
    break
  fi

  # Skip empty lines or lines starting with '#'
  [[ -z "$line" || "$line" == \#* ]] && continue

  channel_id="${fields[0]}"    # First field
  channel_url="${fields[1]}"     # Second field
  channel_title="${fields[2]}"
  [[ "$channel_id" == "Channel Id" ]] && continue

#   echo "Channel ID: $channel_id"
#   echo "Channel URL: $channel_url"
  echo "Channel Title: $channel_title"

  feed="https://www.youtube.com/feeds/videos.xml?channel_id=$channel_id"

poetry >/dev/null run yt-dlp \
    --dateafter now-7days \
    --download-archive "$archive_file" \
    --output "$video_dir/%(channel)s/%(title)s.%(ext)s" \
    --no-post-overwrites \
    --no-mtime \
    --remux-video mp4 \
    --match-filter "duration <= $duration_threshold" \
    -- "$feed"

  echo "--------------------------"
done < "$csv_file"

# cat subscriptions.csv | grep -v "Channel Id" | grep -v "^#"| cut -d',' -f2 > subscriptions.txt
# yesterday=$(date -v-1d +"%Y%m%d")
# echo $yesterday
# yesterday=20250101
# yt-dlp --dateafter $yesterday --download-archive archive.txt -a subscriptions.txt --extract-audio --audio-format mp3
# poetry run yt-dlp --dateafter $yesterday --download-archive archive.txt -a subscriptions.txt
# poetry run yt-dlp --no-post-overwrites --no-mtime --dateafter now-1day --download-archive archive.txt -a subscriptions.txt
# poetry run yt-dlp --dateafter now-1day --playlist-reverse --max-downloads 5 --download-archive archive.txt -a subscriptions.txt
# poetry run yt-dlp --dateafter $yesterday --playlist-reverse --max-downloads 5 --download-archive archive.txt -a subscriptions.txt
# poetry run yt-dlp \
# --no-post-overwrites \
# --no-mtime \
# --dateafter now-1day \
# --download-archive archive.txt \
# -a subscriptions.txt \
# -o "./new/%(title)s.%(ext)s" 

# https://www.youtube.com/feeds/videos.xml?channel_id=UCBR8-60-B28hp2BmDPdntcQ
