#!/bin/bash
set -u

# Usage:
#   ./iperf3_during_checks.sh -i <IFACE> -m <client|server> [-p PORT] [-d DURATION]
#
# Run this while iperf3 is running. It will sample key stats every second.

IFACE=""
MODE=""
PORT=5201
DURATION=15

while getopts "i:m:p:d:" opt; do
  case "$opt" in
    i) IFACE="$OPTARG";;
    m) MODE="$OPTARG";;
    p) PORT="$OPTARG";;
    d) DURATION="$OPTARG";;
    *) echo "Usage: $0 -i <IFACE> -m <client|server> [-p PORT] [-d DURATION]"; exit 1;;
  esac
done

if [ -z "$IFACE" ] || [ -z "$MODE" ]; then
  echo "Usage: $0 -i <IFACE> -m <client|server> [-p PORT] [-d DURATION]"
  exit 1
fi

OUT_BASENAME="iperf3_${MODE}_checks_$(date +%Y%m%d_%H%M%S)"
OUT_FILE="${OUT_BASENAME}.log"

run_cmd() {
  echo "===== $(date '+%Y-%m-%d %H:%M:%S') | $*" >>"${OUT_FILE}"
  if eval "$*" >>"${OUT_FILE}" 2>&1; then
    echo "[OK]" >>"${OUT_FILE}"
  else
    echo "[NG] (exit=$?)" >>"${OUT_FILE}"
  fi
  echo "" >>"${OUT_FILE}"
}

: > "${OUT_FILE}"

echo "# iperf3 during checks (${MODE})" >>"${OUT_FILE}"
run_cmd "uname -a"
run_cmd "cat /etc/os-release"
run_cmd "date"
run_cmd "ip addr show ${IFACE}"
run_cmd "ethtool -i ${IFACE}"
run_cmd "ethtool -k ${IFACE}"
run_cmd "sysctl net.core.rmem_max"
run_cmd "sysctl net.core.wmem_max"
run_cmd "sysctl net.ipv4.tcp_rmem"
run_cmd "sysctl net.ipv4.tcp_wmem"
run_cmd "sysctl net.ipv4.tcp_congestion_control"

# Sample every second during iperf3
for ((t=1; t<=DURATION; t++)); do
  echo "===== SAMPLE ${t}/${DURATION} $(date '+%Y-%m-%d %H:%M:%S')" >>"${OUT_FILE}"
  run_cmd "ss -tin | grep ${PORT}"
  run_cmd "ip -s link show ${IFACE}"
  run_cmd "nstat | head -n 30"
  sleep 1
  done

echo "written: ${OUT_FILE}"