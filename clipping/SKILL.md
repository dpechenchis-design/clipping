---
name: clipping
description: Cuts a long-form video into final short clips by following a transcript. Each "Clip N" block in the transcript becomes ONE final clip, made by cutting all timecoded fragments inside that block and concatenating them in the order they appear in the transcript. Use whenever the user provides a video file plus a transcript with "Clip 1", "Clip 2" headers and timecoded fragments under each header, and asks to cut, slice, clip, or render the clips.
---

# Clipping Skill

Cuts a long-form video into final short clips, where each clip is a concatenation of multiple non-contiguous fragments from the source video.

## What This Skill Does

For each `Clip N` block in the transcript:

1. Cut every timecoded fragment listed under that header from the source video
2. Concatenate all fragments in the order they appear in the transcript
3. Save as ONE final clip named `Clip_N_Topic.mp4`

The result is one finished clip per `Clip N` block, ready to be published.

## Input Format

The user provides:

- **A video file** — `.mov` or `.mp4` in the working directory
- **A transcript** — `.txt`, `.md`, or `.docx` with this structure:

```
Clip 1 — Topic Name
----------------------------------------------------------------
[00:54 → 01:06] "First fragment text..."

[03:32 → 03:35] "Second fragment text..."

[03:05 → 03:19] "Third fragment text..."

Clip 2 — Another Topic
----------------------------------------------------------------
[04:39 → 04:50] "First fragment of clip 2..."

[05:07 → 05:13] "Second fragment of clip 2..."
```

### Parsing rules

- **Clip header**: a line starting with `Clip ` followed by a number (e.g. `Clip 1`, `Clip 2`). The text after `—` or `-` or `:` is the topic name.
- **Fragment**: a line containing two timecodes in the format `[HH:MM:SS → HH:MM:SS]` or `[MM:SS → MM:SS]`. The arrow can be `→`, `->`, `-`, or `—`.
- **HOOK marker**: the word `HOOK` may appear before a fragment's timecode (e.g. `HOOK [00:54 → 01:06]` or `>>> HOOK [00:54 → 01:06]`). This is a **human-facing label only** — treat the fragment exactly like any other. Do NOT cut it as a separate file, do NOT apply a different buffer to it. The HOOK is simply the first fragment of the clip, which already gets the start buffer because it is first.
- Lines that are not Clip headers or fragments are **ignored** (e.g. quoted spoken text, separators, blank lines, prefix words like `HOOK`).
- Fragments under a header belong to that clip until the next `Clip N` header appears.

## Cutting Rules

### 1. ONE final clip per `Clip N` block

Do NOT produce one file per fragment. Cut all fragments in a block, then concatenate them into one final file.

### 2. Order = order in the transcript

Concatenate fragments in the order they appear in the transcript file, top to bottom. Do NOT reorder chronologically by timecode.

### 3. Buffers (apply only to outer edges of the final clip)

- **5 seconds BEFORE** the start of the FIRST fragment
- **1 second AFTER** the end of the LAST fragment
- **No buffer** on inner fragments — cut them precisely at their timecodes

Why: buffers protect the first word of the clip and avoid abrupt endings. Adding buffers to inner fragments would create overlapping audio or repeated words at every splice point.

### 4. Re-encode every fragment (never `-c copy`)

```bash
# CORRECT — re-encode for precise cuts
ffmpeg -ss <start> -to <end> -i input.mov \
  -c:v libx264 -preset medium -crf 23 \
  -c:a aac -b:a 128k -ar 48000 \
  fragment.mp4
```

`-c copy` cuts at keyframes (every 2-5s), which eats first words, desyncs audio, and breaks concat. Always re-encode.

The audio sample rate `-ar 48000` is important — it ensures all fragments are concat-compatible.

### 5. Concatenate with concat demuxer

After cutting all fragments for a clip into `temp/`, create a concat list file and merge:

```bash
# Create concat list
cat > concat_list.txt <<EOF
file 'temp/clip1_frag1.mp4'
file 'temp/clip1_frag2.mp4'
file 'temp/clip1_frag3.mp4'
EOF

# Concatenate
ffmpeg -f concat -safe 0 -i concat_list.txt -c copy clips/Clip_1_Topic.mp4
```

Since all fragments were re-encoded with identical parameters, `-c copy` at the concat step is safe and fast.

## Workflow

For each `Clip N` block in the transcript:

1. **Extract** all fragments under the header (start, end timecodes, in order).
2. **Create** the `temp/` and `clips/` folders if they don't exist.
3. **Apply buffers**: subtract 5s from the FIRST fragment's start; add 1s to the LAST fragment's end. Leave inner fragments untouched.
4. **Cut** each fragment with re-encode → save to `temp/clip_<N>_frag_<i>.mp4`.
5. **Build** a concat list file in the order fragments appear in the transcript.
6. **Concatenate** with `ffmpeg -f concat -safe 0 -i ... -c copy` → save to `clips/Clip_<N>_<TopicName>.mp4`.
7. **Verify** the output file exists and has reasonable size (>100 KB).
8. **Clean up** `temp/` after all clips are done (optional but recommended).

## Output

```
clips/
├── Clip_1_AllOrNothingMentality.mp4
├── Clip_2_TrackInPercentages.mp4
├── Clip_3_AnotherTopic.mp4
```

### Naming rules

- Format: `Clip_<N>_<TopicName>.mp4`
- TopicName: take the text after `—` / `-` / `:` in the `Clip N` header.
- Sanitize: keep letters, numbers; replace spaces with nothing (PascalCase) or underscores; strip punctuation and special characters.
- Truncate to 60 characters maximum.
- Examples:
  - `Clip 1 — All-or-Nothing Mentality` → `Clip_1_AllOrNothingMentality.mp4`
  - `Clip 2 — Track in Percentages, Not Yes/No` → `Clip_2_TrackInPercentages.mp4`

## Important Notes

- **Always show the user a plan before cutting**: list each clip with its fragments, durations, and the resulting total length. Wait for confirmation.
- **Trust the spoken text more than the timecodes**: if a clip's first words seem cut off, increase the start buffer on that clip (try 7-8s).
- **Never use `-c copy` for the initial cut**: it breaks the workflow. Only the final concat step uses `-c copy` (and only because all fragments are already identical).
- **If a fragment's end ≤ start**: skip it and warn the user.
- **If a fragment's end exceeds video duration**: clamp to the video duration and warn the user.
- **If the user requests a single specific clip** (e.g. "only Clip 3"): process only that block, ignore others.
- **If the user changes buffer values**: apply the new values to the OUTER edges (first fragment start, last fragment end), not to inner fragments.

## Folder Structure

```
working-directory/
├── video.mov                    # input video
├── transcript.txt               # input transcript
├── temp/                        # intermediate fragments (auto-created)
│   ├── clip_1_frag_1.mp4
│   ├── clip_1_frag_2.mp4
│   └── ...
├── clips/                       # final output (auto-created)
│   ├── Clip_1_Topic.mp4
│   └── ...
└── concat_list_<N>.txt          # temporary concat lists (auto-created)
```

## Technical Requirements

- `ffmpeg` installed and available in PATH
  - macOS: `brew install ffmpeg`
  - Windows: `winget install ffmpeg`
  - Linux: `apt install ffmpeg`
- Video file in working directory
- Transcript file in working directory

## Helper Script

A bash helper `scripts/cut_clip.sh` is included for processing a single `Clip N` block when working manually. See `SOP.md` for usage.

For typical use through Claude, no scripts are needed — Claude reads the transcript and runs the ffmpeg commands directly.
