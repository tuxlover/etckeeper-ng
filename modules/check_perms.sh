# module to check for changed permissions and resetting them
# this is bash shell module for keeper.sh
# see install instructions to see how to install and use this and other modules
## State needed experimental
check_perms()
{
# This obsoletes check_perms_S
#${INTERACTIVE:="yes"} 2> /dev/null
#${FROM_CHECK:="no"} 2> /dev/null


# fix problems with german umlauts
# if already set do nothing
git config --global core.quotepath false || :
	
return_check=0
echo "checking Permissions ..."	
perms_changed="no"

count=$(wc -l $BACKUPDIR/content.lst | awk '{print $1}')
old_IFS="$IFS"
IFS=""


# FIXME:
# whenever a file has both changes in permissions and owner
# this loop does not distinguish between them
# and restores all the permissions although the user may not want this
until [ $count -eq 0  ]
	do
		FILE=$(head -n ${count} $BACKUPDIR/content.lst|tail -1)
		NAME=$(echo $FILE|awk '{$1="";$2="";$3="";print}'|awk '{ sub(/^[ \t]+/, ""); print }')
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
				echo -e '\E[31m +++ permissions'; echo "of file ${NAME[*]} has changed to $(stat -c %a ${NAME[*]})"
				tput sgr0
				echo "+++ permissions of file ${NAME[*]} has changed to $(stat -c %a ${NAME[*]})" >> $JOURNAL
				
				if [ "$INTERACTIVE" == "yes" ]
					then
						echo "Restore permission for ${NAME[*]} to $PERMS" 
						echo "\!\! Be careful. if you choose no here these changes gets commited instantly \!\!"
						echo "If you press any other key nothing will happen and the file is left untouched."
						read -e -n 1 -p "y(restore)/n(check in these changes)" ANSWER1
						${ANSWER1:="nope"} 2> /dev/null
					else
						ANSWER1="y"
				fi
				
				if [ $ANSWER1 == "y" ]
					then
						chmod $PERMS "${NAME[*]}"
						echo "++++ permissions for file ${NAME[*]} restored"
						echo "++++ permissions for file ${NAME[*]} restored" >> $JOURNAL
				elif [ $ANSWER1 == "n" ]
					then
						
						rsync -rtpogq -clis -R "${NAME[*]}" $BACKUPDIR
						
						# rewriting the permissions file by rewriting this
						# line with the new permissions
						NPERMS=$(stat -c "%a %U %G %n" "${NAME[*]}")
						sed -i "${count},${count}d" $BACKUPDIR/content.lst
						sed -i -e "${count} i ${NPERMS[*]}" $BACKUPDIR/content.lst
						

						COMMITNAME=${NAME[*]##\/etc\/}
						cd $BACKUPDIR
						git add content.lst
						cd ${BACKUPDIR}etc/
						git add "${COMMITNAME[*]}"
						
						
						echo "++++ permissions for file ${NAME[*]} added to backup." 
						echo "++++ permissions for file ${NAME[*]} added to backup." >> $JOURNAL 
						perms_changed="yes"
					else
						echo "++++ permissions for file ${NAME[*]} left untouched." 
						echo "++++ permissions for file ${NAME[*]} left untouched" >> $JOURNAL
				fi
				return_check=1
		fi
		
		# checking whether the Owner or the Group has changed 
		if [[ "$(stat -c %U ${NAME[*]})" != "$OWNU" || "$(stat -c %G ${NAME[*]})" != "$OWNG" ]]
			then				
				echo -e '\E[31m +++ owner or group'; echo  "of ${NAME[*]} have changed to $(stat -c "%U:%G" ${NAME[*]})"
				tput sgr0
				echo "+++ owner or group if ${NAME[*]} have changed to $(stat -c "%U:%G" ${NAME[*]})" >> $JOURNAL
				
				if [ "$INTERACTIVE" == "yes" ]
					then
						echo "Restore the owner and the Group of the File ${NAME[*]} to $OWNU:$OWNG " 
						echo "\!\! Be careful. if you choose no here these changes gets commited instantly \!\!"
						echo "If you press any other key nothing will happen and the file is left untouched."

						read -e -n 1 -p "y(restore)/n (check in these changes)" ANSWER2
						${ANSWER2:="nope"}	2> /dev/null
					else
						ANSWER2="y"
				fi
				

				if [ $ANSWER2 == "y" ]
					then
						chown $OWNU:$OWNG "${NAME[*]}"
						echo "++++ Owner and Group for $FILE restored"
						echo "++++ Owner and Group for $FILE restored" >> $JOURNAL
				elif [ $ANSWER2 == "n" ]
					then
						
						rsync -rtpogq -clis -R "${NAME[*]}" $BACKUPDIR
						
						# rewriting the permissions file by rewriting this
						# line with the new permissions
						NPERMS=$(stat -c "%a %U %G %n" "${NAME[*]}")
						sed -i "${count},${count}d" $BACKUPDIR/content.lst
						sed -i -e "${count} i ${NPERMS[*]}" $BACKUPDIR/content.lst
					
						COMMITNAME=${NAME[*]##\/etc\/}
						cd $BACKUPDIR
						git add content.lst
						cd ${BACKUPDIR}etc/
						git add "${COMMITNAME[*]}"						
						echo "++++ Owner and Group for file ${NAME[*]} added to backup." 
						echo "++++ Owner and Group for file ${NAME[*]} added to backup." >> $JOURNAL 
						perms_changed="yes"
					else
						echo "++++ Owner and Group for file ${NAME[*]} left untouched." 
						echo "++++ Owner and Group for file ${NAME[*]} left untouched." >> $JOURNAL
				fi
				return_check=1
		fi

		count=$((count-=1))
		unset FILE
		unset ANSWER1
		unset ANSWER2
	done

# we only need to call git when new permissions have checked in
# and we are using the "check" command	because when check is called 
# git gets called later in the main compare_git module
if [[ "$perms_changed" == "yes" && 	"$FROM_CHECK" == "yes" ]]
	then
		DATE=$(date +%F-%H-%M)
		git commit -m "$USER $DATE changed permissions see journal"
fi
return $return_check
IFS="$old_IFS"
}
