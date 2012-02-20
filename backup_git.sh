# to a branched backup
backup_git()
{
# fix problems with german umlauts
# if already set do nothing
git config --global core.quotepath false || :

DATE=$(date +%F-%H-%M)
echo "backup repository ..."
#check if the initial backup exists
if [ ! -s $BACKUPDIR/content.lst ]
	then
		echo "No initial backup found"
		read -p "Would you like to do an initial backup now?(y)" ANSWER
		${ANSWER:="no"} 2> /dev/null
		
		if [ "$ANSWER" != "y"  ]
			then
				echo "use -i option to do an initial backup"
				exit 1
			else
				initial_git && exit 0 || exit  && exit 0 || exit 11
		fi				
fi
# first make sure we are on master
cd $BACKUPDIR
echo "checkout backup directory ..."
git checkout master &> /dev/null

echo "##$DATE" >> $JOURNAL

git_return=0

# check if exluce file exists
if [ ! -e $EXCLUDEFILE ]
	then
		echo "syncing from your current /etc ..."
		rsync -rtpogq --delete -cLis /etc/ $BACKUPDIR/etc/
	else
		echo "syncing from your current /etc ..."
		rsync -rtpogq --delete -cLis --exclude-from=$EXCLUDEFILE --delete-excluded /etc/ $BACKUPDIR/etc/
fi


# then track changed files
# create a helper file which will be deleted afterwards
echo "looking for differences ..."
git_status_file="/tmp/git_status_file"
git status -s > $git_status_file
cat $git_status_file

has_changes="no"

# we do not use cat foo|while read line here because this strarts
# a new subshell
# we are using while read line; do ...;done < <(cat $file) construct
while read line
	do	
		if [ $(echo $line|awk '{print $1}') == "M" 2> /dev/null ]
			then
				has_changes="yes"
				# file has spaces
				mod_file=$(echo $line |awk -F\" '{print $2}')
				# file has no spaces
				mod_file_S=$(echo $line|awk '{print $2}')
				old_IFS=$IFS
				IFS=""
				mod_file="${mod_file[*]}"
				cd $BACKUPDIR
				git add "${mod_file:0}" 2> /dev/null || git add $mod_file_S 2> /dev/null
				
				if [ -z "$mod_file" ]
					then
						echo "++ modified file:"|tee -a $JOURNAL 
						echo "+ $mod_file_S" |tee -a $JOURNAL
					else
						echo "++ modified file:"|tee -a $JOURNAL 
						echo "+ ${mod_file:0}"|tee -a $JOURNAL
				fi
				
				IFS=$old_IFS
					

		elif [ $(echo $line |awk '{print $1}') == "D"  2> /dev/null ]
			then
				has_changes="yes"
				del_file=$(echo $line |awk -F\" '{print $2}'|| echo "no")
				del_file_S=$(echo $line | awk '{print $2}')
				del_file="${del_file[*]}"
				cd $BACKUPDIR
				git rm "${del_file:0}" 2> /dev/null|| git rm $del_file_S 2> /dev/null
				
				if [ -z "$del_file" ]
					then
						echo "++ removed file:"|tee -a $JOURNAL 
						echo "+ $del_file_S"|tee -a $JOURNAL
					else
						echo "++ removed file:"|tee -a $JOURNAL 
						echo "+ ${del_file:0}"|tee -a $JOURNAL
				fi
				
				IFS=$old_IFS
				
				#FIXME: not every line gets matched against this
				if [ grep $del_file $EXCLUDEFILE &> /dev/null ]
					then
						echo "$del_file was excluded by exlcude rule and will be removed from backup"
						
				fi

		elif [ $(echo $line|awk '{print $1}') == "A" 2> /dev/null ]
			then
				has_changes="yes"
				a_file=$(echo $line |awk -F\" '{print $2}')
				a_file_S=$(echo $line|awk '{print $2}')
				if [ -z "$a_file" ]
					then
						echo "++ file was already added:"|tee -a $JOURNAL
						echo "+ $a_file_S"|tee -a $JOURNAL
					else
						echo "++ file was already added:"|tee -a $JOURNAL 
						echo "+ ${a_file:0}"|tee -a $JOURNAL
				fi

		elif [ $(echo $line|awk '{print $1}') == "R" 2> /dev/null ]
			then
				has_changes="yes"
				ren_file=$(echo $line |awk -F\" '{print $2}')
				ren_file_S=$(echo $line|awk '{print $2}')
			
				old_IFS=$IFS
				IFS=""
				ren_file="${ren_file[*]}"
				cd $BACKUPDIR
				git add "${ren_file:0}" 2> /dev/null || git add $ren_file_S 2> /dev/null
				
				if [ -z $ren_file ]
					then
						echo "++ renamed file:"|tee -a $JOURNAL  
						echo "+ $ren_file_S"|tee -a $JOURNAL
					else
						echo "++ renamed file:"|tee -a $JOURNAL 
						echo "+ ${ren_file:0}"|tee -a $JOURNAL
				fi
				
				IFS=$old_IFS

			else
				has_changes="yes"
				new_file=$(echo $line |awk '{$1=""; print}'|awk '{sub(/^[ \t]+/, "")};1')
			
				old_IFS=$IFS
				IFS=""
				new_file="${new_file[*]}"
				cd $BACKUPDIR
				git add "${new_file:0}" 2> /dev/null
				
						echo "++ new file:"|tee -a $JOURNAL 
						echo "+ ${new_file:0}"|tee -a $JOURNAL
				
				IFS=$old_IFS

		fi
	done < <(cat $git_status_file)

if [ $DISABLE_PERMS == "1" ]
		then
			echo "permissions check is deactivated in your configuration file"
			#leave this function without doing anything else
			return_check=0
		else
			check_perms
			return_check=$?
fi

#remove untracked file git_status_file
rm $git_status_file

echo $has_changes
echo $return_check

#create new content file only when files have changed or permissions have changed
return_check=0
if [[ $return_check -eq 1 || $has_changes == "yes" ]]
	then
		#clean up the old content.lst
		cat /dev/null > $BACKUPDIR/content.lst
		find /etc/ -exec stat -c "%a %U %G %n" {} \; >> $BACKUPDIR/content.lst
		git add $BACKUPDIR/content.lst
		has_changes="yes"
fi

if [ $has_changes == "yes" ]  	
	then
		while [ -z "$COMMENT" ]
			do
				echo "please comment your commit and press Enter when finished:"
				read -e COMMENT 
		done

echo "committing files to Backup ..."
echo "# ${COMMENT[*]}" >> $JOURNAL
echo "###" >> $JOURNAL
git commit -m "$USER $DATE ${COMMENT[*]}"
	else
		# if nothing has changed we remove the date string from journal
		sed -i '$d' $JOURNAL
		echo "+++++ nothing changed +++++"
fi
#and return back to master branch to make sure we succeed with no errors
git checkout master &> /dev/null || return 1

echo -e '\E[32m done'
tput sgr0
}
