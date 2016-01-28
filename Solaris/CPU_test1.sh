#!/bin/ksh

for i in {1..1000}
do
    for j in {1..1000}
    do
        x=$((sqrt(i*i + j*j)))
    done
done
echo " $x"


./OPatch/prereq CheckConflictAgainstOHWithDetail -ph ./ -invPtrLoc /app/oracle/product/12.1.0/dbhome_1/oraInst.loc

root@swdlprd02:~# time sh test1.sh
 1414.21356237309505

real    0m3.627s
user    0m3.624s
sys     0m0.002s
root@swdlprd02:~# time sh test1.sh
 1414.21356237309505

real    0m3.636s
user    0m3.633s
sys     0m0.002s
root@swdlprd02:~# time sh test1.sh
 1414.21356237309505

real    0m3.599s
user    0m3.596s
sys     0m0.002s

root@swdlprd02:~# time sh test2.sh
 2000

real    0m2.115s
user    0m2.113s
sys     0m0.002s




root@swdlprd02:~# time sh test2.sh
 2000

real    0m2.119s
user    0m2.116s
sys     0m0.002s
root@swdlprd02:~# time sh test2.sh
 2000

real    0m2.122s
user    0m2.119s
sys     0m0.002s
