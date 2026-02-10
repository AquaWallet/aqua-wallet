#!/usr/bin/env bash
set -euo pipefail

ARB_FILE="lib/l10n/app_en.arb"
OUTPUT_FILE="unused_localizations.txt"

echo "Scanning for unused localization keys..."

# Extract keys with Perl (ignore @@locale and keys starting with @)
keys=()
while IFS= read -r key; do
  keys+=("$key")
done < <(
  perl -nle 'print $1 if /^\s*"([^"]+)":/ && $1 !~ /^@/' "$ARB_FILE"
)

unused=()

# Search in all Dart files
for key in "${keys[@]}"; do
  if ! grep -R --include="*.dart" -Fq "loc.$key" lib/; then
    unused+=("$key")
  fi
done

# Print unused elements
if [ ${#unused[@]} -gt 0 ]; then
  echo "Found ${#unused[@]} unused localization keys:"
else
  echo "No unused localization keys found!"
fi

# Write results into metadata file
{
  echo "==== Unused localization keys ===="
  for k in "${unused[@]}"; do
    echo "$k"
  done
} > "$OUTPUT_FILE"

echo "✅ Scan complete. Results saved to $OUTPUT_FILE"
