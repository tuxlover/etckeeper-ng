# module for writing exclude patterns to a file
# this is bash shell module for keeper.sh
# see install instructions to see how to install and use this and other modules
## State needed 
exclude()
{
echo "excluding files from next backup ..."
EXCLUDES=$(echo "$arg")
DATE=$(date +%F-%H-%M)
new_exludes="no"

if [ ! -d $BACKUPDIR ]
	then
		mkdir $BACKUPDIR
fi

# checking whether we have an exclude file 
# if not create it here	
if [ ! -e $EXCLUDEFILE ]	
	then
		touch $EXCLUDEFILE
		cd $BACKUPDIR
                if [ -d $BACKUPDIR/.git  ]
                    then
		        git add $EXCLUDEFILE
		        git commit -m "initial creation of excludefile"
                fi
fi

# checking for already added lines in excludefile 
# by looping over the lines and checking against the input of user
echo "checking your arguments ..."
for e in ${EXCLUDES[@]}
	do

# first check against the /$e pattern 
# and check against ${e:4}
# we do not use double brackets here because we are getting globbing
# pattern maching against a file so we are turning this off

	while read line
			do
				if [ "/$e" == "$line" ]
					then
						echo "$e matched against a pattern alread added in your $EXCLUDEFILE: will not be added"
						echo "Program will not exclude anything"
						exit 1
				# when enclosed in double brackets this gets not evaluated
				# rather than in single brackets
				elif [[ "${e:4}" == "$line" ]]
					then
						echo "$e matched against a pattern alread added in your $EXCLUDEFILE: will not be added"
						echo "Program will not exclude anything"
						exit 1
					else 
						echo "$line"|grep "$e"
						if [ $? -eq 0 ]
							then
								echo "$e matched against a pattern alread added in your $EXCLUDEFILE: will not be added"
								echo "Program will not exclude anything"
								exit 1
						fi

						if [[ "${e:0:4}" == "/etc"  ]]
						then
							echo "$line"|grep "\'${e:4}\'"
							if [ $? -eq 0 ]
								then
									echo "$e matched against a pattern alread added in your $EXCLUDEFILE: will not be added"
									echo "Program will not exclude anything"
									exit 1
							fi
						fi
				fi		
			done < <(cat $EXCLUDEFILE)
			
			# when leaving the read line loop with an exit value of 1 exit the script exits here
			if [ $? -eq 1 ]
				then 
					exit 1
			fi
			
done
	
for e in ${EXCLUDES[@]}	
	do
		
	
		# test whether we have any files of a matching pattern
		# if no pattern where matched we dont add this to the exlude file
		if [[ ${e:0:5} == "/etc/" && $(ls $e &> /dev/null && echo "yes"|| echo "no") == "yes" ]]
			then
				# only relative paths are accepted by rsync
				# so we are cutting of "/etc" from this pattern
				echo "$e: writing exclude pattern to exclude file ..."
				echo "${e:4}" >> $EXCLUDEFILE
				pattern[$count]=$(echo ${e:4}) 
				count=$((count+=1))
				
				new_excludes="yes"
				continue
		fi
			
		
		if [ $(ls /etc/$e &> /dev/null && echo "yes"|| echo "no") == "no" ]
			then		
				echo "$e does not match any file in /etc"
				continue
		fi
		
			echo "$e: writing exclude pattern to exclude file ..."
			echo "/$e" >> $EXCLUDEFILE
			new_excludes="yes"
			pattern[$count]=$(echo "/$e")
			count=$((count+=1))
		
	done

if [ "$new_excludes" == "yes" ]
	then
		cd $BACKUPDIR
                if [ -d $BACKUPDIR/.git  ]
                    then
		        git add $EXCLUDEFILE
		        git commit -m "$DATE $USER new exclude patterns were written to exclude file"
                    else
                       echo "It seems there is no initial backup created yet."
                       echo "don't forget to create one by using keeper init"
                fi
fi

#writing Information to the Journal
if [ "$new_excludes" == "yes" ]
	then
		echo "##$DATE" >> $JOURNAL
		echo "++ exclude patterns were written to exclude file" >> $JOURNAL
		
		for p in ${pattern[@]}	
			do
				echo "+ $p" >> $JOURNAL
	
			done
		echo "###" >> $JOURNAL
fi

echo -e '\E[32m done'
tput sgr0	
}
