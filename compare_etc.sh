compare_etc()
{
# fix problems with german umlauts
# if already set do nothing
git config --global core.quotepath false || :

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
		echo "syncinc backup dirctory to comparing directory ..."
		mkdir $COMPAREDIR
		rsync -rtpogq --delete -clis $BACKUPDIR $COMPAREDIR
		echo "syncing working directory to comparing directory ..."	
		rsync -rtpogq --delete -clis --exclude-from=$EXCLUDEFILE /etc/ $COMPAREDIR/etc/
fi

return_check=0
check_perms
return_check=$?
set_mod=0
set_del=0
set_add=0
set_ren=0
set_new=0

cd $COMPAREDIR
git checkout master &> /dev/null

echo "looking for differences ..."
git_status_file="/tmp/git_status_file"
git status -s > $git_status_file
lof=$(wc -l $git_status_file|awk '{print $1}')
until  [ "$lof" == 0  ]
	do	
		if [ $(tail -n $lof $git_status_file|head -1|awk '{print $1}') == "M" 2> /dev/null ]
			then
				mod_file=$(tail -n $lof $git_status_file|head -1|awk '{print $2}')
				echo "modified file: $mod_file"
				
				if [ $set_mod -eq 0 ]
					then
						return_check=$((return_check+=2))
						set_mod=1
				fi


		elif [ $(tail -n $lof $git_status_file|head -1|awk '{print $1}') == "D"  2> /dev/null ]
			then
				del_file=$(tail -n $lof $git_status_file|head -1|awk '{print $2}')
				echo "deleted file: $del_file"
				
				if [ $set_del -eq 0 ]
					then
						return_check=$((return_check+=4))
						set_del=1
				fi


		elif [ $(tail -n $lof $git_status_file|head -1|awk '{print $1}') == "A" 2> /dev/null ]
			then
				a_file=$(tail -n $lof $git_status_file|head -1|awk '{print $2}')
				echo "file was allready added: $a_file"
				
				if [ $set_add -eq 0 ]
					then
						return_check=$((return_check+=8))
						set_add=1
				fi

		elif [$(tail -n $lof $git_status_file|head -1|awk '{print $1}') == "R" 2> /dev/null ]
			then
				ren_file=$(tail -n $lof $git_status_file|head -1|awk '{print $2}')
				echo "renamed file: $ren_file"		

				if [ $set_ren -eq 0 ]
					then
						return_check=$((return_check+=16))
						set_ren=1
				fi


		else
				new_file=$(tail -n $lof $git_status_file|head -1|awk '{print $2}')
				echo "new file: $new_file"

				if [ $set_new -eq 0 ]
					then
						return_check=$((return_check+=32))
						set_new=1
				fi

				# TODO: print new files here and log to $LOGFILE
			
		fi
		lof=$((lof-=1))
	done

	return_array=(32 16 8 4 2 1 0)
	has_mod=$return_check

	for i in ${return_array[@]}
		do
			if [ $return_check -eq $i ]
				then

					if [ $i -eq 2  ]
						then
							echo "writing logfile ..."
							PAGER=cat git diff --src-prefix="Backup:/" --dst-prefix="Current:/" $COMPAREDIR >> $LOGFILE
					fi
					break
								
			elif [ $return_check -gt $i ]	
				then
					has_mod=$((has_mod - $i))
				
					if [ $i -eq 2  ]
						then
							echo "writing logfile ..."
							PAGER=cat git diff --src-prefix="Backup:/" --dst-prefix="Current:/" $COMPAREDIR >> $LOGFILE
					fi
			fi
		done
						
echo "cleaning up ..."
rm -rf $COMPAREDIR 
rm $git_status_file
echo -e '\E[32m done'
tput sgr0
}
