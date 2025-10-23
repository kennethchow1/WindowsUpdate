#!/bin/bash
# lookup_model_order.sh
# Detect CPU & GPU on macOS, download CSV, and find Apple model_order.

# === CONFIG ===
CSV_URL="https://raw.githubusercontent.com/yourusername/mac-models/main/models.csv"
CSV_FILE="/tmp/models.csv"

# === Download or update CSV ===
echo "⬇️ Fetching latest model database..."
if ! curl -fsSL "$CSV_URL" -o "$CSV_FILE"; then
  echo "❌ Failed to download CSV from $CSV_URL"
  exit 1
fi

# === Normalize GPU function ===
normalize_gpu() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/ graphics?$//; s/ chipset model//; s/ +/ /g' | xargs
}

# === Get CPU info ===
CPU_FULL=$(sysctl -n machdep.cpu.brand_string 2>/dev/null)
if [ -z "$CPU_FULL" ]; then
  CPU_FULL=$(system_profiler SPHardwareDataType | grep "Chip" | awk -F": " '{print $2}')
fi

# Extract CPU code like I7-9750H, uppercase to match CSV
CPU_CODE=$(echo "$CPU_FULL" | grep -Eo '[iI][3579]-[0-9A-Z]+' | head -n 1 | tr '[:lower:]' '[:upper:]')

# Fallback for Apple Silicon M1, M2, etc.
if [ -z "$CPU_CODE" ]; then
  CPU_CODE=$(echo "$CPU_FULL" | grep -Eo 'M[0-9]+( Pro| Max| Ultra)?' | head -n 1 | xargs)
fi

CPU_CODE=$(echo "$CPU_CODE" | xargs)

# === Get GPU info ===
GPU_LIST=$(system_profiler SPDisplaysDataType | grep "Chipset Model" | awk -F": " '{print $2}' | sed 's/^ *//;s/ *$//')
GPU_MODEL=""

# Prefer AMD GPU if present
while IFS= read -r gpu; do
  if echo "$gpu" | grep -qi "AMD"; then
    GPU_MODEL="$gpu"
    break
  fi
done <<< "$GPU_LIST"

# Fallback to first GPU if no AMD
if [ -z "$GPU_MODEL" ]; then
  GPU_MODEL=$(echo "$GPU_LIST" | head -n 1)
fi

GPU_MODEL=$(echo "$GPU_MODEL" | xargs)


# === Output detected info ===
echo "🧠 CPU detected: $CPU_FULL"
echo "🔍 CPU code extracted: $CPU_CODE"
echo "🎨 GPU detected: $GPU_MODEL"
echo "🔎 Searching model_order in remote CSV database..."

# === Lookup in CSV with improved CPU matching ===
MATCH=$(awk -F, -v cpu="$CPU_CODE" -v gpu="$GPU_MODEL" '
BEGIN {IGNORECASE=1}
NR>1 {
  gsub(/"/, "", $0)
  split($0, fields, ",")

  cpu_field = fields[4]
  gpu_field = fields[5]

  # Extract CPU model code inside parentheses, e.g. I7-9750H
  match(cpu_field, /\(([A-Z0-9\-]+)\)/, arr)
  cpu_in_csv = arr[1]

  # Normalize GPU column similar to input
  gpu_col_norm = gpu_field
  gsub(/graphics?$/,"", gpu_col_norm)
  gsub(/chipset model$/,"", gpu_col_norm)
  gsub(/ +/, " ", gpu_col_norm)

  cpu_in_csv_lc = tolower(cpu_in_csv)
  cpu_lc = tolower(cpu)
  gpu_col_lc = tolower(gpu_col_norm)
  gpu_lc = tolower(gpu)

  cpu_match = (cpu_in_csv_lc == cpu_lc)
  gpu_match = (index(gpu_col_lc, gpu_lc) > 0) || (index(gpu_lc, gpu_col_lc) > 0)

  if (cpu_match && gpu_match) {
    print "✅ Model Order: " fields[2]
    print "💻 Model ID: " fields[1]
    print "📅 Year: " fields[6]
    exit
  }
}' "$CSV_FILE")

# === Show results ===
if [ -n "$MATCH" ]; then
  echo "$MATCH"
else
  echo "❌ No matching entry found for CPU: '$CPU_CODE' and GPU: '$GPU_MODEL'"
fi
