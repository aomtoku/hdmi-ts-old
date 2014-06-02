#!/bin/bash

if [ $# != 1 ]; then
    echo "usage: $0 strings" 1>&2
    exit 0
fi

ARGV=$1

cat $ARGV | while read line
do
   echo $line | awk '{ print $1 $2 $3 }' | xargs -J % printf "obase=10; ibase=2; %b\n" % | bc  
done

