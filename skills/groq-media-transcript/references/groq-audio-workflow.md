# Groq Audio Workflow

## Purpose

This reference documents the recovered workflow used to transcribe media with Groq.

The workflow is:

1. Resolve the playable media URL from a public webpage with `yt-dlp`.
2. Inspect the media stream with `ffprobe`.
3. Extract and normalize audio with `ffmpeg`.
4. Send the normalized audio to Groq `audio/transcriptions`.

## Recovered Reference Commands

### Source resolution

```bash
yt-dlp --no-warnings -f ba/b --get-url '<PAGE_URL>'
yt-dlp --no-warnings --get-title '<PAGE_URL>'
```

### Audio extraction

Recovered RTP example:

```bash
ffmpeg -y -i 'https://streaming-vod.rtp.pt/.../master.m3u8' -vn -ac 1 -ar 16000 -c:a mp3 /tmp/.../rtp_porto_santo.mp3
```

Why:

- `-vn` removes video
- `-ac 1` forces mono
- `-ar 16000` standardizes sample rate
- MP3 temp output keeps the handoff simple for the API request

### Groq transcription

```bash
printf 'Authorization: Bearer %s\n' "$GROQ_API_KEY" | curl -sS https://api.groq.com/openai/v1/audio/transcriptions \
  -H @- \
  -F file=@audio.mp3 \
  -F model=whisper-large-v3 \
  -F language=pt \
  -F response_format=verbose_json \
  -F 'timestamp_granularities[]=segment'
```

Why:

- `verbose_json` gives segment data back
- `timestamp_granularities[]=segment` preserves timing needed for readable transcript output
- `language=pt` stabilizes Portuguese recognition when the source language is already known

## Helper Tools

- `yt-dlp`: resolves direct media URLs from page URLs and works well for RTP/HLS-style sources
- `ffprobe`: surfaces duration and stream layout before extraction
- `ffmpeg`: extracts and normalizes audio to a predictable format
- `curl`: keeps the Groq interaction SDK-free and inspectable
- `jq`: prepares segment JSON and renders deterministic output

## Failure Modes

- `yt-dlp` cannot resolve the page: likely unsupported page, geoblock, login, or DRM
- `ffmpeg` fails on the stream: likely unsupported source, expired HLS URL, or extractor drift
- Groq returns 400/404 for model or request fields: likely model or API drift
- Groq returns 429: read `retry-after` and the `x-ratelimit-*-reset-*` headers
  before retrying; these expose the wait and reset times
- Groq returns non-JSON or missing segments: inspect raw response before retrying

## Self-Healing Procedure

When the script fails because Groq-side assumptions appear stale:

1. Run `scripts/check_groq_models.sh`.
2. Compare the available models with the defaults in the script.
3. Re-open the official docs and check whether:
   - the endpoint still exists
   - the request fields are unchanged
   - the recommended STT model changed
4. Summarize the drift for the user.
5. Ask whether to update the skill before changing files.

Do not mutate the skill automatically during a production task run.

## Official Docs

- Groq Speech to Text: <https://console.groq.com/docs/speech-to-text>
- Groq API Reference: <https://console.groq.com/docs/api-reference>
- Groq Audio Transcriptions endpoint: <https://console.groq.com/docs/api-reference#audio-create-transcription>
