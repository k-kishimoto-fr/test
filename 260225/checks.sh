#!/bin/bash
set -u

OUT_BASENAME="nsx_iperf3_checks_$(date +%Y%m%d_%H%M%S)"
OUT_FILE="${OUT_BASENAME}.log"

run_cmd() {
  echo "===== $(date '+%Y-%m-%d %H:%M:%S') | $*" | tee -a "${OUT_FILE}"
  if eval "$*" >>"${OUT_FILE}" 2>&1; then
    echo "[OK]" | tee -a "${OUT_FILE}"
  else
    echo "[NG] (exit=$?)" | tee -a "${OUT_FILE}"
  fi
  echo "" >>"${OUT_FILE}"
}

read -r -p "対象IF名を入力してください (例: eth0): " IFACE

: > "${OUT_FILE}"

echo "# nsx/iperf3 quick checks" | tee -a "${OUT_FILE}"
run_cmd "uname -a"
run_cmd "cat /etc/os-release"
run_cmd "date"

run_cmd "ip addr show ${IFACE}"
run_cmd "ip -s link show ${IFACE}"
run_cmd "ethtool -i ${IFACE}"
run_cmd "ethtool -k ${IFACE}"
run_cmd "ss -lntp | grep 5201"
run_cmd "ss -tin | grep 5201"

run_cmd "sysctl net.ipv4.tcp_rmem"
run_cmd "sysctl net.ipv4.tcp_wmem"
run_cmd "sysctl net.ipv4.tcp_congestion_control"
run_cmd "sysctl net.core.rmem_max"
run_cmd "sysctl net.core.wmem_max"

run_cmd "nstat | head -n 50"

run_cmd "firewall-cmd --state"
run_cmd "firewall-cmd --list-ports"

run_cmd "dmesg | tail -n 50"


echo "" | tee -a "${OUT_FILE}"
echo "written: ${OUT_FILE}"