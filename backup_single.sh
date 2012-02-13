backup_single()
{
	

DATE=$(date +%F-%H-%M)
is_arg1=0

for i in $args
	do
		# convert the ith postion in an actual string value
		i="$i"
		

		#skip the first argument since it is the command itself
		if [ $is_arg1 -eq 0 ]
			then
				is_arg1=1
				continue
		fi
		
		# check if we have a starting substring /etc/ and is at least a substring of a length 6th
		# this will prevent an empty data or including the whole /etc directory
		if [[ ${i:0:5} != "/etc/" && ! -z ${i:6:1} ]]
			then
				echo "add: needs valid path to a file stored in /etc"
				exit 0
				
			else 
				# used to read loop to check each line  in $EXCLUDEFILE against args
				# stop if such patterns matches
				lines=$(wc -l $EXCLUDEFILE|awk '{print $1}')
				until [ "$lines" == 0 ]
					do
						LINE=$(head -n $lines $EXCLUDEFILE |tail -1)
						HAS_PATTERN=$(echo "$i"|grep $LINE || echo "no")
												
						if [ $HAS_PATTERN != "no" ]
							then
								echo "This File has been exluded by exclude pattern:"
								echo "$HAS_PATTERN"
								
								awk '{print $1}' $BACKUPDIR/content.lst| grep "^$i$" &> /dev/null && inlist="yes" || inlist="no"
		
								if [ $inlist == "no" ]
									then
										stat -c "%n %a %U %G" $i >> $BACKUPDIR/content.lst
										cd $BACKUPDIR
										git add $BACKUPDIR/content.lst
										echo "but will be  added to your content.lst "
										cd $BACKUPDIR
										git commit -m "$USER $DATE $i added to content.lst"
										# and return back to master branch to make sure we succeed with no errors
										git checkout master &> /dev/null || return 1
								fi
										
								
							exit 1

						fi
						
						lines=$((lines-=1))
					done
			
			
			# checking if our file actualy exists	
			if [ ! -f $i ]
				then
					echo "WARNING: $i does not exists in /etc"
					continue
			fi
			
			rsync -rtpogq -clis $i $BACKUPDIR/$i

			# check if file exists in content.lst and if not add it
			awk '{print $1}' $BACKUPDIR/content.lst| grep "^$i$" &> /dev/null && inlist="yes" || inlist="no"
		
			if [ $inlist == "no" ]
				then
					stat -c "%n %a %U %G" $i >> $BACKUPDIR/content.lst
					git add $BACKUPDIR/content.lst

			fi
		fi


done

cd $BACKUPDIR
git add $BACKUPDIR/$i

while [ -z "$COMMENT" ]
	        do
			echo "please comment your commit and press Enter when finished:"
			read -e COMMENT
		done

git commit -m "$USER $DATE ${COMMENT[*]}"
# and return back to master branch to make sure we succeed with no errors
git checkout master &> /dev/null || return 1
}
