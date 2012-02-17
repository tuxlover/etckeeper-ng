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

git_return=0

if [ $DISABLE_PERMS == "1" ]
		then
			echo "permissions check is deactivated in your configuration file"
			#leave this function without doing anything else
		else
			check_perms
fi

# check if exluce file exists
if [ ! -e $EXCLUDEFILE ]
	then
		echo "syncing from your current /etc ..."
		rsync -rtpogq --delete -clis /etc/ $BACKUPDIR/etc/
	else
		echo "syncing from your current /etc ..."
		rsync -rtpogq --delete -clis --exclude-from=$EXCLUDEFILE --delete-excluded /etc/ $BACKUPDIR/etc/
fi


# then track changed files
# create a helper file which will be deleted afterwards
echo "looking for differences ..."
git_status_file="/tmp/git_status_file"
git status -s > $git_status_file
cat $git_status_file

cat $git_status_file|while read line
	do	
		if [ $(echo $line|awk '{print $1}') == "M" 2> /dev/null ]
			then
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
						echo "modified file:" 
						echo "$mod_file_S"
					else
						echo "modified file:" 
						echo "${mod_file:0}"
				fi
				
				IFS=$old_IFS
					
					if [ $set_mod  -eq 0 ]
						then
							return_check=$((return_check+=2 ))
							set_mod=1
					fi			

		elif [ $(echo $line |awk '{print $1}') == "D"  2> /dev/null ]
			then
				del_file=$(echo $line |awk -F\" '{print $2}'|| echo "no")
				del_file_S=$(echo $line | awk '{print $2}')
				del_file="${del_file[*]}"
				cd $BACKUPDIR
				git rm "${del_file:0}" 2> /dev/null|| git rm $del_file_S 2> /dev/null
				
				if [ -z "$del_file" ]
					then
						echo "removed file:" 
						echo "$del_file_S"
					else
						echo "removed file:" 
						echo "${del_file:0}"
				fi
				
				IFS=$old_IFS
				
				#FIXME: not every line gets matched against this
				if [ grep $del_file $EXCLUDEFILE &> /dev/null ]
					then
						echo "$del_file was excluded by exlcude rule and will be removed from backup"
						
				fi

		elif [ $(echo $line|awk '{print $1}') == "A" 2> /dev/null ]
			then
				a_file=$(echo $line |awk -F\" '{print $2}')
				a_file_S=$(echo $line|awk '{print $2}')
				if [ -z "$a_file" ]
					then
						echo "file was already added:"
						echo "$a_file_S"
					else
						echo "file was already added:" 
						echo "${a_file:0}"
				fi

		elif [ $(echo $line|awk '{print $1}') == "R" 2> /dev/null ]
			then
				ren_file=$(echo $line |awk -F\" '{print $2}')
				ren_file_S=$(echo $line|awk '{print $2}')
			
				old_IFS=$IFS
				IFS=""
				ren_file="${ren_file[*]}"
				cd $BACKUPDIR
				git add "${ren_file:0}" 2> /dev/null || git add $ren_file_S 2> /dev/null
				
				if [ -z $ren_file ]
					then
						echo "renamed file:" 
						echo "$ren_file_S"
					else
						echo "renamed file:" 
						echo "${ren_file:0}"
				fi
				
				IFS=$old_IFS

			else
				new_file=$(echo $line |awk '{$1=""; print}'|awk '{sub(/^[ \t]+/, "")};1')
			
				old_IFS=$IFS
				IFS=""
				new_file="${new_file[*]}"
				cd $BACKUPDIR
				git add "${new_file:0}" 2> /dev/null
				
						echo "new file:" 
						echo "${new_file:0}"
				
				IFS=$old_IFS

		fi
	done

#remove untracked file git_status_file
rm $git_status_file

#create new content file only when new files were added or permissions have changed
if [[ $return_check -eq 1 || $return_check -ge 32 ]]
	then
		#clean up the old content.lst
		cat /dev/null > $BACKUPDIR/content.lst
		find /etc/ -exec stat -c "%n %a %U %G" {} \; >> $BACKUPDIR/content.lst
		git add $BACKUPDIR/content.lst
fi
		
while [ -z "$COMMENT" ]
	do
		echo "please comment your commit and press Enter when finished:"
		read -e COMMENT 
	done

echo "committing files to Backup ..."
git commit -m "$USER $DATE ${COMMENT[*]}"

#and return back to master branch to make sure we succeed with no errors
git checkout master &> /dev/null || return 1			

echo -e '\E[32m done'
tput sgr0
}
