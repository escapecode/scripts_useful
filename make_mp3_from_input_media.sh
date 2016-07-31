#!/bin/sh
# This script is used in XFE file manager.
# Making mp3's is a common task.  Another common task is the regex commands that are needed to get the filename.
#

(
	# warning, not, handling overwrite
	#FIXME address filenames with multiple periods

	for arg
	do
		filename_rel="${arg##*/}"	# get only the filename without path
		filename_abs="${arg%%.*}"	# get absolute path of file without file extension

		avconv -i "$arg" "$filename_abs.mp3"
        timestamp=`stat "$arg" | grep Modify | cut -d: -f2- | cut -d\  -f2-`
        touch -d "$timestamp" "$filename_abs.mp3"

		echo "${filename_rel} $filename_abs.mp3"
	done
) | xmessage -file -
