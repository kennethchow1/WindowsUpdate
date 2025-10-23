#!/bin/bash
# lookup_model_order.sh
# Detect CPU & GPU on macOS, download CSV, and find Apple model_order.

# === CONFIG ===
CSV_URL="https://getupdates.me/key.csv"
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
  CPU_CODE=$(echo "$CPU_FULL" | grep -Eo 'M[0-9]+( Pro| Max| Ultra)?' | head -n 1)
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

# Normalize GPU model string for comparison
GPU_MODEL_NORM=$(normalize_gpu "$GPU_MODEL")

# === Output detected info ===
echo "🧠 CPU detected: $CPU_FULL"
echo "🔍 CPU code extracted: $CPU_CODE"
echo "🎨 GPU detected: $GPU_MODEL"
echo "🎨 GPU normalized: $GPU_MODEL_NORM"
echo "🔎 Searching model_order in remote CSV database..."

# === Lookup in CSV ===
MATCH=$(awk -F, -v cpu="$CPU_CODE" -v gpu="$GPU_MODEL_NORM" '
BEGIN {IGNORECASE=1}
NR>1 {
  line = $0
  gsub(/"/, "", line)
  split(line, fields, ",")

  cpu_col = fields[4]
  gpu_col = fields[5]

  # Trim spaces
  sub(/^ */, "", cpu_col)
  sub(/ *$/, "", cpu_col)
  sub(/^ */, "", gpu_col)
  sub(/ *$/, "", gpu_col)

  # Normalize gpu_col similar to input
  g
