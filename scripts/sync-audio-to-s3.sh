#!/usr/bin/env bash
set -euo pipefail

source="${1:-https://github.com/Izanar/AI_Nginx.git}"
bucket="${2:?Usage: $0 [source-dir-or-repo-url] <bucket-name>}"
work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

if [[ -d "$source/audio" ]]; then
  audio_dir="$source/audio"
else
  git clone --depth 1 "$source" "$work_dir/ai-nginx"
  audio_dir="$work_dir/ai-nginx/audio"
fi

test -d "$audio_dir" || {
  echo "The repository does not contain an audio/ directory" >&2
  exit 1
}

aws s3 sync "$audio_dir" "s3://${bucket}/audio" --delete
echo "Audio files synchronized to s3://${bucket}/audio"
