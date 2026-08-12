#!/usr/bin/env bash

set -euo pipefail

if [[ -z "${GROQ_API_KEY:-}" ]]; then
  echo "GROQ_API_KEY is not set." >&2
  exit 1
fi

for cmd in curl jq sort; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Missing required command: $cmd" >&2
    exit 1
  fi
done

response_file="$(mktemp)"
trap 'rm -f "$response_file"' EXIT

http_code="$(
  printf 'Authorization: Bearer %s\n' "$GROQ_API_KEY" | curl -sS \
    -o "$response_file" \
    -w '%{http_code}' \
    https://api.groq.com/openai/v1/models \
    -H @-
)"

if [[ "$http_code" != "200" ]]; then
  echo "Failed to query Groq models (HTTP $http_code)." >&2
  cat "$response_file" >&2
  exit 1
fi

echo "All models:"
jq -r '.data[].id' "$response_file" | sort

echo
echo "Speech-related models:"
jq -r '.data[].id | select(test("whisper|speech|audio"; "i"))' "$response_file" | sort

echo
echo "Translation/chat candidates:"
jq -r '.data[].id | select(test("llama|gpt|mixtral|qwen"; "i"))' "$response_file" | sort
