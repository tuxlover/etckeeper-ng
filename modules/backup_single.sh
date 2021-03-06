# module to backup only one single file
# this is bash shell module for keeper.sh
# see install instructions to see how to install and use this and other modules
## State needed

backup_single()
{	
echo "add single files ..."
DATE=$(date +%F-%H-%M)

old_IFS=$IFS
IFS=""

# fix problems with german umlauts
# if already set do nothing
git config --global core.quotepath false || :

arg="${arg[*]}"

# check if we have a starting substring /etc/ and /etc/ is at least a substring with length 6th
# this should prevent an empty data or including the whole /etc directory
if [[ ${arg:0:5} != "/etc/" && ! -z ${arg:6:1}  ]]
	then
		echo "add: need a valid path to a file stored in /etc"
		exit 1
	else
		cat $EXCLUDEFILE|while read line
			do
				HAS_PATTERN=$(echo "$arg"|grep $line || echo "no")
				if [ $HAS_PATTERN != "no" ]
					then
						echo "This file has been excluded by an exclude pattern:"
						echo "$HAS_PATTERN"
						
						# checking whether we add the file to our content.lst
						awk '{$1="";$2="";$3="";print}' $BACKUPDIR/content.lst|awk '{ sub(/^[ \t]+/, ""); print }'|grep "^${arg[*]}$" &> /dev/null && INLIST="yes" || INLIST="no"
						
						if [ $inlist == "no" ]
							then
								stat -c "%a %U %G %n" "${arg[*]}" >> $BACKUPDIR/content.lst
								cd $BACKUPDIR
								git add $BACKUPDIR/content.lst
								echo "but will be  added to your content.lst "
								cd $BACKUPDIR
								git commit -m "$USER $DATE ${arg[*]} added to content.lst"
								# and return back to master branch to make sure we succeed with no errors
								git checkout master &> /dev/null || return 1
								echo -e '\E[32m done'
                                                                echo "##$DATE" >> $JOURNAL
                                                                echo "++ updated your content.lst" >> $JOURNAL
                                                                echo "###" >> $JOURNAL
								tput sgr0
						fi
					exit 1
				fi
			done
fi
	
					
# checking if our file actualy exists	
if [ ! -f ${arg[*]} ]
	then
		echo "WARNING: ${arg[*]} does not exists in /etc"
		exit 1
	else
			rsync -rtpogq -clis "$arg" "${BACKUPDIR}${arg:1}"
			cd $BACKUPDIR
			git add "${arg:1}"

			# check if file exists in content.lst and if not add it
			awk '{$1="";$2="";$3="";print}' $BACKUPDIR/content.lst|awk '{ sub(/^[ \t]+/, ""); print }'|grep "^${arg[*]}$" &> /dev/null && INLIST="yes" || INLIST="no"
		
			if [ $INLIST == "no" ]
				then
					stat -c "%a %U %G %n" "${arg[*]}" >> $BACKUPDIR/content.lst
					git add $BACKUPDIR/content.lst

			fi
fi

echo "commiting single file $arg to backup ..."
cd $BACKUPDIR


while [ -z "$COMMENT" ]
	    do
			echo "please comment your commit and press Enter when finished:"
			read -e COMMENT
		done

git commit -m "$USER $DATE ${COMMENT[*]}" && git_suc="yes"

# only write entries to journal when successfully added
if [ "$git_suc" == "yes" ]
	then
	echo "##$DATE" >> $JOURNAL
	echo "++ single file:" >> $JOURNAL
	echo "+ added $arg" >> $JOURNAL
	echo "#${Comment[*]}" >> $JOURNAL
	git_suc="no"
fi

# and return back to master branch to make sure we succeed with no errors
git checkout master &> /dev/null || return 1
IFS=$old_IFS
echo -e '\E[32m done'
tput sgr0
}
