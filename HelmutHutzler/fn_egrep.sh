#!/bin/bash
#
# Search all file for a certain string 
#
#
echo "Search String: " $1
for FILE in `find . -exec egrep -l "$1" {} \;`
  do
    echo TraceFileName:  $FILE
    cat $FILE |  egrep  "$1"
    echo ' -------------------------------------------------------------------- '
done

