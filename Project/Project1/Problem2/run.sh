#!/usr/bin/env bash
# Run the binary multiple times and aggregate CSV results in perf_results.csv.
# REPS can be overridden: `REPS=5 ./run.sh`
set -euo pipefail

: "${REPS:=3}"

# Remove old results
rm -f perf_results.csv

for i in $(seq 1 "$REPS"); do
  echo "Run $i/$REPS…"
  ./sqrt_compare
done

# Check for CSV lines in the results
if ! grep -q '^serial,' perf_results.csv; then
  echo "No CSV lines captured. Try: ./sqrt_compare | grep '^CSV '"
else
  echo "perf_results.csv updated:"
  tail -n 10 perf_results.csv
fi
