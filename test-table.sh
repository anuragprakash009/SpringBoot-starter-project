#!/bin/bash

CSV_FILE=$1
[ -z "$CSV_FILE" ] && { echo "Usage: $0 <csv_file>"; exit 1; }

# Table width in characters (adjust as needed)
TOTAL_WIDTH=140

# Column weights (13 columns)
COL_WEIGHTS=(5 18 12 10 10 8 8 8 8 10 10 8 8)
NUM_COLS=${#COL_WEIGHTS[@]}

# --- FIX 1: Calculate actual text width ---
# We subtract 3 chars for each column ("| " + " ") and 1 for the final "|"
PADDING_CHARS=$(( (3 * NUM_COLS) + 1 ))
TEXT_WIDTH=$((TOTAL_WIDTH - PADDING_CHARS))
[ $TEXT_WIDTH -le 0 ] && { echo "Error: TOTAL_WIDTH ($TOTAL_WIDTH) is too small for $NUM_COLS columns."; exit 1; }

# Compute column widths
COL_WIDTH=()
TOTAL_WEIGHT=0
CALCULATED_WIDTH=0
for w in "${COL_WEIGHTS[@]}"; do TOTAL_WEIGHT=$((TOTAL_WEIGHT + w)); done

# Calculate widths and track remainder
for w in "${COL_WEIGHTS[@]}"; do
    width=$(( w * TEXT_WIDTH / TOTAL_WEIGHT ))
    COL_WIDTH+=($width)
    CALCULATED_WIDTH=$((CALCULATED_WIDTH + width))
done

# Distribute rounding remainder to make width exact
REMAINDER=$((TEXT_WIDTH - CALCULATED_WIDTH))
for ((i=0; REMAINDER > 0; i++)); do
    idx=$((i % NUM_COLS))
    COL_WIDTH[idx]=$((COL_WIDTH[idx] + 1))
    REMAINDER=$((REMAINDER - 1))
done
# --- End of Width Fix ---

# Function to wrap text to width
wrap_field() {
    local text="$1"
    local width="$2"
    # Wrap text, handling potential empty input
    echo "$text" | fold -s -w "$width"
    [ -z "$text" ] && echo "" # Ensure fold outputs if input is empty
}

# Read header and wrap it
# --- FIX 2: Added sed to remove \r ---
header=$(head -n 1 "$CSV_FILE" | sed 's/\r$//')
header=$(echo "$header" | sed 's/ /_/g')
IFS=',' read -r -a HEADERS <<< "$header"

WRAPPED_HEADERS=()
MAX_HEADER_LINES=1
for i in "${!HEADERS[@]}"; do
    WRAPPED=$(wrap_field "${HEADERS[i]}" "${COL_WIDTH[i]}")
    WRAPPED_HEADERS[i]="$WRAPPED"
    LINES=$(echo "$WRAPPED" | wc -l)
    ((LINES > MAX_HEADER_LINES)) && MAX_HEADER_LINES=$LINES
done

# Print wrapped header line by line
for ((line=1; line<=MAX_HEADER_LINES; line++)); do
    for i in "${!WRAPPED_HEADERS[@]}"; do
        VAL=$(echo "${WRAPPED_HEADERS[i]}" | sed -n "${line}p")
        [ -z "$VAL" ] && VAL=""
        # This printf is correct
        printf "| %-${COL_WIDTH[i]}s " "$VAL"
    done
    echo "|"
done

# Print header separator
sep=""
# Adjust separator width to match COL_WIDTH + 2 spaces
for w in "${COL_WIDTH[@]}"; do sep="$sep|$(printf '%0.s-' $(seq 1 $((w + 2))))"; done
# Remove first char and add final |
sep="-${sep:1}|"
echo "$sep"


# Process rows
# --- FIX 2: Added sed to remove \r from all data lines ---
tail -n +2 "$CSV_FILE" | sed 's/\r$//' | while IFS=',' read -r -a ROW
do
    # Pad row array if CSV line is short
    for ((i=${#ROW[@]}; i<NUM_COLS; i++)); do ROW[i]=""; done

    WRAPPED=()
    MAX_LINES=1
    for i in "${!ROW[@]}"; do
        # Handle index out of bounds if row is too long
        [ $i -ge $NUM_COLS ] && break
        
        WRAPPED_COL=$(wrap_field "${ROW[i]}" "${COL_WIDTH[i]}")
        WRAPPED[i]="$WRAPPED_COL"
        LINES=$(echo "$WRAPPED_COL" | wc -l)
        ((LINES > MAX_LINES)) && MAX_LINES=$LINES
    done

    # Print row line by line
    for ((line=1; line<=MAX_LINES; line++)); do
        for i in "${!ROW[@]}"; do
            [ $i -ge $NUM_COLS ] && break
            
            VAL=$(echo "${WRAPPED[i]}" | sed -n "${line}p")
            [ -z "$VAL" ] && VAL=""
            printf "| %-${COL_WIDTH[i]}s " "$VAL"
        done
        echo "|"
    done
done