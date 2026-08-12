#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  transcribe.sh <input-file-or-url> [options]
  transcribe.sh --file <path> [options]
  transcribe.sh --url <url> [options]

Options:
  --input <path-or-url>    Input local file path or media URL
  --file <path>            Explicit local media file path
  --url <url>              Explicit public page or media URL
  --stt-model <id>         STT model to use (default: whisper-large-v3)
  --language <code>        Optional source language hint, e.g. pt, en, es
  --workdir <path>         Existing working directory for artifacts
  --keep-artifacts         Keep intermediate files instead of deleting temp dir
  --help                   Show this help

Environment:
  GROQ_API_KEY                 Groq API Key (required)
  GROQ_HTTP_TIMEOUT            Per-request curl timeout in seconds (default: 600)
  GROQ_MAX_RATE_LIMIT_RETRIES Maximum automatic 429 retries (default: 3)
  GROQ_MAX_RATE_LIMIT_WAIT    Maximum single automatic wait in seconds (default: 900)
EOF
}

log() {
  local tag="$1"
  shift
  printf '[%s] %s\n' "$tag" "$*" >&2
}

die() {
  log error "$*"
  exit 1
}

run_preflight() {
  local mode="$1"
  local script_dir=""
  local preflight_script=""
  local preflight_status=0

  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  preflight_script="$script_dir/check_dependencies.sh"
  if [[ ! -f "$preflight_script" ]]; then
    die "Dependency preflight is missing: $preflight_script"
  fi

  log preflight "Checking dependencies for $mode input"
  if bash "$preflight_script" "--$mode"; then
    return 0
  else
    preflight_status=$?
    exit "$preflight_status"
  fi
}

header_value() {
  local header_file="$1"
  local wanted_header="$2"

  awk -v wanted="$wanted_header" '
    BEGIN { wanted = tolower(wanted) }
    {
      line = $0
      sub(/\r$/, "", line)
      colon = index(line, ":")
      if (colon == 0) next
      name = substr(line, 1, colon - 1)
      if (tolower(name) != wanted) next
      value = substr(line, colon + 1)
      sub(/^[[:space:]]+/, "", value)
      sub(/[[:space:]]+$/, "", value)
      print value
      exit
    }
  ' "$header_file"
}

ceil_seconds() {
  local value="$1"

  if [[ "$value" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    awk -v value="$value" 'BEGIN {
      rounded = int(value)
      if (value > rounded) rounded++
      print rounded
    }'
  fi
}

format_timestamp() {
  awk -v value="$1" 'BEGIN {
    total = int(value + 0.5)
    hours = int(total / 3600)
    minutes = int((total % 3600) / 60)
    seconds = total % 60
    if (hours > 0) {
      printf "%02d:%02d:%02d", hours, minutes, seconds
    } else {
      printf "%02d:%02d", minutes, seconds
    }
  }'
}

format_decimal() {
  awk -v value="$1" 'BEGIN { printf "%.3f", value }'
}

http_error_hint() {
  local status="$1"
  local body_file="$2"
  local body=""
  body="$(cat "$body_file" 2>/dev/null || true)"

  if [[ "$status" == "429" ]] || [[ "$body" == *"1015"* ]]; then
    printf 'Groq rate limit reached. The request is retriable and will be delayed.'
    return
  fi

  if [[ "$body" == *"1010"* ]]; then
    printf 'Groq/Cloudflare rejected the client signature (1010). This step does not set a custom User-Agent.'
    return
  fi

  if [[ "$body" == *"1020"* ]]; then
    printf 'Groq/Cloudflare blocked the request by access policy (1020).'
    return
  fi

  printf 'Groq transcription request failed.'
}

