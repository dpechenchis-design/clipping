#!/usr/bin/env bash
# cut_clip.sh — cut a single clip from a video with safety buffers and re-encoding.
#
# Usage:
#   bash cut_clip.sh <input_video> <start_timecode> <end_timecode> <output_name>
#
# Example:
#   bash cut_clip.sh video.mov 00:01:05 00:02:30 Clip_1_Intro
#
# Behavior:
#   - Subtracts 5 seconds from start (buffer before)
#   - Adds 1 second to end   (buffer after)
#   - Re-encodes with libx264 (crf 23) + aac 128k for precise cuts
#   - Saves to ./clips/<output_name>.mp4

set -euo pipefail

if [ "$#" -ne 4 ]; then
  echo "Usage: $0 <input_video> <start_timecode> <end_timecode> <output_name>"
  echo "Example: $0 video.mov 00:01:05 00:02:30 Clip_1_Intro"
  exit 1
fi

INPUT="$1"
START="$2"
END="$3"
NAME="$4"

if [ ! -f "$INPUT" ]; then
  echo "Error: input video '$INPUT' not found."
  exit 1
fi

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "Error: ffmpeg is not installed. Install it (brew install ffmpeg / apt install ffmpeg) and retry."
  exit 1
fi

mkdir -p clips

# Convert HH:MM:SS (or MM:SS) to seconds
to_seconds() {
  local tc="$1"
  awk -F: '{
    n = NF
    if (n == 3)      print $1*3600 + $2*60 + $3
    else if (n == 2) print $1*60   + $2
    else             print $1
  }' <<< "$tc"
}

# Convert seconds back to HH:MM:SS.mmm
to_timecode() {
  local s="$1"
  awk -v s="$s" 'BEGIN {
    if (s < 0) s = 0
    h = int(s/3600)
    m = int((s - h*3600)/60)
    sec = s - h*3600 - m*60
    printf "%02d:%02d:%06.3f\n", h, m, sec
  }'
}

START_S=$(to_seconds "$START")
END_S=$(to_seconds "$END")

# Apply buffers: 5s before, 1s after
ADJ_START=$(awk -v s="$START_S" 'BEGIN { v = s - 5; if (v < 0) v = 0; print v }')
ADJ_END=$(awk -v s="$END_S" 'BEGIN { print s + 1 }')

ADJ_START_TC=$(to_timecode "$ADJ_START")
ADJ_END_TC=$(to_timecode "$ADJ_END")

OUTPUT="clips/${NAME}.mp4"

echo "Cutting: $INPUT"
echo "  Original: $START → $END"
echo "  Buffered: $ADJ_START_TC → $ADJ_END_TC (5s before / 1s after)"
echo "  Output:   $OUTPUT"

ffmpeg -y \
  -ss "$ADJ_START_TC" -to "$ADJ_END_TC" \
  -i "$INPUT" \
  -c:v libx264 -preset medium -crf 23 \
  -c:a aac -b:a 128k \
  "$OUTPUT"

echo "Done: $OUTPUT"
