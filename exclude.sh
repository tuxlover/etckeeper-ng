# module for writing exclude patterns to a file
exclude()
{
EXCLUDES=$(echo "$args")

if [ ! -d $BACKUPDIR ]
	then
		mkdir $BACKUPDIR
fi



# checking for already added lines in excludefile 
# by looping over the lines and checking against the input of user
is_arg1=0
for e in ${EXCLUDES[@]}
	do
		# skip the first argument since it is the command itself
		if [ $is_arg1 -eq 0 ]
			then
				is_arg1=1
				continue
		fi
	
		cat $EXCLUDEFILE|while read line
			do
				if [ "/$e" == "$line" ]
					then
						echo "$e matched against a pattern alread added in your $EXCLUDEFILE: will not be added"
						echo "Program will not exclude anything"
						exit 1
					else 
						echo "$line"|grep $e
						if [ $? -eq 0 ]
							then
								echo "$e matched against a pattern alread added in your $EXCLUDEFILE: will not be added"
								echo "Program will not exclude anything"
								exit 1
						fi
				fi
				
			done
			
			# when leaving the read line loop with an exit value of 1 exit the script here
			if [ $? -eq 1 ]
				then 
					exit 1
			fi
			
	done

is_arg1=0	
for e in ${EXCLUDES[@]}	
	do
		
		# skip the first argument since it is the command itself
		if [ $is_arg1 -eq 0 ]
			then
				is_arg1=1
				continue
		fi
	
		# test whether we have any files of a matching pattern
		# if no pattern where matched we dont add this to the exlude file
		if [ $(ls /etc/$e &> /dev/null && echo "yes"|| echo "no") == "no" ]
			then
				echo "$e does not match any file in /etc"
				continue
		fi
			echo "/$e" >> $EXCLUDEFILE
		
	done
	
}
