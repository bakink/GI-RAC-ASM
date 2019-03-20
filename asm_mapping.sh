--https://mdinh.wordpress.com/2019/03/16/playing-with-oracleasm-and-asmlib/

#!/bin/sh -e
for disk in `/etc/init.d/oracleasm listdisks`
do
oracleasm querydisk -d $disk
#ls -l /dev/*|grep -E `oracleasm querydisk -d $disk|awk '{print $NF}'|sed s'/.$//'|sed '1s/^.//'|awk -F, '{print $1 ",.*" $2}'`
# Alternate option to remove []
ls -l /dev/*|grep -E `oracleasm querydisk -d $disk|awk '{print $NF}'|sed 's/[][]//g'|awk -F, '{print $1 ",.*" $2}'`
echo
done
