backup_git_single()
{
DATE=$(date +%F-%H-%M)
git_return=0
# this option requires an argument so write a check whether $OPTARG is NULL and has a valid value
# a valid value is a file or a path in one of the configured directories

# actually this should never happen
if [ -z $OPTARG ]
	then
		echo "Option needs an argument"
		exit 0
fi

# convert OPTARG to a string value
OPTARG="$OPTARG"
# check if we have a starting substring /etc/ and is at leest a substing of a lenght 6th
if [[ ${OPTARG:0:5} != "/etc/" && ! -z ${OPTARG:6:1} ]]
	then
		echo "-f: needs valid path to a file stored in /etc"
		exit 0
	else
		# use read loop to check each line in $EXCLUDEFILE against $OPTARG
		# Stop if such patterns matches
		lines=$(wc -l $EXCLUDEFILE|awk '{print $1}')
	       	until [ "$lines" == 0 ]	
			do
				LINE=$(head -n $lines $EXCLUDEFILE |tail -1)
				HAS_PATTERN=$(echo "$OPTARG"|grep $LINE || echo "no")
				if [ $HAS_PATTERN != "no" ]
					then
						echo "This File has been exluded by exclude pattern:"
						echo "$HAS_PATTERN"
						echo "check $EXCLUDEFILE to correct this."
						echo "will exit now"
						exit 1

				fi
			lines=$((lines-=1))
			done 

		rsync -rtpog -clis $OPTARG $BACKUPDIR/$OPTARG

		# check if file exists in content.lst and if not add it
		awk '{print $1}' $BACKUPDIR/content.lst| grep "^$OPTARG$" &> /dev/null && inlist="yes" || inlist="no"
		
		if [ $inlist == "no" ]
			then
				 stat -c "%n %a %U %G" $OPTARG >> $BACKUPDIR/content.lst
				 git add $BACKUPDIR/content.lst

		fi
fi


cd $BACKUPDIR
git add $BACKUPDIR/$OPTARG

while [ -z "$COMMENT" ]
	        do
			echo "please comment your commit and press Enter when finished:"
			read -e COMMENT
		done

git commit -m "$USER $DATE ${COMMENT[*]}"
# and return back to master branch to make sure we succeed with no errors
git checkout master || return 1
							


# OPTARG than must check if this file exists in one of the supported direcotries 
# those far this is only /etc

# we dont call the check_perms function 
# we test whether this file has changed and if so check in this change
}
