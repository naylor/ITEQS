#!/bin/bash

DETACH="--detach"
NUMC=9
EXEC=29
PASTA=/mysql

#sudo find /mysql/res/ | grep .log | xargs rm -f

function clean {
    NUMC=$1
    for c in $( eval echo {0..$NUMC} )
    do
        echo "Stoping and dropping container: teste$c"
        sudo docker stop teste"$c"
        sudo docker rm teste"$c"
    done
    sudo rm /mysql/imagem/resultados/* 
}

function create {
    NUMC=$1
    DV=$2
    TIPO=$3

    for c in $( eval echo {0..$NUMC} )
    do
        echo "Creating container: teste$c:$DV"
   
        #DOCKER VOLUME
        if [ "$DV" == "consistent" ] || [ "$DV" == "cached" ] || [ "$DV" == "delegated" ]; then
            sudo docker run -it -d --name=teste"$c" -v $PASTA:$PASTA:$DV ubuntu:teste
	    sudo /etc/init.d/nfs-kernel-server stop
	fi
    
        #NFS
	if [ "$DV" == "sync" ] || [ "$DV" == "async" ]; then
            sudo /etc/init.d/nfs-kernel-server stop
	    if [ "$DV" == "sync" ]; then
                sudo sed -i -e 's/\<async\>/sync/g' /etc/exports
	    fi
            if [ "$DV" == "async" ]; then
		sudo sed -i -e 's/\<sync\>/async/g' /etc/exports
	    fi

            sudo /etc/init.d/nfs-kernel-server start
            sudo docker run -it --privileged -d --name=teste"$c" ubuntu:teste
            sudo docker exec -ti teste"$c" sh -c "mount 172.17.0.1:$PASTA $PASTA"
	    sudo docker exec -ti teste"$c" sh -c "touch /mysql/teste"

        fi
	
	#BENCH
	if [ "$TIPO" == "100M" ] || [ "$TIPO" == "2G" ]; then
	    if [ "$c" == 0 ]; then
                sudo rm -f /mysql/test_file*
	        echo "Sysbanch Prepare..."
                sudo docker exec -ti teste"$c" sh -c "cd /mysql && sysbench --test=fileio --file-total-size=$TIPO prepare"
	        sudo chmod 777 /mysql/test_file*
	    fi
        fi

	#MYSQL
	sudo docker exec -ti teste"$c" sh -c "/etc/init.d/mysql stop"
	if [ "$TIPO" == "MYSQL" ]; then
            sudo docker exec -ti teste"$c" sh -c "sed -i -e 's/\/var\/lib\/mysql/\/mysql\/$c\/mysql/g' /etc/mysql/mysql.conf.d/mysqld.cnf"
            sudo docker exec -ti teste"$c" sh -c "/etc/init.d/mysql start"
	fi
          
        sudo docker exec -ti teste"$c" sh -c "/etc/init.d/ssh start"
        sudo docker exec -ti teste"$c" sh -c "ls $PASTA | wc -l"
        
    done
}

function run {
    NUMC=$1
    EXEC=$2
    DV=$3
    TIPO=$4
    S=$5

    WAIT="1"
    for m in $( eval echo {0..$EXEC} )
    do
        echo "Numero do teste: $m - $DV"
	for i in $( eval echo {0..$NUMC} )
        do
	    LOG="/mysql/res/$TIPO/res_${DV}_${i}.log"
	    if [ "$S" == "single" ]; then
                LOG="/mysql/res/$TIPO/res_${DV}_SINGLE.log"
	    fi

	    echo "Container: teste$i >>>> $TIPO >>>> logging in $LOG"

            #MYSQL
	    if [ "$TIPO" == "MYSQL" ]; then
	        sudo docker exec -ti $DETACH teste"$i" sh -c "sysbench /usr/share/sysbench/oltp_read_write.lua --mysql-host=localhost --mysql-port=5701 --mysql-user=teste --mysql-password='123456' --mysql-db=teste --db-driver=mysql --tables=1 --table-size=100000 --threads=1 --time=60 run >> $LOG"
	    fi

	    #BENCH
	    if [ "$TIPO" == "100M" ] || [ "$TIPO" == "2G" ]; then
                AS=""
	        if [ "$DV" == "async" ]; then
	           AS="--file-io-mode=async"
	        fi
	        echo "Sysbench running..."
                sudo docker exec -ti $DETACH teste"$i" sh -c "cd /mysql/ && sysbench --test=fileio $AS --file-total-size=$TIPO --file-test-mode=rndrw --time=60 --max-requests=0 run >> $LOG"
            fi

	    #IMAGE
	    if [ "$TIPO" == "IMAGEP" ] || [ "$TIPO" == "IMAGEG" ]; then
		NH=12
		LIN=300
		HOST="--hostfile /mysql/imagem/nodes"
		if [ "$S" == "single" ]; then
		    NH=2
		    LIN=300
		    HOST="--host 172.17.0.2"
		fi
		cd /mysql/imagem/ && mpiexec -n $NH $HOST /mysql/imagem/PPMparalelo -i $TIPO.ppm -t 1 -c $LIN
		cat /mysql/imagem/resultados/P_$TIPO.ppm.txt > $LOG
		WAIT="0"
		break
            fi

       done

       if [ "$WAIT" == "1" ]; then
          echo "Esperando 70 segundos: "
           for n in {1..70}
           do
               printf "|"
	       if [ $((n%10)) == 0 ]; then
                   printf $n
	       fi
               sleep 1
           done
           echo " "
        fi
    done
}

#declare -a tipo=("MYSQL" "100M" "2G"  "IMAGEP" "IMAGEG")
declare -a tipo=( "IMAGEG")
for t in "${tipo[@]}"
do

    declare -a arr=("consistent" "cached" "delegated" "sync" "async")
    #declare -a arr=( "async")
    for d in "${arr[@]}"
    do
        clean 9
        create 0 $d $t
        run 0 29 $d $t "single"
    done

    for d in "${arr[@]}"
    do
        clean 9
        create 9 $d $t
        run 9 29 $d $t
    done
done
