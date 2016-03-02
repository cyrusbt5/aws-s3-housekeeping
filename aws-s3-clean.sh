#!/usr/bin/env bash
# Usage: ./aws-s3-clean.sh "bucketname" "days"
# Usage: ./aws-s3-clean.sh "bucketname" "--size|-s"
# Usage: ./aws-s3-clean.sh "--help|-h"

set -o errexit  # exit when a command fails.
set -o pipefail # catch pipe fails in e.g. mysqldump | gzip
set -o nounset  # exit when your script tries to use undeclared variables

# set internal field separator
IFS=$'\n\t'

# set default variables for arguments
bucket="${1:-}"
days="${2:-}"

# set s3cmd command
s3cmd=$(command -v s3cmd)

function display_usage() {
  echo -e "\nUsage: clean bucket\n$0 [bucket name] [days]\n"
  echo -e "Usage: get bucket size\n$0 [bucket name] -s|--size\n"
  echo -e "Usage: print help\n$0 -h|--help\n"
}

function display_bucket_size() {
  echo "AWS S3 bucket size $("${s3cmd}" du s3://"${bucket}" | awk '{ printf "%.0f MB\n", $1/1024/1024 }')"
}

if [[ "${bucket}" = "--help" || "${bucket}" = "-h" ]]; then
  display_usage
  exit 0
fi

if [[ "$#" -le 1 ]]; then
  display_usage
  exit 1
fi

if [[ "${days}" = "--size" || "${days}" = "-s" ]]; then
  display_bucket_size
  exit 0
fi

function find_timestamp() {
  case "$OSTYPE" in
    darwin*)
      timestamp=$(date -j -f "%Y-%m-%d" "$(echo "${1}" | awk {'print $1'})" '+%s');
      echo "${timestamp}";
    ;;
    linux*)
      timestamp=$(date -d"$(echo "${1}" | awk {'print $1'})" '+%s');
      echo "${timestamp}";
    ;;
  esac
}

function create_timestamp() {
  case "$OSTYPE" in
    darwin*)
      olderThan=$(date -v"-${days}d" '+%s');
      echo "${olderThan}";
    ;;
    linux*)
      olderThan=$(date -d "-${days} days" '+%s');
      echo "${olderThan}";
    ;;
  esac
}

olderThan=$(create_timestamp)

"${s3cmd}" ls -r s3://"${bucket}" | grep -Eiv "logs/" | while read -r line; do

 timestamp=$(find_timestamp "${line}")

  if [[ "${timestamp}" -lt "${olderThan}" ]]; then
    fileName=$(echo "${line}" | awk {'print $5'})
    if [[ -n "${fileName}" ]]; then
      "${s3cmd}" rm "${fileName}" &> /dev/null
    fi
  fi
done;
display_bucket_size
