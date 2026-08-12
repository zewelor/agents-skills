#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  check_dependencies.sh [--file | --url | --direct-url]

Options:
  --file         Check dependencies for a local media file (default)
  --url          Also require yt-dlp for resolving a public page URL
  --direct-url   Check a direct media URL; yt-dlp is not required
  --help         Show this help

Exit status:
  0  All required dependencies are available
  2  Dependencies are missing; installation suggestions were printed
EOF
}

MODE="file"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --file)
      MODE="file"
      shift
      ;;
    --url)
      MODE="url"
      shift
      ;;
    --direct-url)
      MODE="direct-url"
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 64
      ;;
  esac
done

REQUIRED_COMMANDS=(
  awk
  basename
  cat
  cp
  curl
  dirname
  ffmpeg
  ffprobe
  head
  jq
  mkdir
  mktemp
  rm
  sleep
  sort
)

if [[ "$MODE" == "url" ]]; then
  REQUIRED_COMMANDS+=(yt-dlp)
fi

missing_commands=()
for command_name in "${REQUIRED_COMMANDS[@]}"; do
  if command_path="$(command -v "$command_name" 2>/dev/null)"; then
    printf '[ok]      %-8s %s\n' "$command_name" "$command_path"
  else
    printf '[missing] %-8s\n' "$command_name"
    missing_commands+=("$command_name")
  fi
done

missing_key=0
if [[ -n "${GROQ_API_KEY:-}" ]]; then
  echo '[ok]      GROQ_API_KEY is set'
else
  echo '[missing] GROQ_API_KEY is not set'
  missing_key=1
fi

if ((${#missing_commands[@]} == 0 && missing_key == 0)); then
  echo
  echo 'Preflight passed. The transcription workflow may continue.'
  exit 0
fi

apt_packages=()
add_apt_package() {
  local package_name="$1"
  local existing

  for existing in "${apt_packages[@]}"; do
    [[ "$existing" == "$package_name" ]] && return
  done
  apt_packages+=("$package_name")
}

for command_name in "${missing_commands[@]}"; do
  case "$command_name" in
    awk)
      add_apt_package mawk
      ;;
    basename|cat|cp|dirname|head|mkdir|mktemp|rm|sleep|sort)
      add_apt_package coreutils
      ;;
    curl)
      add_apt_package curl
      ;;
    ffmpeg|ffprobe)
      add_apt_package ffmpeg
      ;;
    jq)
      add_apt_package jq
      ;;
    yt-dlp)
      ;;
  esac
done

echo
echo 'No installation was attempted.'

if ((${#apt_packages[@]} > 0)); then
  echo 'Missing OS tools: install their apt packages manually:'
  if command -v apt >/dev/null 2>&1; then
    printf '  sudo apt update\n'
    printf '  sudo apt install -y'
    printf ' %s' "${apt_packages[@]}"
    printf '\n'
  else
    printf '  Use the OS package manager to install: %s\n' "${apt_packages[*]}"
  fi
fi

if [[ " ${missing_commands[*]} " == *' yt-dlp '* ]]; then
  echo
  echo 'Missing Python CLI: yt-dlp.'

  if command -v mise >/dev/null 2>&1; then
    local_mise_tools="$(mise ls --local --no-header 2>/dev/null || true)"
    local_mise_yt_dlp="$(mise ls --local --no-header yt-dlp 2>/dev/null || true)"

    if [[ -n "${local_mise_tools//[[:space:]]/}" ]]; then
      echo 'Project-local mise configuration detected.'
      if [[ -n "${local_mise_yt_dlp//[[:space:]]/}" ]]; then
        echo 'Suggested manual action:'
        echo '  mise install yt-dlp'
      else
        echo 'Suggested manual action:'
        echo '  mise use --env local yt-dlp@latest'
      fi
    else
      echo 'No project-local mise tool configuration detected; mise is available.'
      echo 'Suggested manual action:'
      echo '  mise use --global yt-dlp@latest'
    fi
  elif command -v pipx >/dev/null 2>&1; then
    echo 'mise is unavailable; pipx is available.'
    echo 'Suggested manual action:'
    echo '  pipx install yt-dlp'
  else
    echo 'Neither mise nor pipx is available; use pipx as the fallback.'
    echo 'Suggested manual action:'
    if command -v apt >/dev/null 2>&1; then
      echo '  sudo apt update'
      echo '  sudo apt install -y pipx'
      echo '  pipx ensurepath'
      echo '  pipx install yt-dlp'
    else
      echo '  Install pipx with your OS package manager.'
      echo '  pipx ensurepath'
      echo '  pipx install yt-dlp'
    fi
  fi
fi

if ((missing_key == 1)); then
  echo
  echo 'Missing configuration: set GROQ_API_KEY in the environment.'
fi

echo
echo 'STOP: do not run the transcription command yet.'
echo 'After the user completes the suggestions, ask them to confirm that the tools are installed.'
echo 'Then rerun this preflight before continuing.'
exit 2
