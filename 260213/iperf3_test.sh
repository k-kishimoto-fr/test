#!/bin/bash


SERVER="10.10.100.176"   # 接続先サーバ
INTERVAL=50            # 繰り返し間隔（秒）
RUNS=30                  # 実行回数
typeset -r MYFILE=${0##*/}             # スクリプト名
typeset -r MYNAME=${MYFILE%.*} # スクリプト名(拡張子なし)

for (( i=1; i<=RUNS; i++)); do
    OFILE=${MYNAME}-${i}.txt
    stdbuf -oL iperf3 -c "$SERVER" -t 10 -i 1 --timestamps="%Y-%m-%d %H:%M:%S  "  --forceflush | tee ${OFILE}
    sleep $INTERVAL
done
