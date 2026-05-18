#!/usr/bin/env bash
# cut_clip.sh — cut multiple fragments from a video and concatenate them into ONE final clip.
#
# Usage:
#   bash cut_clip.sh <input_video> <output_name> <frag1_start> <frag1_end> [<frag2_start> <frag2_end> ...]
#
# Example (Clip 1 with 3 fragments):
#   bash cut_clip.sh video.mov "Clip_1_AllOrNothing" \
#     00:00:54 00:01:06 \
#     00:03:32 00:03:35 \
#     00:03:05 00:03:19
#
# Behavior:
#   - Cuts each fragment with re-encode (libx264 crf 23, aac 128k, 48kHz audio)
#   - Adds 5s buffer BEFORE the first fragment's start
#   - Adds 1s buffer AFTER the last fragment's end
#   - Inner fragments are cut precisely at their timecodes (no buffer)
#   - Concatenates fragments in the order given
#   - Saves to ./clips/<output_name>.mp4
#   - Cleans up temp files

set -euo pipefail

if [ "$#" -lt 4 ]; then
  echo "Usage: $0 <input_video> <output_name> <frag1_start> <frag1_end> [<frag2_start> <frag2_end> ...]"
  echo ""
  echo "Example:"
  echo "  $0 video.mov Clip_1_Test 00:00:54 00:01:06 00:03:32 00:03:35"
  echo ""
  echo "Each fragment is two timecodes: start and end."
  echo "At least one fragment (2 arguments) required."
  exit 1
fi

INPUT="$1"
OUTPUT_NAME="$2"
shift 2

# Remaining arguments must come in pairs
if [ $(( $# % 2 )) -ne 0 ]; then
  echo "Error: fragments must come in pairs (start end). Got odd number of timecodes."
  exit 1
fi

if [ ! -f "$INPUT" ]; then
  echo "Error: input video '$INPUT' not found."
  exit 1
fi

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "Error: ffmpeg is not installed."
  echo "  macOS:   brew install ffmpeg"
  echo "  Windows: winget install ffmpeg"
  echo "  Linux:   apt install ffmpeg"
  exit 1
fi

mkdir -p clips temp

# ---------- helper functions ----------
to_seconds() {
  local tc="$1"
  awk -F: '{
    n = NF
    if (n == 3)      print $1*3600 + $2*60 + $3
    else if (n == 2) print $1*60   + $2
    else             print $1
  }' <<< "$tc"
}

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

# ---------- collect fragments ----------
FRAG_STARTS=()
FRAG_ENDS=()
while [ "$#" -gt 0 ]; do
  FRAG_STARTS+=("$1")
  FRAG_ENDS+=("$2")
  shift 2
done

NUM_FRAGS=${#FRAG_STARTS[@]}
LAST_INDEX=$((NUM_FRAGS - 1))

echo ""
echo "================================================================"
echo "Processing: $OUTPUT_NAME"
echo "Input:      $INPUT"
echo "Fragments:  $NUM_FRAGS"
echo "================================================================"

# ---------- cut each fragment ----------
CONCAT_LIST="temp/${OUTPUT_NAME}_concat.txt"
> "$CONCAT_LIST"

for i in $(seq 0 $LAST_INDEX); do
  START="${FRAG_STARTS[$i]}"
  END="${FRAG_ENDS[$i]}"

  START_S=$(to_seconds "$START")
  END_S=$(to_seconds "$END")

  if (( $(echo "$END_S <= $START_S" | bc -l) )); then
    echo "  Skipping fragment $((i+1)): end ($END) <= start ($START)"
    continue
  fi

  # Apply buffers only to outer edges
  ADJ_START_S=$START_S
  ADJ_END_S=$END_S

  if [ "$i" -eq 0 ]; then
    ADJ_START_S=$(awk -v s="$START_S" 'BEGIN { v = s - 5; if (v < 0) v = 0; print v }')
  fi
  if [ "$i" -eq "$LAST_INDEX" ]; then
    ADJ_END_S=$(awk -v s="$END_S" 'BEGIN { print s + 1 }')
  fi

  ADJ_START_TC=$(to_timecode "$ADJ_START_S")
  ADJ_END_TC=$(to_timecode "$ADJ_END_S")

  FRAG_FILE="temp/${OUTPUT_NAME}_frag_$((i+1)).mp4"

  echo ""
  echo "Fragment $((i+1))/$NUM_FRAGS"
  echo "  Original:  $START → $END"
  echo "  With buf:  $ADJ_START_TC → $ADJ_END_TC"
  echo "  Output:    $FRAG_FILE"

  ffmpeg -y -hide_banner -loglevel error \
    -ss "$ADJ_START_TC" -to "$ADJ_END_TC" \
    -i "$INPUT" \
    -c:v libx264 -preset medium -crf 23 \
    -c:a aac -b:a 128k -ar 48000 \
    "$FRAG_FILE"

  echo "file '$FRAG_FILE'" >> "$CONCAT_LIST"
done

# ---------- concatenate ----------
OUTPUT="clips/${OUTPUT_NAME}.mp4"
echo ""
echo "Concatenating $NUM_FRAGS fragments into $OUTPUT..."

ffmpeg -y -hide_banner -loglevel error \
  -f concat -safe 0 \
  -i "$CONCAT_LIST" \
  -c copy \
  "$OUTPUT"

# ---------- cleanup ----------
for i in $(seq 1 $NUM_FRAGS); do
  rm -f "temp/${OUTPUT_NAME}_frag_${i}.mp4"
done
rm -f "$CONCAT_LIST"

# Try to remove temp if empty
rmdir temp 2>/dev/null || true

echo ""
echo "================================================================"
echo "✓ Done: $OUTPUT"
echo "================================================================"
