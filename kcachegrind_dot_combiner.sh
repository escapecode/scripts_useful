#!/bin/sh

prog_name=kcachegrind_dot_combiner.sh

# Usage
if [ $# -gt 0 ]; then
	echo "______"
    echo "| Usage: $prog_name"
    echo "|"
	echo "| example"
	echo "| 1. valgrind --tool=callgrind ./blender"
	echo "| 2. put all callgrind.out files in a path.  for example"
	echo " while true"
	echo " do"
	echo "  for i in callgrind.out.*"
	echo "  do"
	echo "    mv -b '$i' out/"
	echo "  done"
	echo "  sleep 3"
	echo " done"
	echo "| 3 new terminal run kcachegrind in executable directory"
	echo "| 4 walk through call graph and export all major branches"
	echo "| 5 stop while loop"
	echo "| 6 run $prog_name to combine .dot files"
	echo "----"
    exit 1
fi

###############
#  TODO -add rest of temp files (i.e. all_labels2.txt
FILE_LABELS="`mktemp -t $prog_name.XXXXXXXXXX`" || exit
FILE_CONNECTORS="`mktemp -t $prog_name.XXXXXXXXXX`" || exit

trap 'rm -f -- "$FILE_LABELS" "$FILE_CONNECTORS"' EXIT
trap 'trap - EXIT; rm -f -- "$FILE_LABELS" "$FILE_CONNECTORS"; exit 1' HUP INT QUIT TERM
###############

echo "" > $FILE_LABELS
echo "" > $FILE_CONNECTORS
for i in *.dot
do
	# grep removes first and last lines and lines with "->".  sed will remove beginning line whitespace and label then clear lines with only ~ and remove empty lines and removes blank lines
	grep -v "\->\|digra\|}" $i | sed 's/\(\\n.*\|^[[:space:]]*\)//g; s/ \[label="/~/; s/^~$//; /^\s*$/d' >> $FILE_LABELS

	# remove labels and remove empty lines
	grep "\->" $i | sed 's/ \[.*]//; /^\s*$/d' >> $FILE_CONNECTORS
done

LAST_LABEL=''
LAST_ID=''
echo "" > labels.txt

echo "" > all_labels2.txt
while IFS= read -r i
do
		echo "$i" | awk -F~ '{print($2"~"$1)}' >> all_labels2.txt
done < "$FILE_LABELS"

sort -u all_labels2.txt > all_labels3.txt
while IFS= read -r i
do
        my_label=`echo "$i" | cut -d~ -f1`
		my_id=`echo "$i" | cut -d~ -f2`

        if test "$my_label" != "$LAST_LABEL" ; then
                # echo ok $my_label == $LAST_LABEL
                echo   $my_id [label=\"$my_label\"]\; >> labels.txt

                LAST_LABEL="$my_label"
                LAST_ID="$my_id"
        else
				# note that the dot object type can be changed from sphere to something different on branches, etc.
                echo skipping/updating duplicate $my_label from $my_id to $LAST_ID
                sed -i s/$my_id/$LAST_ID/g $FILE_CONNECTORS	#TODO: id fields need to be normalized
        fi
done < "all_labels3.txt"

sed '/^\s*$/d' $FILE_CONNECTORS | sort -u > connectors.txt

echo 'digraph "callgraph" {' > dotfile.txt
sed '/^\s*$/d' labels.txt >> dotfile.txt
cat connectors.txt >> dotfile.txt
echo '}' >> dotfile.txt

echo "finished combining dot files.  To create a SVG file for display:"
echo "dot -Tsvg dotfile.txt > dotfile.svg"