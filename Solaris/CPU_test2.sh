#!/bin/ksh

for i in {1..1000}
do
    for j in {1..1000}
    do
        x=$((j+j))
    done
done
echo " $x"
