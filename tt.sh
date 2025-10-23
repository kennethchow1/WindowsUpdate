#!/bin/sh
# Apple MacBook SKU Generator (Online CSV)
# Fully self-contained version
# Melody's SKU Tool

CSV_URL="https://example.com/Apple SKU Key - Key.csv"

# Fetch CSV from URL dynamically
fetch_csv() {
  if command -v curl >/dev/null 2>&1; then
    curl -sL "$CSV_URL"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO- "$CSV_URL"
  else
    echo "❌ curl or wget not available!" >&2
    exit 1
  fi
}

trim() { printf "%s" "$1" | awk '{$1=$1; print}'; }

# === CODE MAPPINGS ===
ram_code() {
  case "$1" in
    8) echo "3" ;;
    16) echo "4" ;;
    32) echo "6" ;;
    36) echo "A" ;;
    40) echo "D" ;;
    48) echo "B" ;;
    64) echo "7" ;;
    *) echo "?" ;;
  esac
}

ssd_code() {
  case "$1" in
    10) echo "D" ;;
    128) echo "4" ;;
    256) echo "5" ;;
    512) echo "6" ;;
    1024) echo "8" ;;
    2048) echo "A" ;;
    4096) echo "B" ;;
    *) echo "?" ;;
  esac
}

color_code() {
  uc=$(printf "%s" "$1" | tr '[:lower:]' '[:upper:]')
  case "$uc" in
    "GRAY"|"SPACE GRAY") echo "G" ;;
    "SILVER") echo "S" ;;
    "ROSE GOLD") echo "R" ;;
    "GOLD") echo "D" ;;
    "BLUE"|"MIDNIGHT BLUE") echo "M" ;;
    "BLACK"|"SPACE BLACK") echo "B" ;;
    *) echo "?" ;;
  esac
}

cond_code() {
  case "$1" in
    A|a) echo "A" ;;
    B|b) echo "B" ;;
    C|c) echo "C" ;;
    D|d) echo "D" ;;
    *) echo "?" ;;
  esac
}

# === PRINT BOXED SKU REPORT ===
print_boxed() {
  FULLSKU="$1"; MODEL_ORDER="$2"; MODEL="$3"; MODEL_BASIC="$4"; MODEL_EMC="$5"
  BASESKU="$6"; YEAR="$7"; CPU="$8"; GPU="$9"; BATTERY="${10}"; CHARGER="${11}"
  RAMCODE="${12}"; RAMVAL="${13}"; SSDCODE="${14}"; SSDVAL="${15}"
  CONDCODE="${16}"; CONDVAL="${17}"; COLORCODE="${18}"; COLORVAL="${19}"

  echo "╔$(printf '═%.0s' $(seq 1 70))╗"
  printf "║ %-68s ║\n" "GENERATED SKU REPORT"
  echo "╠$(printf '═%.0s' $(seq 1 70))╣"
  printf "║ %-15s: %-48.48s ║\n" "FULL SKU" "$FULLSKU"
  printf "║ %-15s: %-48.48s ║\n" "MODEL ORDER" "$MODEL_ORDER"
  printf "║ %-15s: %-48.48s ║\n" "MODEL" "$MODEL"
  printf "║ %-15s: %-48.48s ║\n" "MODEL BASIC" "$MODEL_BASIC"
  printf "║ %-15s: %-48.48s ║\n" "MODEL EMC" "$MODEL_EMC"
  printf "║ %-15s: %-48.48s ║\n" "BASE SKU" "$BASESKU"
  printf "║ %-15s: %-48.48s ║\n" "YEAR" "$YEAR"
  printf "║ %-15s: %-48.48s ║\n" "CPU" "$CPU"
  printf "║ %-15s: %-48.48s ║\n" "GPU" "$GPU"
  printf "║ %-15s: %-48.48s ║\n" "Battery Code" "$BATTERY"
  printf "║ %-15s: %-48.48s ║\n" "Charger" "$CHARGER"
  echo "╟$(printf '─%.0s' $(seq 1 70))╢"
  printf "║ %-15s: %-48.48s ║\n" "RAM Code" "${RAMCODE} (${RAMVAL} GB)"
  printf "║ %-15s: %-48.48s ║\n" "SSD Code" "${SSDCODE} (${SSDVAL} GB)"
  printf "║ %-15s: %-48.48s ║\n" "Condition" "${CONDCODE} (${CONDVAL})"
  printf "║ %-15s: %-48.48s ║\n" "Color Code" "${COLORCODE} (${COLORVAL})"
  echo "╚$(printf '═%.0s' $(seq 1 70))╝"
}

