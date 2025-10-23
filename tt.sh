#!/bin/sh
# Apple MacBook SKU Generator (Online CSV)
# Melody's SKU Tool

CSV_URL="https://getupdates.me/key.csv"

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

view_models() {
  echo ""
  echo "=== AVAILABLE MODELS ==="
  fetch_csv | awk -F, 'NR>1 {printf "%-8s — %-18s — %s\n", $9, $1, $6}' | sort -u
}

view_config_options() {
  echo ""
  echo "=== CONFIGURATION OPTIONS ==="
  echo "RAM:"
  echo "  8 GB  → 3"
  echo "  16 GB → 4"
  echo "  32 GB → 6"
  echo "  36 GB → A"
  echo "  40 GB → D"
  echo "  48 GB → B"
  echo "  64 GB → 7"
  echo ""
  echo "SSD:"
  echo "  128 GB → 4"
  echo "  256 GB → 5"
  echo "  512 GB → 6"
  echo "  1 TB   → 8"
  echo "  2 TB   → A"
  echo "  4 TB   → B"
  echo ""
  echo "Condition:"
  echo "  A → Excellent"
  echo "  B → Good"
  echo "  C → Fair"
  echo "  D → Poor"
  echo ""
  echo "Color Codes:"
  echo "  Gray / Space Gray → G"
  echo "  Silver → S"
  echo "  Rose Gold → R"
  echo "  Gold → D"
  echo "  Blue / Midnight Blue → M"
  echo "  Black / Space Black → B"
}

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

# The generate_sku and find_model_order functions are left mostly unchanged.
# Just replace "$CSV_FILE" with "fetch_csv |" in all awk commands inside them.

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
