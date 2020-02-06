#!/bin/bash

PASTA=/mysql/res/SSD

function collect {
    bench=$1
    typ=$2
    single=$3

    log="$PASTA/$bench/"
    log+="res_$typ"
    s="_SINGLE.log"
    logs=$log
    logs+=$s

    if [ "$bench" == "MYSQL" ]; then
       grep1="read:"
       grep2="write:"
       grep3="transactions:"
       grep4="queries:"
       V1='$2'
       V2='$2'
    fi

    if [ "$bench" == "100M" ] || [ "$bench" == "2G" ]; then
        grep1="reads/s"
	grep2="writes/s"
	grep3="read,"
	grep4="written,"
	V1='$2'
	V2='$3'
    fi

    if [ "$single" == "single" ]; then
        cat $logs | grep $grep1 | awk '{{print '$V1'}}' > /tmp/1
        cat $logs | grep $grep2 | awk '{{print '$V1'}}' > /tmp/2
        cat $logs | grep $grep3 | awk '{{print '$V2'}}' > /tmp/3
        cat $logs | grep $grep4 | awk '{{print '$V2'}}' > /tmp/4
	paste /tmp/1	/tmp/2	/tmp/3	/tmp/4 > $logs.res
    fi

    rm -f $log.log.res
    for c in $( eval echo {0..9} )
    do
	logm=$log
	logm+="_$c.log"
        cat $logm | grep $grep1 | awk '{{print '$V1'}}' > /tmp/1
        cat $logm | grep $grep2 | awk '{{print '$V1'}}' > /tmp/2
        cat $logm | grep $grep3 | awk '{{print '$V2'}}' > /tmp/3
        cat $logm | grep $grep4 | awk '{{print '$V2'}}' > /tmp/4
        paste /tmp/1    /tmp/2  /tmp/3  /tmp/4 >> $log.log.res
    done
}

declare -a bench=("MYSQL" "100M" "2G")
#declare -a bench=("2G")
for b in "${bench[@]}"
do

    declare -a type=("consistent" "cached" "delegated" "sync" "async")
    #declare -a type=( "async")
    for t in "${type[@]}"
    do
        collect $b $t "single"
    done

done
