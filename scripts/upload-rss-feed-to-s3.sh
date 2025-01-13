#!/bin/bash

# Source the environment variables
if [[ ! -f "variables.env" ]]; then
  echo "Error: variables.env file not found. Please create it before running this script."
  exit 1
fi
source "variables.env"

# Ensure AWS CLI is installed
if ! command -v aws &> /dev/null; then
  echo "AWS CLI not found. Please install it before running this script."
  exit 1
fi

# Optional: Log output to a file
exec > >(tee -a "$log_file") 2>&1

generate_rss_feed() {
  echo "Generating RSS feed..."
  cat <<EOF > "$rss_file"
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd">
<channel>
  <title>$podcast_title</title>
  <description>$podcast_description</description>
  <link>$base_url</link>
  <language>en-us</language>
  <lastBuildDate>$(date -R)</lastBuildDate>
  <author>$podcast_author</author>
  <itunes:category text="Education"/>
  <itunes:image href="$base_url/artwork.jpg"/>
  <itunes:explicit>no</itunes:explicit>
EOF

  find "$audio_dir" -type f -name "*.mp3" | while IFS= read -r file; do
    file_name=$(basename "$file")  # Extract the file name
    title="${file_name%.mp3}"      # Remove .mp3 extension for the title
    title="${title//_/ }"          # Replace underscores with spaces

    # Extract the subfolder name
    subfolder_name=$(basename "$(dirname "$file")")
    prefix="${subfolder_name//_/ }" # Replace underscores in subfolder name with spaces

    # Add prefix to the title
    title="$prefix: $title"

    url="${base_url}/${file_name}" # Public URL of the audio file
    file_size=$(stat -f "%z" "$file") # Get file size in bytes
    pub_date=$(stat -f "%Sm" -t "%a, %d %b %Y %H:%M:%S %z" "$file")

    # Get audio duration using ffprobe
    duration=$(ffprobe -i "$file" -show_entries format=duration -v quiet -of csv="p=0" | awk '{printf("%d:%02d:%02d", $1/3600, ($1%3600)/60, $1%60)}')

    # Generate a unique GUID
    guid=$(echo -n "$file_name" | shasum -a 256 | awk '{print $1}')

    cat <<EPISODE >> "$rss_file"
  <item>
    <title>$title</title>
    <itunes:subtitle>$prefix</itunes:subtitle>
    <link>$url</link>
    <guid isPermaLink="false">$guid</guid>
    <pubDate>$pub_date</pubDate>
    <enclosure url="$url" type="audio/mpeg" length="$file_size"/>
    <itunes:duration>$duration</itunes:duration>
    <itunes:explicit>no</itunes:explicit>
  </item>
EPISODE
  done

  cat <<EOF >> "$rss_file"
</channel>
</rss>
EOF

  echo "RSS feed generated at $rss_file."
}


upload_rss_feed_to_s3() {
  echo "Uploading RSS feed to S3..."
  s3_rss_path="${s3_folder}/rss.xml"
  aws s3 cp "$rss_file" "s3://${s3_bucket}/${s3_rss_path}" --profile "$aws_profile" --content-type "application/rss+xml"
  echo "RSS feed uploaded to: ${base_url}/rss.xml"
}

# Main execution
generate_rss_feed || { echo "Error: Failed to generate RSS feed."; exit 1; }
# Optional: Validate RSS feed
# validate_rss_feed || { echo "Error: RSS feed validation failed."; exit 1; }
upload_rss_feed_to_s3 || { echo "Error: Failed to upload RSS feed."; exit 1; }
echo "Podcast setup complete!"
