#!/bin/bash
#-------------------------------------------------------------------#
# = Title : sampling_get_http.sh
# = Author : 東 一博
# = Date : 2025-02-10
# = Memo : HTTP受信サンプリングスクリプト
# = Description :
#   httpbin.org(HTTPテストサイト)を使用して、指定サイズのHTTP受信にかかる時間をサンプリングする
#   httobinの仕様上、URIに含めたサイズのデータ生成のためのラグがあるため、データ転送時間は
#   curlがレスポンスするメタデータのうち、総応答時間 - 最初の1バイトの受信時間 を計算して使用してください。
#   
# = Usage :
#   $ ./sampling_get_http.sh \
#    -kbyte 10 \       # 受信するHTTPのサイズ(KB)
#    -interval 20 \    # サンプリング間隔(秒)
#    -sample 1000 \    # サンプリング回数
#    -client 10        # クライアント数
#
# = 出力フォーマット(CSV):
#   1: 日時
#   2: クライアントID
#   3: HTTPステータスコード
#   4: 総応答時間 (time_total)
#   5: 最初の1バイト受信時間 (time_starttransfer)
#   6: SSL接続確立時間 (time_appconnect)
#   7: TCP接続確立時間 (time_connect)
#   8: DNS解決時間 (time_namelookup)
#   9: サーバIPアドレス (remote_ip)
#
# = CSV出力例:
# 2026-02-10 14:28:03,000,200,0.763731,0.762961,0.570503,0.008755,0.000055,10.131.129.12
# 2026-02-10 14:28:06,001,200,1.130806,1.130164,0.558741,0.005267,0.000053,10.131.129.12
# 2026-02-10 14:28:10,002,200,1.123919,0.948179,0.558693,0.004465,0.000063,10.131.129.12
# 2026-02-10 14:28:15,000,200,0.739278,0.738327,0.539583,0.004686,0.000050,10.131.129.12
# 2026-02-10 14:28:18,001,200,0.824643,0.824186,0.567256,0.004560,0.000079,10.131.129.12
# 2026-02-10 14:28:21,002,200,0.775099,0.774118,0.565331,0.004500,0.000054,10.131.129.12
# 2026-02-10 14:28:26,000,200,1.196578,1.196370,0.542582,0.004868,0.000050,10.131.129.12 
# 2026-02-10 14:28:29,001,200,0.804774,0.804679,0.606081,0.005499,0.000057,10.131.129.12
# 2026-02-10 14:28:32,002,200,0.792161,0.791784,0.565792,0.004869,0.000066,10.131.129.12
#
# = 転送時間算出例
#   総応答時間 - 最初の1バイト受信時間
#   例) 0.763731 - 0.762961 = 0.000770秒 (770マイクロ秒)
#
# = 注意事項 :
#   - httpbin.orgのサービス仕様上、URIに含めたサイズのデータ生成にラグがあるため、
#     転送時間の正確な測定には向かない可能性があります。
#   - 大量のリクエストを短時間に送信すると、httpbin.org側で制限がかかる場合があります。
#     適切な間隔を空けてリクエストを送信してください。
#-------------------------------------------------------------------#

#-------------------------------------------------------------------#
# 定数
#-------------------------------------------------------------------#
#typeset -r TPL_URL="https://httpbin.org/bytes/%http_byte%"   # HTTPテストサイトのURL
typeset -r TPL_URL="https://speed.cloudflare.com/__down?bytes=%http_byte%"   # HTTPテストサイトのURL
#typeset -r TPL_URL="https://mockerapi.com/bytes/%http_byte%" # HTTPテストサイトのURL (httpbin.orgより高負荷テストに向いている)
#typeset -r TPL_URL="https://httpi.dev/bytes/%http_byte%"      # HTTPテストサイトのURL (httpbin.orgより高負荷/大容量にむいてる)

typeset -r MYFILE=${0##*/}                               # スクリプト名
typeset -r MYNAME=${MYFILE%.*}                           # スクリプト名(拡張子なし)
typeset -r MYPID=$$                                      # プロセスID
typeset -r MYWORK="/tmp/${MYNAME}_${MYPID}"              # ワーキングディレクトリ  
typeset -r LOGFILE="${MYWORK}/${MYNAME}.log"             # ログファイル
typeset -r CSVFILE="${MYWORK}/${MYNAME}_result.csv"      # 結果CSVファイル


#-------------------------------------------------------------------#
# ワーキングディレクトリ作成
# 出力ファイル書き込み確認
#-------------------------------------------------------------------#
mkdir -p ${MYWORK} || { echo "Error: mkdir ${MYWORK}"; exit 1; }
touch ${LOGFILE} || { echo "Error: touch ${LOGFILE}"; exit 1; }
touch ${CSVFILE} || { echo "Error: touch ${CSVFILE}"; exit 1; }

#-------------------------------------------------------------------#
# 引数処理
#-------------------------------------------------------------------#
while [ $# -gt 0 ]; do
  case $1 in
    -kbyte )    shift; typeset -r KBYTE=$1 ;;           
    -interval ) shift; typeset -r INTERVAL=$1 ;;
    -sample )   shift; typeset -r SAMPLE=$1 ;;
    -client )   shift; typeset -r CLIENT=$1 ;;
    * )         echo "Unknown argument: $1"; exit 1 ;;
  esac
  shift
