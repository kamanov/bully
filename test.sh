#!/usr/bin/env bash

if [ "$#" -ne 1 ]; then
    echo "Illegal number of parameters"
	exit 1
fi
erlc bully.erl
NODES_NUMBER=$1
for (( i=0; i<$NODES_NUMBER; i++ ))
do
	CONNECTED_NODES=""
	for (( j=0; j<$NODES_NUMBER; j++ ))
	do
		if [ $i != $j ]
		then
		      CONNECTED_NODES+=" node$j@`hostname`"
		fi    
	done
	echo "NODES"
	echo $CONNECTED_NODES
    erl bully -sname "node$i" -s bully start ${CONNECTED_NODES} -s init stop -noshell &
done
read
echo "Stop"
pkill beam.smp
