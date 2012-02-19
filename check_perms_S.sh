check_perms_S()
{
# fix problems with german umlauts
# if already set do nothing
git config --global core.quotepath false || :
	
return_check=0
echo "checking Permissions ..."	
	
count=$(wc -l $BACKUPDIR/content.lst | awk '{print $1}')
old_IFS=$IFS
IFS=""

until [ $count == 0  ]
	do
		FILE=$(tail -n ${count} $BACKUPDIR/content.lst|head -1)
		NAME=$(echo $FILE|awk awk '{$1="";$2="";$3="";print}'|awk '{ sub(/^[ \t]+/, ""); print }')
		PERMS=$(echo $FILE|awk '{print $1}')
		OWNU=$(echo $FILE|awk '{print $2}')
		OWNG=$(echo $FILE|awk '{print $3}')
		
	# if a file is not present, skip test
		if [ ! -e "${NAME[*]}" ]
			then
				count=$((count-=1))
				continue
		fi
	
	# cheking whether the Permissions have changed
		if [ "$(stat -c %a ${NAME[*]})" != "$PERMS"  ]
			then	
				echo -e '\E[31m permissions'; echo "of file ${NAME[*]} has changed to $(stat -c %a ${NAME[*]})"
				tput sgr0
				chmod $PERMS "${NAME[*]}"
				echo "permissions for file ${NAME[*]} restored"
				return_check=1
		fi
		
	# checking whether the Owner or the Group has changed 
		if [[ "$(stat -c %U ${NAME[*]})" != "$OWNU" || "$(stat -c %G ${NAME[*]})" != "$OWNG" ]]
			then				
				echo -e '\E[31m owner or group'; echo  "of ${NAME[*]} has changed to $(stat -c "%U:%G" ${NAME[*]})"
				tput sgr0
				chown $OWNU:$OWNG "${NAME[*]}"
				echo "Owner and Group for $FILE restored"
				return_check=1
		fi

		count=$((count-=1))
		unset FILE

	done
	echo -e '\E[32m done'
	tput sgr0
	return $return_check
IFS=$old_IFS
}


list_git()
{

cd $BACKUPDIR 2> /dev/null || return 1
git branch -a
PAGER=cat git log
echo -e '\E[32m done'
tput sgr0
}
