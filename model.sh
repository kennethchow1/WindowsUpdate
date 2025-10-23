#!/bin/bash
# lookup_model_order.sh
# Detect CPU + GPU info, download a CSV from GitHub, and find Apple model_order.

# === CONFIG ===
CSV_URL="https://getupdates.me/key.csv"
CSV_FILE="/tmp/models.csv"   # Temporary local copy

# === DOWNLOAD OR UPDATE CSV ===
echo "⬇️  Fetching latest model database..."
if ! curl -fsSL "$CSV_URL" -o "$CSV_FILE"; then
  echo "❌ Failed to download CSV from $CSV_URL"
  exit 1
fi

# === GET CPU INFO ===
CPU_MODEL=$(sysctl -n machdep.cpu.brand_string 2>/dev/null)
if [ -z "$CPU_MODEL" ]; then
  CPU_MODEL=$(system_profiler SPHardwareDataType | grep "Chip" | awk -F": " '{print $2}')
fi

# === GET GPU INFO ===
GPU_MODEL=$(system_profiler SPDisplaysDataType | grep "Chipset Model" | awk -F": " '{print $2}' | head -n 1)

# === CLEAN + NORMALIZE ===
CPU_MODEL=$(echo "$CPU_MODEL" | sed 's/(R)//g' | sed 's/CPU @.*//g' | xargs)
GPU_MODEL=$(echo "$GPU_MODEL" | xargs)

echo "🧠 CPU detected: $CPU_MODEL"
echo "🎨 GPU detected: $GPU_MODEL"
echo "🔎 Searching in remote CSV database..."

# === LOOKUP IN CSV ===
MATCH=$(awk -F, -v cpu="$CPU_MODEL" -v gpu="$GPU_MODEL" '
BEGIN {IGNORECASE=1}
NR>1 {
  gsub(/"/, "", $0);
  if (index(cpu, $4) && index(gpu, $5)) {
    print "✅ Model Order: " $2 "\n💻 Model ID: " $1 "\n📅 Year: " $6;
    exit
  }
}' "$CSV_FILE")

# === RESULT ===
if [ -n "$MATCH" ]; then
  echo "$MATCH"
else
  echo "❌ No matching entry found in $CSV_URL"
fi
