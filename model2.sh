#!/bin/bash
# lookup_model_order.sh
# Detect CPU + GPU info on macOS, download a CSV from GitHub, and find Apple model_order.

# === CONFIG ===
CSV_URL="https://getupdates.me/key.csv"
CSV_FILE="/tmp/models.csv"

# === DOWNLOAD OR UPDATE CSV ===
echo "⬇️  Fetching latest model database..."
if ! curl -fsSL "$CSV_URL" -o "$CSV_FILE"; then
  echo "❌ Failed to download CSV from $CSV_URL"
  exit 1
fi

# === GET CPU INFO ===
CPU_FULL=$(sysctl -n machdep.cpu.brand_string 2>/dev/null)
if [ -z "$CPU_FULL" ]; then
  CPU_FULL=$(system_profiler SPHardwareDataType | grep "Chip" | awk -F": " '{print $2}')
fi

# Extract model code from CPU string (e.g. i7-9750H)
CPU_CODE=$(echo "$CPU_FULL" | grep -Eo '[iI][3579]-[0-9A-Z]+' | head -n 1 | tr '[:lower:]' '[:upper:]')


# Fallback for Apple Silicon (M1, M2, M3, etc.)
if [ -z "$CPU_CODE" ]; then
  CPU_CODE=$(echo "$CPU_FULL" | grep -Eo 'M[0-9]+( Pro| Max| Ultra)?' | head -n 1)
fi

CPU_CODE=$(echo "$CPU_CODE" | xargs)

# === GET GPU INFO ===
GPU_LIST=$(system_profiler SPDisplaysDataType | grep "Chipset Model" | awk -F": " '{print $2}' | sed 's/^ *//;s/ *$//')
GPU_MODEL=""

# Prefer AMD if present
while IFS= read -r gpu; do
  if echo "$gpu" | grep -qi "AMD"; then
    GPU_MODEL="$gpu"
    break
  fi
done <<< "$GPU_LIST"

# Fallback to first GPU
if [ -z "$GPU_MODEL" ]; then
  GPU_MODEL=$(echo "$GPU_LIST" | head -n 1)
fi

GPU_MODEL=$(echo "$GPU_MODEL" | xargs)

# === OUTPUT DETECTED HARDWARE ===
echo "🧠 CPU detected: $CPU_FULL"
echo "🔍 CPU code extracted: $CPU_CODE"
echo "🎨 GPU detected: $GPU_MODEL"
echo "🔎 Searching in remote CSV database..."

# === LOOKUP IN CSV ===
MATCH=$(awk -F, -v cpu="$CPU_CODE" -v gpu="$GPU_MODEL" '
BEGIN {IGNORECASE=1}
NR>1 {
  gsub(/"/, "", $0);
  if (index($4, cpu) && index(gpu, $5)) {
    print "✅ Model Order: " $2 "\n💻 Model ID: " $1 "\n📅 Year: " $6;
    exit
  }
}' "$CSV_FILE")

# === RESULT ===
if [ -n "$MATCH" ]; then
  echo "$MATCH"
else
  echo "❌ No matching entry found for CPU: '$CPU_CODE' and GPU: '$GPU_MODEL'"
fi
