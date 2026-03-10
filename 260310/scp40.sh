#!/bin/bash

SERVER="10.10.100.176"
RUNS=40
PASS="2xV!75r6"
typeset -r MYWORK=/tmp/${0##*/}-$$
typeset -r SOCKET="${MYWORK}/ssh-socket"
typeset -r ifile=testfile.dat
# 進捗管理用のディレクトリ
typeset -r DONE_DIR="${MYWORK}/done"

mkdir -p ${MYWORK} ${DONE_DIR}

# --- 1. マスター接続 ---
echo "Launching Master connection..."
sshpass -p "$PASS" ssh -nM -S "${SOCKET}" -o StrictHostKeyChecking=no -o ControlPersist=10m root@${SERVER}

while [ ! -S "${SOCKET}" ]; do sleep 0.2; done
echo "Socket is ready."

# --- 2. 実行 ---
echo "Starting 40 parallel transfers..."

for (( i=1; i<=RUNS; i++)); do
    (
        { time sshpass -p "$PASS" scp -o ControlPath="${SOCKET}" \
            -o ControlMaster=no \
            -o StrictHostKeyChecking=no \
            -c aes128-ctr ${ifile} root@${SERVER}:/dev/null ; } 2>&1 | \
            sed "s/^/[Job $i] /" >> "${MYWORK}/transfer.log"
        
        # 終了したらフラグ用のファイルを作成
        touch "${DONE_DIR}/$i"
    ) &
done

# --- 3. 進行状況のリアルタイム表示 ---
while true; do
    # 完了したファイル数をカウント
    FINISHED=$(ls -1 ${DONE_DIR} | wc -l)
    
    # 簡易進捗バー
    printf "\rProgress: [%-40s] %d/%d" "$(printf '#%.0s' $(seq 1 $FINISHED))" "$FINISHED" "$RUNS"
    
    if [ "$FINISHED" -eq "$RUNS" ]; then
        echo -e "\nAll jobs finished!"
        break
    fi
    sleep 1
done

wait

ssh -S "${SOCKET}" -O exit root@${SERVER} 2>/dev/null
echo "Cleanup completed."
