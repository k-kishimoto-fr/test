#!/bin/bash

SERVER="10.10.100.176"
RUNS=40
PASS="2xV!75r6"
typeset -r MYWORK=/tmp/${0##*/}-$$
typeset -r SOCKET="${MYWORK}/ssh-socket"
typeset -r ifile=testfile.dat

# ログディレクトリ作成
mkdir -p ${MYWORK}

# --- 重要: 最初に「土台」となるマスター接続を作る ---
# -M: マスターモード, -N: コマンド実行せず待機, -f: バックグラウンドへ
# StrictHostKeyChecking=no を入れないと、初回の fingerprint 確認で40個全部止まります
sshpass -p "$PASS" ssh -nMf -S "${SOCKET}" \
    -o StrictHostKeyChecking=no \
    -o ControlPersist=10m \
    root@${SERVER}

echo "Master connection established. Starting 40 parallel transfers..."

# --- 40同時に実行 ---
for (( i=1; i<=RUNS; i++)); do
    (
        # ControlMaster=no (既存のソケットを使うだけ) にするのがコツ
        # time コマンドの結果をログに残す
        { time sshpass -p "$PASS" scp -o ControlPath="${SOCKET}" \
            -o StrictHostKeyChecking=no \
            -c aes128-ctr ${ifile} root@${SERVER}:/dev/null ; } 2>&1 | \
            sed "s/^/[Job $i] /" >> "${MYWORK}/transfer.log"
    ) &
done

# 全終了を待機
wait

# マスター接続をクローズ
ssh -S "${SOCKET}" -O exit root@${SERVER} 2>/dev/null
echo "All transfers completed. Log: ${MYWORK}/transfer.log"
