#!/bin/bash
set -u

usage() {
  echo "Usage: $0 --mode {default|tuned}"
  echo "  default: 元設定に戻す"
  echo "  tuned  : 変更設定を適用"
}

MODE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --mode) shift; MODE="${1:-}";;
    -h|--help) usage; exit 0;;
    *) echo "Unknown arg: $1"; usage; exit 1;;
  esac
  shift
 done

if [ -z "$MODE" ]; then
  usage; exit 1
fi

case "$MODE" in
  default)
    sudo sysctl -w net.core.rmem_max=212992
    sudo sysctl -w net.core.wmem_max=212992
    sudo sysctl -w net.ipv4.tcp_rmem="4096 131072 6291456"
    sudo sysctl -w net.ipv4.tcp_wmem="4096 16384 4194304"
    ;;
  tuned)
    sudo sysctl -w net.core.rmem_max=33554432
    sudo sysctl -w net.core.wmem_max=33554432
    sudo sysctl -w net.ipv4.tcp_rmem="4096 87380 33554432"
    sudo sysctl -w net.ipv4.tcp_wmem="4096 65536 33554432"
    ;;
  *)
    echo "Unknown mode: $MODE"; usage; exit 1;;
 esac

# Show current values
sysctl net.core.rmem_max
sysctl net.core.wmem_max
sysctl net.ipv4.tcp_rmem
sysctl net.ipv4.tcp_wmem#!/bin/bash
set -u

usage() {
  echo "Usage: $0 --mode {default|tuned}"
  echo "  default: 元設定に戻す"
  echo "  tuned  : 変更設定を適用"
}

MODE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --mode) shift; MODE="${1:-}";;
    -h|--help) usage; exit 0;;
    *) echo "Unknown arg: $1"; usage; exit 1;;
  esac
  shift
 done

if [ -z "$MODE" ]; then
  usage; exit 1
fi

case "$MODE" in
  default)
    sudo sysctl -w net.core.rmem_max=212992
    sudo sysctl -w net.core.wmem_max=212992
    sudo sysctl -w net.ipv4.tcp_rmem="4096 131072 6291456"
    sudo sysctl -w net.ipv4.tcp_wmem="4096 16384 4194304"
    ;;
  tuned)
    sudo sysctl -w net.core.rmem_max=33554432
    sudo sysctl -w net.core.wmem_max=33554432
    sudo sysctl -w net.ipv4.tcp_rmem="4096 87380 33554432"
    sudo sysctl -w net.ipv4.tcp_wmem="4096 65536 33554432"
    ;;
  *)
    echo "Unknown mode: $MODE"; usage; exit 1;;
 esac

# Show current values
sysctl net.core.rmem_max
sysctl net.core.wmem_max
sysctl net.ipv4.tcp_rmem
sysctl net.ipv4.tcp_wmem