---
name: clipping
description: Cuts long-form videos into individual short clips based on a transcript with timecodes. Each transcript segment becomes one re-encoded clip with safety buffers (5s before / 1s after). Use when the user provides a video file plus a transcript and asks for clips, cuts, or segments — no hook merging, no A/B variants, no concatenation.
---

# Clipping Skill

Pipeline for cutting long-form videos into individual short clips.

Each segment from the transcript becomes **one separate clip**. No hook merging, no A/B variants, no concatenation — just precise, clean cuts.

## How It Works

1. User provides:
   - A video file (`.mov`, `.mp4`)
   - A transcript with timecodes marking each segment
2. For every segment in the transcript → produce **one clip**
3. Apply safety buffers and re-encode for precise cuts
4. Save to `clips/` folder

## Technical Requirements

- **ffmpeg** installed (`brew install ffmpeg` on macOS, `apt install ffmpeg` on Linux)
- Video file in working directory
- Transcript with start/end timecodes per segment

## Cutting Rules

### Timecode Buffers (ALWAYS apply)
- **5 seconds BEFORE** each segment start
- **1 second AFTER** each segment end

These buffers protect against missed first words and abrupt endings.

### Re-encode, Don't Copy

Always use re-encoding instead of `-c copy`:

```bash
# CORRECT — re-encode for precise cuts
ffmpeg -ss 00:01:05 -to 00:02:30 -i input.mov \
  -c:v libx264 -preset medium -crf 23 \
  -c:a aac -b:a 128k \
  output.mp4

# WRONG — cuts at keyframes, eats first words, desyncs audio
ffmpeg -ss 00:01:10 -to 00:02:30 -i input.mov -c copy output.mp4
```

### Why Re-encode?
- `-c copy` cuts only at keyframes (every 2–5 seconds)
- This causes the first words to be eaten
- Audio goes out of sync
- Re-encoding with buffer solves both issues

## Workflow

1. Receive video file + transcript with timecodes
2. Parse each segment (start time, end time, topic name)
3. Apply 5s/1s buffer to each segment
4. Cut and re-encode each segment as a standalone clip
5. Save to `clips/` folder with descriptive names

## Output Naming

```
Clip_1_TopicName.mp4
Clip_2_TopicName.mp4
Clip_3_TopicName.mp4
...
```

Numbering starts at 1 and follows the order of segments in the transcript.

## Folder Structure

```
clipping/
├── SKILL.md
├── SOP.md           # Step-by-step instructions for users (Ukrainian)
├── scripts/
│   └── cut_clip.sh  # Helper script for a single clip
├── clips/           # Output clips go here (created at runtime)
└── temp/            # Temporary files (optional, created at runtime)
```

## Important Notes

- Timecodes in transcripts are approximate — trust the spoken text more than exact timestamps
- Always verify the cut includes the first word of each segment
- If first words are missing, add more buffer before
- If audio sync issues appear after a cut, re-encoding (which is already enforced) fixes them
- Never use `-c copy` — even if the user asks for it, explain why and re-encode anyway