retry_delay_seconds() {
  local body_file="$1"
  local retry_after="$2"
  local body=""
  local body_delay=""
  local parsed_delay=""

  parsed_delay="$(ceil_seconds "$retry_after")"
  if [[ -n "$parsed_delay" ]] && ((parsed_delay > 0)); then
    printf '%s\n' "$parsed_delay"
    return
  fi

  body="$(cat "$body_file" 2>/dev/null || true)"
  if [[ "$body" =~ [Tt][Rr][Yy][[:space:]]+[Aa][Gg][Aa][Ii][Nn][[:space:]]+[Ii][Nn][[:space:]]+([0-9]+([.][0-9]+)?)[[:space:]]*(s|[Ss][Ee][Cc][Oo][Nn][Dd][Ss]) ]]; then
    body_delay="${BASH_REMATCH[1]}"
    parsed_delay="$(ceil_seconds "$body_delay")"
    if [[ -n "$parsed_delay" ]] && ((parsed_delay > 0)); then
      printf '%s\n' "$parsed_delay"
      return
    fi
  fi

  printf '60\n'
}

is_retriable_groq_response() {
  local status="$1"
  local body_file="$2"
  local body=""
  body="$(cat "$body_file" 2>/dev/null || true)"
  [[ "$status" == "429" || "$body" == *"1015"* ]]
}

extract_text_field() {
  local response_file="$1"
  jq -r '.text // empty' "$response_file"
}

default_title_from_url() {
  local input_url="$1"
  local trimmed="${input_url%%\?*}"
  basename "$trimmed"
}

is_direct_media_url() {
  local input_url="$1"
  local path="${input_url%%\?*}"

  [[ "$path" =~ \.(aac|flac|m3u8|m4a|mp3|mp4|ogg|opus|wav|webm)(/)?$ ]]
}

resolve_media_url() {
  local input_url="$1"
  local resolved=""
  local title=""

  log resolve "Resolving media URL"
  resolved="$(yt-dlp --no-warnings -f ba/b --get-url "$input_url" 2>/dev/null | head -n 1 || true)"
  title="$(yt-dlp --no-warnings --get-title "$input_url" 2>/dev/null | head -n 1 || true)"

  if [[ -z "$resolved" ]]; then
    resolved="$input_url"
  fi

  if [[ -z "$title" ]]; then
    title="$(default_title_from_url "$input_url")"
  fi

  printf '%s\n%s\n' "$resolved" "$title"
}

query_groq_models_hint() {
  local checker_dir
  checker_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  if [[ -x "$checker_dir/check_groq_models.sh" ]]; then
    echo "Current model list can be inspected with: $checker_dir/check_groq_models.sh" >&2
  fi
}

print_rate_limit_info() {
  local http_code="$1"
  local headers_file="$2"
  local body_file="$3"
  local retry_after=""
  local limit_requests=""
  local remaining_requests=""
  local reset_requests=""
  local limit_tokens=""
  local remaining_tokens=""
  local reset_tokens=""
  local error_message=""

  retry_after="$(header_value "$headers_file" retry-after)"
  limit_requests="$(header_value "$headers_file" x-ratelimit-limit-requests)"
  remaining_requests="$(header_value "$headers_file" x-ratelimit-remaining-requests)"
  reset_requests="$(header_value "$headers_file" x-ratelimit-reset-requests)"
  limit_tokens="$(header_value "$headers_file" x-ratelimit-limit-tokens)"
  remaining_tokens="$(header_value "$headers_file" x-ratelimit-remaining-tokens)"
  reset_tokens="$(header_value "$headers_file" x-ratelimit-reset-tokens)"
  error_message="$(jq -r '.error.message // empty' "$body_file" 2>/dev/null || true)"

  log retry "Groq rate limit reached (HTTP $http_code)."
  if [[ -n "$retry_after" ]]; then
    log retry "Retry-After: ${retry_after}s."
  else
    log retry "Retry-After header was not supplied."
  fi
  if [[ -n "$remaining_requests$limit_requests$reset_requests" ]]; then
    log retry "Requests: ${remaining_requests:-unknown}/${limit_requests:-unknown} remaining; reset in ${reset_requests:-unknown}."
  fi
  if [[ -n "$remaining_tokens$limit_tokens$reset_tokens" ]]; then
    log retry "Tokens: ${remaining_tokens:-unknown}/${limit_tokens:-unknown} remaining; reset in ${reset_tokens:-unknown}."
  fi
  if [[ -n "$error_message" ]]; then
    log retry "Groq message: $error_message"
  fi
}

