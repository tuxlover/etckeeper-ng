# reset function

reset_etc()
{

#fix for the files with spaces
old_IFS=$IFS
IFS=$'\n'	
	
cd $BACKUPDIR
git checkout -- *
rsync -rtpogq -clis $BACKUPDIR/etc/ /etc/

for file in $(find /etc/ -printf '%p\n')
	do
		in_origin=$(grep $file $BACKUPDIR/content.lst  &> /dev/null && echo "yes" || echo "no") 
		
		if [ $in_origin == "no" ]
			then
				rm $file
				echo ""${file[*]}" was removed from your original since it was not in your backup."
		fi
	done

IFS=$old_IFS
}

