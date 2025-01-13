# YT-DLP-FUN

- A set of bash scripts to download favorite youtube subscriptions, extract the audio, and send them to a personal podcast channel for easy review

## TODO

- don't process LIVE or overly long videos / audios
- set the # of days (currently hard-coded to 7 days prior)
- manage purging of reviewed audios/videos
- verify that duplicates do not occur
- downloads are in .webm format, is that a concern?
- performance
  - it takes about 5 secs per channel, and of course download rates when there are new videos
  - can we download just the audio?
- error handling.
  - some of the scripts log to a log file, others not so much
  - should we stop if there's an error? currently we push along

## Running

- The scripts depend upon python3 and poetry. Installation is beyond the scope of this document
- The scripts also depend upon the AWS CLI being installed and configured. Installation is beyond the scope of this document
- `poetry lock && poetry install` # one time for set up
- `source ./scripts/source.me`
    - sets environment vars, path
- `cd podcasts/drfrancintosh`
- `all.sh`

## Folder Structure

- ./podcasts/ - a parent folder for all podcasts to be created, one per "channel"
  - [podcast name]/
    - videos/ - a folder to hold downloaded videos
      - [channel] - a folder per channel that is subscribed to
    - audios/ - a folder to hold extracted audios
      - [channel] - a folder per channel that is subscribed to
    - archive.txt - a file of videos previously downloaded that should not be re-downloaded
    - artwork.jpg - the artwork for the podcast rss feed
    - subscriptions.csv - the output from Google Takeout for all your subscriptions (optionally sorted)
    - variables.env - variables that drive the scripts, customized for this podcast
    - rss.xml - the generated rss feed 

## Secrets.env

- You should keep any passwords, etc in a ~/secrets.env file and source that file 
- Don't keep secrets in this folder

## AWS S3

- this project expects that you have access to S3 buckets
- the bucket should
  - Have ACLs turned off
  - Be a `Static website hosting` enabled
  - Set the `Bucket Policy Permissions` as below:
- the `variables.env` file should set
  - s3_bucket     # Replace with your S3 bucket name
  - s3_folder     # Folder inside the S3 bucket to store files
- all audio files and the rss.xml will be delivered to ${s3_bucket}/${s3_folder}/
- NOTE: files are stored in a flat organization with [channel_name]:[file_name]

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadForStaticWebsite",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::[your-bucket-name]/*"
        }
    ]
}
```

## Scripts

- all.sh - run all the scripts
  - yt-download.sh - download the most recent youtube videos from `subscriptions.csv` and store them in `./videos/channel-name`
  - split-audios.sh - split the audio out of the videos and store in `./audios/channel-name`
  - upload-files-to-s3.sh - send the files to the S3 bucket
  - upload-rss-feed-to-s3.sh - send the rss feed to the S3 bucket

