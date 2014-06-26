#!/bin/bash

if [ $# != 1 ]; then
    echo "usage: $0 strings" 1>&2
    exit 0
fi

ARGV=$1


nkf -Lu $1 > build/$1.1

ruby bc.rb build/$1.1 > build/$1.2

ruby dn.rb build/$1.2 > build/$1.3

ruby bi.rb build/$1.3 > $1.data

rm build/$1.1 build/$1.2 build/$1.3
