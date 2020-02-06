#!/bin/bash

#DETACH="--detach"

for c in {0..0}
do
    echo "Clean container: teste$c"
    docker exec -ti $DETACH teste"$c" sh -c "umount /pasta"
    docker exec -ti $DETACH teste"$c" sh -c "echo "" > /root/teste.log"

    for i in {0..29}
    do
        echo "Execucao: $i"
        #docker exec -ti $DETACH teste"$c" sh -c "cd /pasta/ && sysbench --test=fileio --file-total-size=2G --file-test-mode=rndrw --max-time=60 --max-requests=0 run >> /root/teste.log"
        docker exec -ti $DETACH teste"$c" sh -c "cd /pasta/ && sysbench --test=fileio --file-io-mode=async --file-total-size=2G --file-test-mode=rndrw --max-time=60 --max-requests=0 run >> /root/teste.log"
    done
done

