#!/bin/bash

upload() {
  local_path=$1
  s3_uri=$2

  echo "$(date) start upload files"
  aws s3 sync ${local_path} "${s3_uri}" --delete
  echo "$(date) end upload files"
}

download() {
  s3_uri=$1
  local_path=$2

  echo "$(date) start download files"
  aws s3 sync "${s3_uri}" ${local_path} --delete
  echo "$(date) end download files"
}

echo_usage() {
  echo "Usage: $0 [upload|download] <LocalPath> <S3Uri>|<S3Uri> <LocalPath>"
}

if test @$1 = @--help -o @$1 = @-h; then
  echo_usage
  exit 0
fi

if [[ $# -lt 2 ]]; then
  echo_usage
  exit 1
fi

case "$1" in
  "upload")
    upload "$2" "$3"
    ;;
  "download")
    download "$2" "$3"
    ;;
  *)
    exit 1
    ;;
esac