#!/usr/bin/env bash
set -euo pipefail

repo_url="${1:-https://github.com/Izanar/AI_Nginx.git}"
bucket="${2:?Usage: $0 [repo-url] <bucket-name>}"
work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

git clone --depth 1 "$repo_url" "$work_dir/ai-nginx"
test -d "$work_dir/ai-nginx/audio" || {
  echo "The repository does not contain an audio/ directory" >&2
  exit 1
}

aws s3 sync "$work_dir/ai-nginx/audio" "s3://${bucket}/audio" --delete
echo "Audio files synchronized to s3://${bucket}/audio"