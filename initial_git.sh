#module for the first initalisation
# do the initial backup
initial_git()
{

DATE=$(date +%F-%H-%M)

#check if an older backup already exists
if [ -s $BACKUPDIR/content.lst  ]
	then
		read -p "it seems there already exists an backup. overwrite?(y)" ANSWER
		${ANSWER:="no"} 2> /dev/null
		
		if [ "$ANSWER" != "y" ]
			then
				echo "use backup command to commit new backup branch"
				exit 1
			else
				rm -rf $BACKUPDIR/
		fi
fi

# configure the gloabel git  if already set do nothing
git config --global user.name "$USER" 2> /dev/null || :
git config --global user.email "$USER@$HOSTNAME" 2> /dev/null || :

if [ ! -d $BACKUPDIR ]
	then	
		mkdir -p $BACKUPDIR	
		find /etc/ -exec stat -c "%n %a %U %G" {} \; >> $BACKUPDIR/content.lst

	else
		find /etc/ -exec stat -c "%n %a %U %G" {} \; >> $BACKUPDIR/content.lst		
fi

mkdir $BACKUPDIR/etc
# check wheter we have an excludefile
if [ ! -e $EXCLUDEFILE ]
	then
		echo "WARNING: there was no exlcudefile setup, so i exclude nothing"
		echo "WARNING: Use \"exclude\" to wirte a list of filese that will be excluded"
		echo "WARNING: it is highly recommended that you first define what should be exluded"
		sleep 10

		# create empty excludefile
		touch $EXCLUDEFILE
		rsync -rtpog --delete -clis /etc/ $BACKUPDIR/etc
	else
		
		rsync -rtpog --delete -clis --exclude-from=$EXCLUDEFILE --delete-excluded /etc/ $BACKUPDIR/etc
fi

while [ -z "$COMMENT" ]
	do
		echo "please comment your commit and press Enter when finished:"
		read -e COMMENT 
	done

# doing the git action
cd $BACKUPDIR
git init
git add etc/ && git add content.lst && git add $EXCLUDEFILE && git commit -m "$USER $DATE initial commit"
}