# === VIEW MODELS ===
view_models() {
  echo ""
  echo "=== AVAILABLE MODELS ==="
  fetch_csv | awk -F, 'NR>1 {printf "%-8s — %-18s — %s\n", $9, $1, $6}' | sort -u
}

# === VIEW CONFIG OPTIONS ===
view_config_options() {
  echo ""
  echo "=== CONFIGURATION OPTIONS ==="
  echo "RAM: 8 → 3, 16 → 4, 32 → 6, 36 → A, 40 → D, 48 → B, 64 → 7"
  echo "SSD: 128 → 4, 256 → 5, 512 → 6, 1024 → 8, 2048 → A, 4096 → B"
  echo "Condition: A → Excellent, B → Good, C → Fair, D → Poor"
  echo "Colors: Gray → G, Silver → S, Rose Gold → R, Gold → D, Blue → M, Black → B"
}

# === LOOKUP BY BASE SKU ===
lookup_by_base() {
  printf "Enter Base SKU: "
  read bsku
  bsku=$(trim "$bsku")
  [ -z "$bsku" ] && { echo "Base SKU required."; return; }
  echo ""
  echo "Matches for Base SKU $bsku:"
  fetch_csv | awk -F, -v bsku="$bsku" 'NR>1 && $3==bsku {
    printf "%-18s — %-6s — %-25s — %s — Battery: %s\n", $1, $9, $4, $6, $12
  }'
}

# === LOOKUP BY EMC ===
lookup_by_emc() {
  printf "Enter EMC Number: "
  read emc
  emc=$(trim "$emc")
  [ -z "$emc" ] && { echo "EMC required."; return; }
  echo ""
  echo "Matches for EMC $emc:"
  fetch_csv | awk -F, -v emc="$emc" 'NR>1 && $10==emc {
    printf "%-18s — %-6s — %-25s — %s — Battery: %s — Base SKU: %s\n", $1, $9, $4, $6, $12, $3
  }'
}

# === FIND MODEL ORDER ===
find_model_order() {
  printf "Enter Model Name: "
  read model
  model=$(trim "$model")
  [ -z "$model" ] && { echo "Model required."; return; }
  fetch_csv | awk -F, -v model="$model" 'NR>1 && $1==model {print $9, $3}'
}

# === GENERATE SKU ===
generate_sku() {
  printf "Enter Model Name: "
  read model
  model=$(trim "$model")
  info=$(fetch_csv | awk -F, -v model="$model" 'NR>1 && $1==model {print $1","$2","$3","$4","$5","$6","$9","$10","$11","$12}')
  [ -z "$info" ] && { echo "Model not found."; return; }

  # Split CSV info into variables
  IFS=',' read MODEL MODEL_BASIC BASESKU YEAR CPU GPU BATTERY CHARGER MODEL_ORDER <<< "$info"

  printf "Enter RAM (GB): "
  read RAMVAL
  printf "Enter SSD (GB): "
  read SSDVAL
  printf "Enter Condition (A-D): "
  read CONDVAL
  printf "Enter Color: "
  read COLORVAL

  RAMCODE=$(ram_code "$RAMVAL")
  SSDCODE=$(ssd_code "$SSDVAL")
  CONDCODE=$(cond_code "$CONDVAL")
  COLORCODE=$(color_code "$COLORVAL")

  FULLSKU="${MODEL_ORDER}-${RAMCODE}${SSDCODE}${CONDCODE}${COLORCODE}"
  print_boxed "$FULLSKU" "$MODEL_ORDER" "$MODEL" "$MODEL_BASIC" "$MODEL_EMC" "$BASESKU" "$YEAR" "$CPU" "$GPU" "$BATTERY" "$CHARGER" "$RAMCODE" "$RAMVAL" "$SSDCODE" "$SSDVAL" "$CONDCODE" "$CONDVAL" "$COLORCODE" "$COLORVAL"
}

# === MAIN MENU ===
while true; do
  echo ""
  echo "=== MAIN MENU ==="
  echo "1. Generate SKU Code"
  echo "2. View Available Models"
  echo "3. View Configuration Options"
  echo "4. Lookup by Base SKU"
  echo "5. Lookup by EMC"
  echo "6. Find Model Order"
  echo "7. Exit"
  printf "Choose: "
  read choice
  case "$choice" in
    1) generate_sku ;;
    2) view_models ;;
    3) view_config_options ;;
    4) lookup_by_base ;;
    5) lookup_by_emc ;;
    6) find_model_order ;;
    7) echo "Goodbye!"; exit 0 ;;
    *) echo "Invalid choice." ;;
  esac
done
