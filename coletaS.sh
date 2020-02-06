#!/bin/bash

#DETACH="--detach"

echo "" > read.log
echo "" > write.log
echo "" > tread.log
echo "" > twrite.log

for c in {0..0}
do
    echo "Get data from container: teste$c"
    docker exec -ti $DETACH teste"$c" sh -c "cat /root/teste.log | grep \"reads/s\" " | awk '{ print $2 }' >> read.log
    docker exec -ti $DETACH teste"$c" sh -c "cat /root/teste.log | grep \"writes/s\"" | awk '{ print $2 }' >> write.log
    docker exec -ti $DETACH teste"$c" sh -c "cat /root/teste.log | grep \"read, MiB\"" | awk '{ print $3 }' >> tread.log
    docker exec -ti $DETACH teste"$c" sh -c "cat /root/teste.log | grep \"written, MiB\"" | awk '{ print $3 }' >> twrite.log
done
