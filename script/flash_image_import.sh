#!/bin/bash

# look through a set of flash build directories looking for new images
# compare them and offer to replace them...

root=`dirname $0`
install=$root/../public/players

function usage () {
	echo "usage: $0 <flash import dir>"
	exit
}

if [ $# != 1 ]; then usage; fi
if [ ! -d $1 ]; then usage; fi

find $1 -name images | while read img_dir; do
	echo "Scanning $img_dir"
	for file in $img_dir/*; do 
		#echo $file
		image=`basename $file`
		if [ -e $install/images/$image ]; then 
			cmp $install/images/$image $file
			if [ $? == 0 ]; then
				echo "SAME: ${file} "
			else
				echo -n "CHANGE: ${file}  Copy to project? [y/N] "
				read copy <&1
				if [ "${copy}" == 'y' ]; then
					cp $file $install/images/
				fi
			fi
		else
			echo -n "NEW: ${file}  Copy to project? [y/N] "
			read copy
			if [ "${copy}" == 'y' ]; then
				cp $file $install/images/
			fi
		fi

	done
done

