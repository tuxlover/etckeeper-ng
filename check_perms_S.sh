check_perms_S()
{
return_check=0
echo "checking Permissions ..."	
	
count=$(wc -l $BACKUPDIR/content.lst | awk '{print $1}')

until [ $count == 0  ]
	do
		FILE=$(tail -n ${count} $BACKUPDIR/content.lst|head -1)
		NAME=$(echo $FILE|awk '{print $1}')
		PERMS=$(echo $FILE|awk '{print $2}')
		OWNU=$(echo $FILE|awk '{print $3}')
		OWNG=$(echo $FILE|awk '{print $4}')
		
	#if a file is not present, skip test
		if [ ! -e "$NAME" ]
			then
				count=$((count-=1))
				continue
		fi
	
	#cheking whether the Permissions have changed
		if [ "$(stat -c %a $NAME)" != "$PERMS"  ]
			then	
				echo -e '\E[31m permissions'; echo "of file $NAME has changed to $(stat -c %a $NAME)"
				tput sgr0
				chmod $PERMS $NAME
				echo "permissions for file $NAME restored"
				return_check=1
		fi
		
	#checking whether the Owner or the Group has changed 
		if [[ "$(stat -c %U $NAME)" != "$OWNU" || "$(stat -c %G $NAME)" != "$OWNG" ]]
			then				
				echo -e '\E[31m owner or group'; echo  "of $NAME has changed to $(stat -c "%U:%G" $NAME)"
				tput sgr0
				chown $OWNU:$OWNG $NAME
				echo "Owner and Group for $FILE restored"
				return_check=1
		fi

		count=$((count-=1))
		unset FILE

	done
	return $return_check
}


list_git()
{

cd $BACKUPDIR 2> /dev/null || return 1
git branch -a
PAGER=cat git log
}
