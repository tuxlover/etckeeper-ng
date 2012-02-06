# module for writing exclude patterns to a file
exclude()
{
EXCLUDES=$(echo "$args")

if [ ! -d $BACKUPDIR ]
	then
		mkdir $BACKUPDIR
fi

is_arg1=0

for e in ${EXCLUDES}	
	do
		
		# skip the first argument since it is the command itself
		if [ $is_arg1 -eq 0 ]
			then
				is_arg1=1
				continue
		fi
	
		# test whether we have any files of a matching pattern
		# if no pattern where matched we dont add this to the exlude file
		is_valid_exclude=$(ls /etc/$e &> /dev/null && echo "yes"|| echo "no")
		if [ "$is_vaild_exclude" == "no" ]
			then
				echo "$e does not match any file"
				continue
		fi
			echo "/$e" >> $EXCLUDEFILE
	done
	
}
