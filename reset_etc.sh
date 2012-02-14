# reset function

reset_etc()
{
echo "resetting from latest backup ..."
#fix for the files with spaces
old_IFS=$IFS
IFS=$'\n'	

echo "checkout last commit ..."	
cd $BACKUPDIR
git checkout -- *

echo "syncing back to current working /etc directory ..."
rsync -rtpogq -clis $BACKUPDIR/etc/ /etc/

echo "deleting files not found in latest backup ..."
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
echo -e '\E[32m done'
tput sgr0
}