done || { echo "Argument error"; exit 1; }

# デフォルト値設定
: ${KBYTE:=10}      # デフォルト値10,000バイト(10KB)
: ${INTERVAL:=10}   # デフォルト値10秒
: ${SAMPLE:=600}    # デフォルト値600回
: ${CLIENT:=5}      # デフォルト値5クライアント

typeset -r KBYTE INTERVAL SAMPLE CLIENT

GET_URL=${TPL_URL//%http_byte%/$((KBYTE * 1000))}  # 受信URL
typeset -r GET_URL

SAMPLE_PER_CLIENT=$(( SAMPLE / CLIENT ))  # クライアントあたりのサンプリング回数
START_INTERVAL=$(( INTERVAL / CLIENT ))   # クライアント起動間隔

typeset -r SAMPLE_PER_CLIENT START_INTERVAL 

# 子プロセス管理: 起動したバックグラウンドジョブのPIDを保持
typeset -a PIDS=()

#-------------------------------------------------------------------#
# 関数定義
#-------------------------------------------------------------------#
function _log {
  typeset sev="$( printf '%-8s' ${1} )"
  typeset dt="$(date '+%Y/%m/%d %H:%M:%S')"
  typeset msg="${2}"
  echo "${dt} [${sev}] ${MYNAME} ${msg}"
  echo "${dt} [${sev}] ${msg}" >> ${LOGFILE}
}

function e_log { _log "ERROR" "${1}"; }
function i_log { _log "INFO"  "${1}"; }

function get_http {
# HTTP GETサンプリング処理
# 引数: クライアントID(0～)
  client_id=$( printf "%03d" ${1} ) 
  completed=0

  i_log "Client ${client_id} started. Sampling ${SAMPLE_PER_CLIENT} times."


  # HTTP GET実行
  while [ $(( SAMPLE_PER_CLIENT )) -gt ${completed} ]
  do
  curl -o /dev/null -sS -w "$( date +'%Y-%m-%d %H:%M:%S'),${client_id},%{http_code},%{time_total},%{time_starttransfer},%{time_appconnect},%{time_connect},%{time_namelookup},%{remote_ip}\n" ${GET_URL} >> ${CSVFILE}
  if [[ $? -ne 0 ]]; then
    e_log "client ${client_id} on sample $(( completed + 1 )) Failed to get HTTP response."
  else    
    i_log "client ${client_id} on sample $(( completed + 1 )) Successfully got HTTP response."
  fi

  #異常レスポンスは、CSVファイ分析時にhttp_codeで判定する。
  
  sleep ${INTERVAL:-60}     #未指定時は60秒待機( 安全のため)     

  completed=$(( completed + 1 ))

done
} #get_http

function cleanup {
  # Ctrl+C (SIGINT) や SIGTERM を受け取ったら子プロセスを終了する
  i_log "Interrupt received, terminating child processes..."
  if [ ${#PIDS[@]} -gt 0 ]; then
    for pid in "${PIDS[@]}"; do
      if kill -0 "$pid" 2>/dev/null; then
        kill "$pid" 2>/dev/null || true    #SIGTERM
      fi
    done
    sleep 1
    for pid in "${PIDS[@]}"; do
      if kill -0 "$pid" 2>/dev/null; then
        kill -9 "$pid" 2>/dev/null || true #SIGKILL
      fi
    done
  fi
  i_log "Cleanup complete. Exiting."
  exit 130
} #cleanup


#-------------------------------------------------------------------#
# メイン処理
#-------------------------------------------------------------------#
i_log "Start HTTP GET sampling script."
i_log "Parameters: KBYTE=${KBYTE}, INTERVAL=${INTERVAL}, SAMPLE=${SAMPLE}, CLIENT=${CLIENT}, SAMPLE_PER_CLIENT=${SAMPLE_PER_CLIENT}, START_INTERVAL=${START_INTERVAL}"
i_log "GET URL: ${GET_URL}"

trap 'cleanup' INT TERM #割り込み、終了シグナルをキャッチしてcleanup関数を呼び出す

# 受信クライアント起動
ACTIVE_CLIENT=0

while [ ${ACTIVE_CLIENT} -lt ${CLIENT} ]
do
  get_http ${ACTIVE_CLIENT} &
  PIDS+=( $! ) 
  ACTIVE_CLIENT=$(( ACTIVE_CLIENT + 1 ))
  sleep ${START_INTERVAL}
done

# 全バックグラウンドジョブが終わるまで待機
wait

i_log "All clients have completed sampling."
i_log "HTTP GET sampling script finished. REF: ${CSVFILE}"







