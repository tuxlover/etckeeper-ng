# module to check for changed permissions and resetting them
# this is bash shell module for keeper.sh
# see install instructions to see how to install and use this and other modules
## State needed development
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
                                echo "+++ $FILE was listed but is not present in your filesystem."|tee  -a $JOURNAL
                                #remember skipped lines for later deletition
                                sed -i "${count},${count}d" $BACKUPDIR/content.lst
                                cd $BACKUPDIR
                                git add content.lst
                                echo "++ deleted" | tee -a $JOURNAL
                                perms_changed="yes"
				continue
		fi

	       # cheking whether the Permissions have changed
		if [ "$(stat -c %a ${NAME[*]})" != "$PERMS"  ]
			then	
				return_check=1
				per_changed="y"
				echo -e '\E[31m +++ permissions'; echo "of file ${NAME[*]} has changed to $(stat -c %a ${NAME[*]})"
				tput sgr0
				echo "+++ permissions of file ${NAME[*]} has changed to $(stat -c %a ${NAME[*]})" >> $JOURNAL
				
				if [ "$INTERACTIVE" == "yes" ]
					then
						echo "Restoring permission for ${NAME[*]} to $PERMS" 
						echo "\!\! Be careful. if you choose no here these changes gets commited instantly \!\!"
						echo "If you press any other key nothing will happen and the file is left untouched."
						read -e -n 1 -p "y(restore)/n(check in these changes)" ANSWER1
						${ANSWER1:="nope"} 2> /dev/null
					else
						ANSWER1="y"
				fi

		fi

		# checking whether the user name has changed
                if [ "$(stat -c %U ${NAME[*]})" != "$OWNU" ]
			then
				return_check=1
				own_changed="y"
				echo -e '\E[31m +++ owner'; echo "of ${NAME[*]} has changed to $(stat -c %U ${NAME[*]})"
				tput sgr0
				echo "+++ owner of ${NAME[*]} has changed to $(stat -c %U ${NAME[*]})" >> $JOURNAL

				if [ "$INTERACTIVE" == "yes" ]
					then
						echo "Restoring the owner of the File ${NAME[*]} to $OWNU" 
						echo "\!\! Be careful. if you choose no here these changes gets commited instantly \!\!"
						echo "If you press any other key nothing will happen and the file is left untouched."
						
						read -e -n 1 -p "y(restore)/n (check in these changes)" ANSWER2
						${ANSWER2:="nope"}	2> /dev/null
					else
						ANSWER2="y"
				fi 
		fi

		# checking whether the group has changed
                if [ "$(stat -c %G ${NAME[*]})" != "$OWNG" ]
			then
				return_check=1
				grp_changed="y"
				echo -e '\E[31m +++ group'; echo "of ${NAME[*]} has changed to $(stat -c %G ${NAME[*]})"
				tput sgr0
				echo "+++ group of ${NAME[*]} has changed to $(stat -c %G ${NAME[*]})" >> $JOURNAL

				if [ "$INTERACTIVE" == "yes" ]
					then
						echo "Restoring the group of the File ${NAME[*]} to $OWNU" 
						echo "\!\! Be careful. if you choose no here these changes gets commited instantly \!\!"
						echo "If you press any other key nothing will happen and the file is left untouched."
						
						read -e -n 1 -p "y(restore)/n (check in these changes)" ANSWER3
						${ANSWER3:="nope"}	2> /dev/null
					else
						ANSWER3="y"
				fi 
		fi

		# checking for answers
		# checking for ANSWER1 perms
		if [[ $per_changed == "y" && $ANSWER1 == "y" ]]
			then
				chmod $PERMS "${NAME[*]}"
				echo "++++ permissions for file ${NAME[*]} restored" | tee -a $JOURNAL
		elif [[ $per_changed == "y" && $ANSWER1 == "n" ]]
			then
				we_change="y"
		elif [[ $per_changed == "y" && $ANSWER1 == "nope" ]]
			then
			 
				echo "++++ permissions for file ${NAME[*]} left untouched" | tee -a $JOURNAL
		fi

		# checking for ANSWER2 owner
		if [[ $own_changed == "y" && $ANSWER2 == "y" ]]
			then
				chown $OWNU "${NAME[*]}"
				echo "++++ Owner for $FILE restored" | tee -a $JOURNAL
		elif [[ $own_changed == "y" && $ANSWER2 == "n" ]]
			then
				we_change="y"
		elif [[ $own_changed == "y" && $ANSWER2 == "nope" ]]
			then
				echo "++++ Owner and Group for file ${NAME[*]} left untouched." | tee -a $JOURNAL
		fi
		
		
		# checking for ANSWER3 group
		if [[ $grp_changed == "y" && $ANSWER3 == "y" ]]
			then
				chown :${OWNG} "${NAME[*]}"
				echo "++++ Group for $FILE restored" | tee -a $JOURNAL
		elif [[ $grp_changed == "y" && $ANSWER3 == "n" ]]
			then
				we_change="y"
		elif [[ $grp_changed == "y" && $ANSWER3 == "nope" ]]
			then
				echo "++++ Owner and Group for file ${NAME[*]} left untouched." | tee -a $JOURNAL
		fi

		if [[ -n $we_change && $we_change == "y" ]]
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
				echo "++++ Owner and Group for file ${NAME[*]} added to backup."| tee -a $JOURNAL 
				perms_changed="yes"
		fi 

		count=$((count-=1))
		unset FILE
		unset ANSWER1
		unset ANSWER2
		unset ANSWER3
		unset we_change
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
