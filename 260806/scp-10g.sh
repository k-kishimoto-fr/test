#!/bin/bash

SRC_FILE="/tmp/10g.test"
DST_USER="root"
DST_HOST="192.168.200.11"
DST_FILE="/tmp/10g.test"
DST_PASS="GRP!0grp"

END_TIME=$(( $(date +%s) + 600 ))

COUNT=0

while [ "$(date +%s)" -lt "$END_TIME" ]
do
    START=$(date +%s)

    sshpass -p ${DST_PASS} scp -q "${SRC_FILE}" "${DST_USER}@${DST_HOST}:${DST_FILE}"

    RC=$?

    END=$(date +%s)

    if [ $RC -ne 0 ]; then
        echo "$(date) SCP failed"
        continue
    fi

    sshpass -p ${DST_PASS} ssh -q "${DST_USER}@${DST_HOST}" "rm -f ${DST_FILE}"

    COUNT=$((COUNT + 1))

    ELAPSED=$((END - START))

    if [ $ELAPSED -gt 0 ]; then
        RATE=$(echo "scale=2; 10240 / $ELAPSED" | bc)
        echo "$(date) iteration=${COUNT} transfer_time=${ELAPSED}s rate=${RATE}MB/s"
    fi
done
