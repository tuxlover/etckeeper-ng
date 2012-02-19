check_perms()
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
		NAME=$(echo $FILE|awk '{$1="";$2="";$3="";print}'|awk '{ sub(/^[ \t]+/, ""); print }')
		PERMS=$(echo $FILE|awk '{print $1}')
		OWNU=$(echo $FILE|awk '{print $2}')
		OWNG=$(echo $FILE|awk '{print $3}')
		
	#if a file is not present, skip test
		if [ ! -e "${NAME[*]}" ]
			then
				count=$((count-=1))
				continue
		fi
	
	#cheking whether the Permissions have changed
		if [ "$(stat -c %a ${NAME[*]})" != "$PERMS"  ]
			then	
				echo -e '\E[31m +++ permissions'; echo "of file ${NAME[*]} has changed to $(stat -c %a ${NAME[*]})"
				tput sgr0
				echo "+++ permissions of file ${NAME[*]} has changed to $(stat -c %a ${NAME[*]})" >> $JOURNAL
				echo "Restore permission for ${NAME[*]} to $PERMS" 
				read -e -n 1 -p	"y(restore)/n(check in these changes)" ANSWER1
				{$ANSWER1:="n"} 2> /dev/null
				
				if [ $ANSWER1 == "y" ]
					then
						chmod $PERMS "${NAME[*]}"
						echo "++++ permissions for file ${NAME[*]} restored"
						echo "++++ permission for file ${NAME[*]} restored" >> $JOURNAL
				fi
				return_check=1
		fi
		
	#checking whether the Owner or the Group has changed 
		if [[ "$(stat -c %U ${NAME[*]})" != "$OWNU" || "$(stat -c %G ${NAME[*]})" != "$OWNG" ]]
			then				
				echo -e '\E[31m +++ owner or group'; echo  "of ${NAME[*]} have changed to $(stat -c "%U:%G" ${NAME[*]})"
				tput sgr0
				echo "+++ owner or group if ${NAME[*]} have changed to $(stat -c "%U:%G" ${NAME[*]})" >> $JOURNAL
				
				echo "Restore the owner and the Group of the File ${NAME[*]} to $OWNU:$OWNG " 
				read -e -n 1 -p	"y(restore)/n (check in these changes)" ANSWER2
				{$ANSWER2:="n"}	2> /dev/null
				
				if [ $ANSWER2 == "y" ]
					then
					chown $OWNU:$OWNG "${NAME[*]}"
					echo "++++ Owner and Group for $FILE restored"
					echo "++++ Owner and Group for $FILE restored" >> $JOURNAL
				fi
				return_check=1
		fi

		count=$((count-=1))
		unset FILE
		unset ANSWER1
		unset ANSWER2
	done
	return $return_check
IFS=$old_IFS
}