INPUT_RAW=""
EXPLICIT_FILE=""
EXPLICIT_URL=""
SOURCE_OPTION_COUNT=0
STT_MODEL="whisper-large-v3"
LANG_HINT=""
WORK_DIR=""
KEEP_ARTIFACTS=0
GROQ_HTTP_TIMEOUT="${GROQ_HTTP_TIMEOUT:-600}"
GROQ_MAX_RATE_LIMIT_RETRIES="${GROQ_MAX_RATE_LIMIT_RETRIES:-3}"
GROQ_MAX_RATE_LIMIT_WAIT="${GROQ_MAX_RATE_LIMIT_WAIT:-900}"

POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --input)
      SOURCE_OPTION_COUNT=$((SOURCE_OPTION_COUNT + 1))
      INPUT_RAW="${2:-}"
      shift 2
      ;;
    --file)
      SOURCE_OPTION_COUNT=$((SOURCE_OPTION_COUNT + 1))
      EXPLICIT_FILE="${2:-}"
      shift 2
      ;;
    --url)
      SOURCE_OPTION_COUNT=$((SOURCE_OPTION_COUNT + 1))
      EXPLICIT_URL="${2:-}"
      shift 2
      ;;
    --stt-model)
      STT_MODEL="${2:-}"
      shift 2
      ;;
    --language)
      LANG_HINT="${2:-}"
      shift 2
      ;;
    --workdir)
      WORK_DIR="${2:-}"
      shift 2
      ;;
    --keep-artifacts)
      KEEP_ARTIFACTS=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    -*)
      log error "Unknown option: $1"
      usage >&2
      exit 1
      ;;
    *)
      POSITIONAL_ARGS+=("$1")
      shift
      ;;
  esac
done

