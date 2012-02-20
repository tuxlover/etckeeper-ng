# This module contains the journal and logging modules

list_git()
{

cd $BACKUPDIR 2> /dev/null || return 1
git branch -a
PAGER=cat git log
echo -e '\E[32m done'
tput sgr0
}

show_journal()
{
if [ ! -z $JOURNAL ]
	then
		cat $JOURNAL
	 else
			echo "!!! empty journal !!!"
fi
}
