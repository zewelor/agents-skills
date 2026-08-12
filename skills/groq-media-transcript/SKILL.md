---
name: groq-media-transcript
description: Transcribe audio or video from a local file path or public media URL with Groq, with a read-only dependency preflight that suggests manual installations without installing them. Use when the user wants a timestamped transcript from a local audio/video file or a web URL.
---

# Groq Media Transcript

Each invocation accepts exactly one input source.

Default output is a timestamped transcript. Do not generate a summary unless the user explicitly asks for one.

## Workflow

1. Identify the input type (local file path or public media/page URL).
2. Run `scripts/transcribe.sh` with the input path or URL. The script runs the
   read-only dependency preflight immediately after it determines `file` vs
   `url`, before `ffprobe`, `ffmpeg`, URL resolution, or Groq requests.
3. If the script exits with status `2`, show its suggestions and stop. Never
   run `apt`, `mise install`, `mise use`, `pipx install`, or any other
   installation command yourself. Wait for the user to confirm that the tools
   are installed, then rerun the same transcription command.
4. Return the transcript as timestamped lines in the script's output format.

Do not invoke `check_dependencies.sh` separately during the normal workflow;
`transcribe.sh` calls it internally. The preflight checks the actual external
commands used by the workflow and `check_groq_models.sh`: `ffmpeg`/`ffprobe`,
`curl`, `jq`, `awk`, coreutils, and, for page URLs, `yt-dlp`. Direct media URLs
with a recognized media extension use `ffprobe`/`ffmpeg` without requiring
`yt-dlp`. Check `GROQ_API_KEY` without printing its value.

Interpret “mise-local” as a project-local mise toolset detected with `mise ls
--local`; do not assume that a separate `mise-local` executable exists. When
`yt-dlp` is missing, detect that local toolset first, suggest the local mise
command when it exists, fall back to global `mise`, and fall back to `pipx`
when `mise` is unavailable. Install OS tools such as `curl`, `jq`, and
`ffmpeg` from the `apt` suggestions printed by the checker. Treat this as a
recommendation hierarchy only: never execute those commands from the agent.

When Groq returns `429`, print the reported `Retry-After`, remaining request and
token quotas, reset times, and Groq error message. Retry only within the
script's bounded automatic retry policy; report the reset time and stop when
the bound is reached.

## Commands

Transcribe dynamically (auto-detects local file vs URL):

```bash
scripts/transcribe.sh '<FILE_PATH_OR_URL>'
```

Explicit URL or local file:

```bash
scripts/transcribe.sh --url '<URL>'
scripts/transcribe.sh --file '/path/to/audio.mp3'
```

Keep intermediate JSON for debugging:

```bash
scripts/transcribe.sh '<FILE_OR_URL>' --keep-artifacts
```

## References

Read `references/groq-audio-workflow.md` when you need:

- the recovered RTP/Groq command sequence
- the rationale for `yt-dlp`, `ffprobe`, `ffmpeg`, and the Groq flow
- official documentation links
- drift-handling guidance

## Self-Healing

When the workflow fails, do not guess blindly.

1. Read the error body from the script output.
2. Run `scripts/check_groq_models.sh` to see current model availability.
3. Check the official Groq docs linked in `references/groq-audio-workflow.md`.
4. Compare the failure against the current references:
   - model missing or renamed
   - endpoint shape changed
   - request field changed
   - docs now recommend a different model or format
5. If you detect drift, explain the discrepancy and propose a concrete skill update.
6. Ask the user before editing the skill or changing defaults. Do not silently rewrite the skill during a task run.

If the failure is source-specific, prefer fixing resolution or media extraction first. Use drift diagnosis only when the source itself is not the problem.
