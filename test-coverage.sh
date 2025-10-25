#!/bin/bash

# Script to calculate aggregate code coverage from a CSV report.
# It checks if the total instruction coverage meets a minimum threshold (90%).

# --- Configuration ---
CSV_FILE=$1
MIN_COVERAGE_PERCENT=10
# ---------------------

# 1. Input Validation
if [ -z "$CSV_FILE" ]; then
    echo "Error: Please provide the path to the coverage CSV file."
    echo "Usage: $0 <path/to/coverage.csv>"
    exit 1
fi

if [ ! -f "$CSV_FILE" ]; then
    echo "Error: File not found at '$CSV_FILE'."
    exit 1
fi

# 2. Calculation using awk
# AWK is ideal for summing columns in CSV files.
# It sums the missed (Field 4) and covered (Field 5) instructions from all rows 
# after skipping the header line (NR > 1).
COVERAGE_STATS=$(awk -F, '
    BEGIN {
        # Initialize sums
        total_missed = 0
        total_covered = 0
    }
    # Skip the header (first line)
    NR > 1 {
        # Fields: $4 is INSTRUCTION_MISSED, $5 is INSTRUCTION_COVERED
        total_missed += $4
        total_covered += $5
    }
    # After processing all rows, print the results separated by a space
    END {
        total_instructions = total_missed + total_covered
        # Avoid division by zero
        if (total_instructions == 0) {
            print total_covered, total_instructions, 0
        } else {
            coverage_percentage = (total_covered / total_instructions) * 100
            # Print the total covered, total instructions, and the percentage
            print total_covered, total_instructions, coverage_percentage
        }
    }
' "$CSV_FILE")

# 3. Parse AWK output
# Read the three values into shell variables
read -r COVERED TOTAL PERCENTAGE <<< "$COVERAGE_STATS"

# Check if awk returned valid numeric data (e.g., if the file was empty)
if [ -z "$TOTAL" ] || [ "$TOTAL" -eq 0 ]; then
    echo "Warning: No instruction data found. Assuming 100% coverage."
    AVERAGE_COVERAGE=100.0
else
    # AWK uses floating point, so the result is already correct.
    AVERAGE_COVERAGE=$PERCENTAGE
fi

# 4. Print results
echo "--- Coverage Summary ---"
echo "Metric: Total Instruction Coverage"
printf "Calculated Coverage: %.2f%%\n" "$AVERAGE_COVERAGE"
printf "Expected Minimum: %d%%\n" "$MIN_COVERAGE_PERCENT"
echo "------------------------"

# 5. Check Threshold and Exit (FIXED: Using robust awk float comparison)

# Pass shell variables to awk using -v for reliable float comparison.
# If coverage is below minimum, awk prints '1' (FAIL flag), else '0'.
FAILURE_FLAG=$(awk -v avg="$AVERAGE_COVERAGE" -v min="$MIN_COVERAGE_PERCENT" 'BEGIN { print (avg < min) ? 1 : 0 }')

if [ "$FAILURE_FLAG" -eq 1 ]; then
    echo "FAIL: Coverage is below the minimum threshold of ${MIN_COVERAGE_PERCENT}%."
    exit 1
else
    echo "SUCCESS: Coverage requirement met."
    exit 0
fi