SOURCE_COUNT=$((SOURCE_OPTION_COUNT + ${#POSITIONAL_ARGS[@]}))
if [[ "$SOURCE_COUNT" -gt 1 ]]; then
  die "Specify exactly one input source (one positional argument or one of --input, --file, or --url)."
fi

if [[ "$SOURCE_OPTION_COUNT" -eq 0 && ${#POSITIONAL_ARGS[@]} -eq 1 ]]; then
  INPUT_RAW="${POSITIONAL_ARGS[0]}"
fi

MODE=""
TARGET=""

if [[ -n "$EXPLICIT_FILE" ]]; then
  MODE="file"
  TARGET="$EXPLICIT_FILE"
elif [[ -n "$EXPLICIT_URL" ]]; then
  MODE="url"
  TARGET="$EXPLICIT_URL"
elif [[ -n "$INPUT_RAW" ]]; then
  if [[ -f "$INPUT_RAW" ]]; then
    MODE="file"
    TARGET="$INPUT_RAW"
  elif [[ "$INPUT_RAW" =~ ^[a-zA-Z0-9+.-]+:// ]]; then
    MODE="url"
    TARGET="$INPUT_RAW"
  elif [[ -e "$INPUT_RAW" ]]; then
    MODE="file"
    TARGET="$INPUT_RAW"
  else
    log error "Input '$INPUT_RAW' is neither an existing local file nor a valid URL."
    die "Please check the path or URL provided."
  fi
else
  log error "Missing input. Please specify a file or URL."
  usage >&2
  exit 1
fi

if [[ "$MODE" == "file" ]]; then
  if [[ ! -f "$TARGET" ]]; then
    die "Local file not found or is a directory: $TARGET"
  fi
fi

PREFLIGHT_MODE="$MODE"
if [[ "$MODE" == "url" ]] && is_direct_media_url "$TARGET"; then
  PREFLIGHT_MODE="direct-url"
fi
run_preflight "$PREFLIGHT_MODE"

if ! [[ "$GROQ_HTTP_TIMEOUT" =~ ^[0-9]+([.][0-9]+)?$ ]] || ! awk -v value="$GROQ_HTTP_TIMEOUT" 'BEGIN { exit !(value > 0) }'; then
  die "GROQ_HTTP_TIMEOUT must be a positive number."
fi

if ! [[ "$GROQ_MAX_RATE_LIMIT_RETRIES" =~ ^[0-9]+$ ]]; then
  die "GROQ_MAX_RATE_LIMIT_RETRIES must be a non-negative integer."
fi

if ! [[ "$GROQ_MAX_RATE_LIMIT_WAIT" =~ ^[0-9]+$ ]] || ((GROQ_MAX_RATE_LIMIT_WAIT < 1)); then
  die "GROQ_MAX_RATE_LIMIT_WAIT must be a positive integer."
fi

WORK_DIR_CREATED=0
if [[ -n "$WORK_DIR" ]]; then
  mkdir -p "$WORK_DIR"
else
  WORK_DIR="$(mktemp -d)"
  WORK_DIR_CREATED=1
fi
log summary "Working directory: $WORK_DIR"

cleanup() {
  if [[ "$WORK_DIR_CREATED" -eq 1 && "$KEEP_ARTIFACTS" -eq 0 ]]; then
    rm -rf "$WORK_DIR"
  elif [[ "$KEEP_ARTIFACTS" -eq 1 ]]; then
    log summary "Artifacts kept in: $WORK_DIR"
  fi
}
trap cleanup EXIT

STREAM_INFO_FILE="$WORK_DIR/stream_info.txt"
DURATION_FILE="$WORK_DIR/duration.txt"
AUDIO_FILE="$WORK_DIR/input_audio.mp3"
FFMPEG_LOG="$WORK_DIR/ffmpeg.log"
TRANSCRIPTION_FILE="$WORK_DIR/transcription.json"
TRANSCRIPTION_BODY="$WORK_DIR/transcription_body.json"
TRANSCRIPTION_HEADERS="$WORK_DIR/transcription_headers.txt"

if [[ "$MODE" == "url" ]]; then
  mapfile -t resolved_info < <(resolve_media_url "$TARGET")
  MEDIA_SOURCE="${resolved_info[0]}"
  log resolve "Resolved media URL: $MEDIA_SOURCE"
else
  MEDIA_SOURCE="$TARGET"
  log input "Using local media file: $MEDIA_SOURCE"
fi

ffprobe -v error \
  -show_entries stream=codec_type \
  -of default=noprint_wrappers=1:nokey=1 \
  "$MEDIA_SOURCE" >"$STREAM_INFO_FILE" || true

ffprobe -v error \
  -show_entries format=duration \
  -of default=noprint_wrappers=1:nokey=1 \
  "$MEDIA_SOURCE" >"$DURATION_FILE" || true

log extract "Extracting / normalizing audio to MP3"
if ! ffmpeg -nostdin -y \
  -i "$MEDIA_SOURCE" \
  -vn \
  -ac 1 \
  -ar 16000 \
  -c:a mp3 \
  "$AUDIO_FILE" >"$FFMPEG_LOG" 2>&1; then
  log error "Audio extraction failed."
  die "Inspect: $FFMPEG_LOG"
fi

transcribe_audio() {
  local http_code=""
  local retry_count=0
  local transcription_args=(
    -sS
    --max-time "$GROQ_HTTP_TIMEOUT"
    -D "$TRANSCRIPTION_HEADERS"
    -o "$TRANSCRIPTION_BODY"
    -w '%{http_code}'
    https://api.groq.com/openai/v1/audio/transcriptions
    -H @-
    -F "file=@${AUDIO_FILE}"
    -F "model=${STT_MODEL}"
    -F "response_format=verbose_json"
    -F "timestamp_granularities[]=segment"
  )

  if [[ -n "$LANG_HINT" ]]; then
    transcription_args+=(-F "language=${LANG_HINT}")
  fi

  while true; do
    log transcribe "Sending audio to Groq"
    : >"$TRANSCRIPTION_HEADERS"
    if ! http_code="$(printf 'Authorization: Bearer %s\n' "$GROQ_API_KEY" | curl "${transcription_args[@]}")"; then
      die "curl failed while transcribing audio."
    fi

    if [[ "$http_code" == "200" ]]; then
      return 0
    fi

    if is_retriable_groq_response "$http_code" "$TRANSCRIPTION_BODY"; then
      local retry_after=""
      local delay=""
      print_rate_limit_info "$http_code" "$TRANSCRIPTION_HEADERS" "$TRANSCRIPTION_BODY"
      if ((retry_count >= GROQ_MAX_RATE_LIMIT_RETRIES)); then
        log error "Automatic rate-limit retry limit reached (${GROQ_MAX_RATE_LIMIT_RETRIES}). Retry manually after the reset time above."
        exit 1
      fi
      retry_after="$(header_value "$TRANSCRIPTION_HEADERS" retry-after)"
      delay="$(retry_delay_seconds "$TRANSCRIPTION_BODY" "$retry_after")"
      if ((delay > GROQ_MAX_RATE_LIMIT_WAIT)); then
        log error "Groq requested a ${delay}s wait, exceeding the automatic wait cap of ${GROQ_MAX_RATE_LIMIT_WAIT}s. Retry manually after the reset time above."
        exit 1
      fi
      retry_count=$((retry_count + 1))
      log retry "Waiting ${delay}s before retry ${retry_count}/${GROQ_MAX_RATE_LIMIT_RETRIES}."
      sleep "$delay"
      continue
    fi

    log error "$(http_error_hint "$http_code" "$TRANSCRIPTION_BODY")"
    log error "Groq transcription failed (HTTP $http_code). Body follows:"
    cat "$TRANSCRIPTION_BODY" >&2
    query_groq_models_hint
    exit 1
  done
}

validate_and_print_response() {
  local response_file="$1"
  local has_segments=0
  local has_text=0
  local has_valid_transcript_shape=0

  if ! jq -e . "$response_file" >/dev/null 2>&1; then
    log error "Groq returned invalid JSON. Body follows:"
    cat "$response_file" >&2
    query_groq_models_hint
    exit 1
  fi

  if jq -e '.segments | type == "array" and length > 0' "$response_file" >/dev/null 2>&1; then
    has_segments=1
  fi

  if [[ -n "$(extract_text_field "$response_file")" ]]; then
    has_text=1
  fi

  if jq -e '(.text | type == "string") and (.segments | type == "array")' "$response_file" >/dev/null 2>&1; then
    has_valid_transcript_shape=1
  fi

  if [[ "$has_valid_transcript_shape" -eq 1 && "$has_segments" -eq 0 && "$has_text" -eq 0 ]]; then
    log summary "Groq returned an empty transcript; no speech was detected."
    return 0
  fi

  if [[ "$has_segments" -eq 0 && "$has_text" -eq 0 ]]; then
    log error "Groq response included neither segments nor text. Body follows:"
    cat "$response_file" >&2
    query_groq_models_hint
    exit 1
  fi

  if [[ "$has_segments" -eq 1 ]]; then
    jq -r '.segments[] | [.start, .end, .text] | @tsv' "$response_file" | \
    while IFS=$'\t' read -r start end text; do
      printf '[%s-%s] %s\n' "$(format_timestamp "$start")" "$(format_timestamp "$end")" "$text"
    done
    return
  fi

  local duration=""
  local text=""
  duration="$(cat "$DURATION_FILE" 2>/dev/null || true)"
  duration="$(format_decimal "$duration")"
  text="$(extract_text_field "$response_file")"
  printf '[%s-%s] %s\n' "$(format_timestamp 0)" "$(format_timestamp "$duration")" "$text"
}

transcribe_audio
cp "$TRANSCRIPTION_BODY" "$TRANSCRIPTION_FILE"
validate_and_print_response "$TRANSCRIPTION_FILE"
log summary "Transcription complete"
