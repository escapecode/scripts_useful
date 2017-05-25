#!/bin/sh

# low resource way of getting notifications when any /var/log file is updated.
# This is complimentary to tail -f, multitail and other tools

# NOTE:  Script works fine, but I might remove $2

echo $0 PATH FILENAME
echo FILENAME should not have spaces
echo
echo (eg.  $0 /var/log messages)

inotifywait -m -e modify $1 |
while read -r directory events filename
do
        tail1=`tail -1 "$directory/$filename"`
        echo -ne "$directory$filename   -> $tail1"
        echo
         gtkdialog-splash -placement bottom-right -fg "#17171E" -bg "#25344C" -fontsize 8 -border false -icon gtk-info -margin 2 -timeout 6 -text "$directory$filename   ->   $tail1" 2>/dev/null 1>/dev/null &
        if [ "$filename" = $2 ]; then
                echo $1/$2 found
        fi
done
