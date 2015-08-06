#!/usr/bin/env bash
# Usage:   ./aws-s3-clean.sh "bucketname" "days"
# Example: ./aws-s3-clean.sh "bucket-foo" "5"

set -o errexit  # exit when a command fails.
set -o pipefail # catch pipe fails in e.g. mysqldump | gzip
set -o nounset  # exit when your script tries to use undeclared variables

# set internal field separator
IFS=$'\n\t'

# set default variables for arguments
bucket=${1:-}
days=${2:-}

# set s3cmd command
s3cmd=$(command -v s3cmd)

display_usage() {
  echo -e "\nUsage:\n$0 [bucket] [days]\n"
}

display_bucket_size() {
  echo "AWS S3 bucket size $(${s3cmd} du -r s3://${bucket} | awk '{printf "%.0f MB\n", $1/1024/1024 }')"
}

if [[ $# -le 1 ]]; then
  display_usage
  exit 1
fi

if [[ $# == "--help" || $# == "-h" ]]; then
  display_usage
  exit 0
fi

${s3cmd} ls -r s3://${bucket} | grep -Ev "logs/" | while read -r line; do
  # timestamp=$(date -d"$(echo $line | awk {'print $1'})" '+%s')
  timestamp=$(date -j -f "%Y-%m-%d" "$(echo $line | awk {'print $1'})" '+%s')
  if [[ $timestamp -lt $olderThan ]]; then
    fileName=$(echo $line | awk {'print $5'})
    if [[ $fileName != "" ]]; then
      ${s3cmd} rm "${fileName}" > /dev/null 2>&1
    fi
  fi
done;
display_bucket_size
