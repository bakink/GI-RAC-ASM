#!/bin/bash
#
# Search all file for a certain string 
#
#Usage: 
# Search FATAL CRS errors         : % ~/fn.sh CRS-16 -B 1
# Search  generic CSS exit message: % ~/fn.sh  'aborting' -B 1  [ -A 10 ]
# Search eviction msgs            : % ~/fn.sh  '[Ee]vict' -B 1
# Search Voting msgs              : % ~/fn.sh  '[Vv]oting' -B 1
# Search IMR                      : % ~/fn.sh  'IMR' -B 1
# Search Split-Brain msgs         : %~/fn.sh '[Bb]rain' -B 1

# Search   ALL CRS errors     : % ~/fn.sh CRS- -B 2
# Search   ALL ORA errors     : % ~/fn.sh ORA- -A 3
#   
# Identify Eviction types ( see Top 5 issues for Instance Eviction (Doc ID 1374110.1) )
# 1 Alert.log shows ora-29740 as a reason for instance crash/eviction:  % ~/fn.sh 'ORA-29'  -A 3 -B 3
# 2 Alert.log shows "ipc send timeout" error or "network interface      % ~/fn.sh 'network interface with IP'  -A 3 -B 3
#    with IP dropped" before the instance  crashes or is evicted:        % ~/fn.sh   '[Ii][Pp][Cc] [Ss]end [Tt]imeout' -B 1 -A 2 ( -> tested )
# 3 The problem instance was hanging before the instance crashes or 
#    is evicted:                                                        % ~/fn.sh 'Remote instance kill is issued'  -A 3 -B 3 
# 4 Alert.log shows "Waiting for clusterware split-brain resolution" 
#    before one or more instances crashes or is evicted                 % ~/fn.sh 'Waiting for clusterware split-brain' -A 3 -B 3
# 5 The problem instance is killed by CRS because another instance 
#     tried to evict the problem instance and could not evict it        % ~/fn.sh 'Remote instance kill is issued'  -A 3 -B 3
#
#
echo "Search String: " $1
for FILE in `find . -exec grep -l "$1" {} \;`
  do
    echo TraceFileName:  $FILE
    cat $FILE |  grep -r  "$1" $2 $3  $4 $5 
    echo ' -------------------------------------------------------------------- '
done

