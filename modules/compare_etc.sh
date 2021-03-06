# module to compare 2 directories and determine changed items in etc
# this is bash shell module for keeper.sh
# see install instructions to see how to install and use this and other modules
## State needed 
compare_etc()
{
# fix problems with german umlauts
# if already set do nothing
git config --global core.quotepath false || :
DATE=$(date +%F-%H-%M)

echo "comparing backup directory with current working /etc directory ..."
#delete old logfile if exising
if [ -f $LOGFILE ]
	then
		rm $LOGFILE
fi

# check if the initial backup exists
if [ ! -s $BACKUPDIR/content.lst ]
	then
		echo "No initial backup found"
		read -p "Would you like to do an initial backup now?(y)" ANSWER
		${ANSWER:="no"} 2> /dev/null
		
		if [ "$ANSWER" != "y"  ]
			then
				echo "use the init command to do an initial backup"
				exit 1
			else
				initial_git && exit 0 || exit  && exit 0 || exit 11
		fi
	else
		echo "checking for exiting comparing directory from unclean termination ..."
		
		# if compare directory already exiists clean up first
		if [ -d $COMPAREDIR ]
			then
				echo "unclean $COMPAREDIR found."
				echo "cleaning up before continue."
				rm -r $COMPAREDIR && suc_clean="yes"
				
		fi
		
		if [[ "$suc_clean" != "yes" && -d $COMPAREDIR ]]
			then
				echo "unable to clean $COMPAREDEAR"
				echo "stopping the script."
				exit 1
		fi
						
		echo "syncing backup directory to comparing directory ..."
		mkdir $COMPAREDIR
		rsync -rtpogq --delete -clis $BACKUPDIR $COMPAREDIR
		echo "syncing working directory to comparing directory ..."	
		rsync -rtpogq --delete -clis --exclude-from=$EXCLUDEFILE /etc/ $COMPAREDIR/etc/
fi

cd $COMPAREDIR
git checkout master &> /dev/null

echo "##$DATE" >> $JOURNAL

echo "looking for differences ..."
git_status_file="/tmp/git_status_file"
git status -s > $git_status_file

has_changes="no"
while read line
	do	
		if [ $(echo $line|awk '{print $1}') == "M" 2> /dev/null ]
			then
				has_changes="yes"
				# in case file has spaces
				mod_file=$(echo $line |awk -F\" '{print $2}')
				# in case the file has no spaces
				mod_file_S=$(echo $line|awk '{print $2}')
				old_IFS=$IFS
				IFS=""
				mod_file="${mod_file[*]}"				
				if [ -z "$mod_file" ]
					then
						echo "++ modified file:" 
						echo "+ $mod_file_S"
					else
						echo "++ modified file:" 
						echo "+ ${mod_file:0}"
				fi				
				IFS=$old_IFS

		elif [ $(echo $line|awk '{print $1}') == "D"  2> /dev/null ]
			then
				has_changes="yes"
				# in case file name has spaces
				del_file=$(echo $line |awk -F\" '{print $2}')
				# in case file name has no spaces
				del_file_S=$(echo $line|awk '{print $2}')
				
				old_IFS=$IFS
				IFS=""
				del_file="${del_file[*]}"
				if [ -z "$del_file" ]
					then
						echo "++ deleted file:"
						echo "+ $del_file_S"
					else
						echo "++ deleted file:"
						echo "+ ${del_file:0}"
				fi
				IFS=$old_IFS



		elif [$(echo $line|awk '{print $1}') == "R" 2> /dev/null ]
			then
				has_changes="yes"
				# in case file name has spaces
				ren_file=$(echo $line |awk -F\" '{print $2}')
				# in case file name has no spaces
				ren_file_S=$(echo $line|awk '{print $2}')
				
				old_IFS=$IFS
				IFS=""
				ren_file="${ren_file[*]}"
				if [ -z "$ren_file" ]
					then
						echo "++ renamed file:"
						echo "+ $ren_file_S"
					else
						echo "++ renamed file:"
						echo "+ ${ren_file:0}"
				fi
				IFS=$old_IFS

		else
				has_changes="yes"
				new_file=$(echo $line |awk '{$1=""; print}'|awk '{sub(/^[ \t]+/, "")};1')
				old_IFS=$IFS
				IFS=""
				new_file="${new_file[*]}"
				echo "++ new file:" 
				echo "+ ${new_file:0}"
				old_IFS=$IFS

				# TODO: print new files here and log to $LOGFILE
			
		fi
	done < <(cat $git_status_file)

echo "writing logfile ..."
PAGER=cat git diff --src-prefix="Backup:/" --dst-prefix="Current:/" $COMPAREDIR >> $LOGFILE
if [ ! -s $LOGFILE ]
	then
		rm $LOGFILE
fi

#function was here
return_check=0
if [ "$DISABLE_PERMS" == "1" ]
		then
			echo "permissions check is deactivated in your configuration file"
			# leave this function without doing anything else
			return_check=0
		else
			FROM_CHECK="yes"
			INTERACTIVE="yes"
			check_perms
			return_check=$?
		
		#assuming permissions have changed and therefore we most check in content.lst
		# before we can continue	
		if [ $return_check -ne 0  ]
			then
				git add  $BACKUPDIR/content.lst
				git commit -m "$USER $DATE changed permissions"
		fi
fi

#missing subroutine for writing new content.lst

echo "$has_changes"					
echo "cleaning up ..."
rm -rf $COMPAREDIR 
rm $git_status_file

if [[ $has_changes == "no" && "$perms_changed" == "no" ]]
	then
		echo "+++++ nothing changed +++++"
fi		

echo "# check done" >>	$JOURNAL

if [ "$perms_changed" != "yes" ]
	then
		echo "++ Permissions changed" >> $JOURNAL
fi	

echo "###" >> $JOURNAL		

echo -e '\E[32m done'
tput sgr0
}
