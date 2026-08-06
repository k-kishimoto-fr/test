#!/bin/bash

#--------------------------------------------------
# Edge負荷確認用 HTTP Download Script
#--------------------------------------------------

URL="https://speed.cloudflare.com/__down?bytes=90000000"

DURATION=600
PARALLEL=16

while [ $# -gt 0 ]; do
    case "$1" in
        -url)
            shift
            URL="$1"
            ;;
        -duration)
            shift
            DURATION="$1"
            ;;
        -parallel)
            shift
            PARALLEL="$1"
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
    shift
done

START_TIME=$(date +%s)
END_TIME=$((START_TIME + DURATION))

WORKDIR="/tmp/http_load_$$"
mkdir -p "${WORKDIR}"

echo "======================================"
echo "Start Time : $(date)"
echo "URL        : ${URL}"
echo "Duration   : ${DURATION} sec"
echo "Parallel   : ${PARALLEL}"
echo "======================================"

worker() {

    local id=$1
    local count=0

    while [ "$(date +%s)" -lt "${END_TIME}" ]
    do
        START=$(date +%s)

        curl \
            -L \
            -s \
            -o /dev/null \
            "${URL}"

        RC=$?

        STOP=$(date +%s)
        ELAPSED=$((STOP - START))

        count=$((count + 1))

        echo "$(date '+%F %T') worker=${id} count=${count} rc=${RC} sec=${ELAPSED}" \
            >> "${WORKDIR}/worker_${id}.log"
    done
}

for ((i=1; i<=PARALLEL; i++))
do
    worker "${i}" &
done

wait

echo "======================================"
echo "Finished : $(date)"
echo "Logs     : ${WORKDIR}"
echo "======================================"