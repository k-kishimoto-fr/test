#!/bin/bash


SERVER="秘密"  
#INTERVAL=50            
RUNS=40
PASS="2xV!75r6"
typeset -r MYFILE=${0##*/}  
typeset -r MYNAME=${MYFILE%.*}
typeset -r MYWORK=/tmp/${MYNAME}-$$
typeset -r MYLOG=${MYWORK}/${MYNAME}.log
typeset -r ifile=testfile.dat


function _log {
    typeset msg=$1
    echo "$( date +'%Y%m%d%H%M%S' ): ${1}" | tee -a ${MYLOG}
}

function runscp {
    typeset -r num=$1
    _log "${num} start"
    sshpass -p "$PASS" time scp -o ControlMaster=auto -o ControlPath=${MYWROK}/ssh-%r@%h:%p -c aes128-ctr ${ifile} root@${SERVER}:/dev/null | tee -a ${MYLOG}
    _log "${num} end"
}

mkdir ${MYWORK} || exit 1
runscp 0
for (( i=1; i<=RUNS; i++)); do
    runscp ${i} &
done

wait

_log "${MYFILE} END."
