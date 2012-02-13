# to a branched backup
backup_git()
{

DATE=$(date +%F-%H-%M)
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
git checkout master &> /dev/null

git_return=0
check_perms
return_check=$?
set_mod=0
set_del=0
set_add=0
set_ren=0
set_new=0

# check if exluce file exists
if [ ! -e $EXCLUDEFILE ]
	then
		rsync -rtpogq --delete -clis /etc/ $BACKUPDIR/etc/
	else
		rsync -rtpogq --delete -clis --exclude-from=$EXCLUDEFILE --delete-excluded /etc/ $BACKUPDIR/etc/
fi


# then track changed files
# create a helper file which will be deleted afterwards
git_status_file="/tmp/git_status_file"
git status -s > $git_status_file
lof=$(wc -l $git_status_file|awk '{print $1}')
until  [ "$lof" == 0  ]
	do	
		if [ $(tail -n $lof $git_status_file|head -1|awk '{print $1}') == "M" 2> /dev/null ]
			then
				mod_file=$(tail -n $lof $git_status_file|head -1|awk '{print $2}')
				echo "modified file: $mod_file"
				git add $mod_file
					
					if [ $set_mod  -eq 0 ]
						then
							return_check=$((return_check+=2 ))
							set_mod=1
					fi			

		elif [ $(tail -n $lof $git_status_file|head -1|awk '{print $1}') == "D"  2> /dev/null ]
			then
				del_file=$(tail -n $lof $git_status_file|head -1|awk '{print $2}')
				echo "deleted file: $del_file"
				
				if [ grep $del_file $EXCLUDEFILE &> /dev/null ]
					then
						echo "$del_file was excluded by exlcude rule and will be removed from backup"
				fi
					git rm $del_file
				
				if [ $set_del -eq 0 ]
					then
						return_check=$((return_check+=4 ))
						set_del=1
				fi


		elif [ $(tail -n $lof $git_status_file|head -1|awk '{print $1}') == "A" 2> /dev/null ]
			then
				a_file=$(tail -n $lof $git_status_file|head -1|awk '{print $2}')
				echo "file was allready added: $a_file"

				if [ $set_add -eq 0 ]
					then
						return_check=$((return_check+=8 ))
						set_add=1
				fi


		elif [$(tail -n $lof $git_status_file|head -1|awk '{print $1}') == "R" 2> /dev/null ]
			then
				ren_file=$(tail -n $lof $git_status_file|head -1|awk '{print $2}')
				echo "renamed file: $ren_file"
				git add $ren_file

				if [ $set_ren -eq 0 ]
					then
						return_check=$((return_check+=16 ))
						set_ren=1
				fi

			else
				new_file=$(tail -n $lof $git_status_file|head -1|awk '{print $2}')
				echo "new file: $new_file"
				git add $new_file
				
				if [ $set_new -eq 0 ]
					then
						return_check=$((return_ceck+=32 ))
						set_new=1
				fi

		fi
		lof=$((lof-=1 ))
	done

echo "Check Code is $return_check"
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
	
git commit -m "$USER $DATE ${COMMENT[*]}"

#and return back to master branch to make sure we succeed with no errors
git checkout master &> /dev/null || return 1			
}
