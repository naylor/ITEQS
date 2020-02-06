#!/bin/bash

DETACH="--detach"

for c in {0..9}
do
    echo "Clean container: teste$c"
    docker exec -ti $DETACH teste"$c" sh -c "umount /pasta"
    #docker exec -ti $DETACH teste"$c" sh -c "mount 172.17.0.1:/pasta /pasta"
    docker exec -ti $DETACH teste"$c" sh -c "echo "" > /root/teste.log"
done


for m in {0..29}
do
    echo "Numero do teste: $m"
    for i in {0..9}
    do
        echo "Container: teste$i"
        #docker exec -ti $DETACH teste"$i" sh -c "umount /pasta"
        #docker exec -ti $DETACH teste"$i" sh -c "mount 172.17.0.1:/pasta pasta"
        #docker exec -ti $DETACH teste"$i" sh -c "echo "" > /root/teste.log"
        for j in {0..0}
        do
            echo "Execucao: $j"
            #docker exec -ti $DETACH teste"$i" sh -c "cd /pasta/ && sysbench --test=fileio --file-total-size=2G --file-test-mode=rndrw --max-time=60 --max-requests=0 run >> /root/teste.log"
            docker exec -ti $DETACH teste"$i" sh -c "cd /pasta/ && sysbench --test=fileio --file-io-mode=async --file-total-size=2G --file-test-mode=rndrw --max-time=60 --max-requests=0 run >> /root/teste.log"
        done
    done

    echo "Esperando 70 segundos: "
    for n in {0..69}
    do
        printf "|"
	sleep 1
    done
    echo " "
done

