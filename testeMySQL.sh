#!/bin/bash

DETACH="--detach"

echo "# $1 #";


for c in {0..9}
do
    echo "Clean container: teste$c"
    rm /home/naylor/mysql/res_$c.log
done


for m in {0..29}
do
    echo "Numero do teste: $m"
    for i in {0..9}
    do
        echo "Container: teste$i"
	sudo docker exec -ti $DETACH teste"$i" sh -c "sysbench /usr/share/sysbench/oltp_read_write.lua --mysql-host=localhost --mysql-port=5701 --mysql-user=teste --mysql-password='123456' --mysql-db=teste --db-driver=mysql --tables=1 --table-size=100000 --threads=1 --time=60 run >> /home/naylor/mysql/res_$i.log"
    done

    echo "Esperando 70 segundos: "
    for n in {0..69}
    do
        printf "|"
	sleep 1
    done
    echo " "
done

