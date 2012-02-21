# the check module
# check whether we have all needed tools installed and got acces to them

check_tools()
{
# checking git
git --version &> /dev/null && HAS_GIT="yes" || HAS_GIT="no"
if [ $HAS_GIT != "yes" ]
	then
		echo -e '\E[31m git not installed'
		tput sgr0
		exit 1
fi

# checking rsync
rsync --version &> /dev/nul && HAS_RSYNC="yes" || HAS_RSYNC="no"
if [ $HAS_RSYNC != "yes" ]
		then
			echo -e '\[31m rsync not installed'
			tput sgr0
			exit 1
fi

# checking awk
awk --version &> /dev/null && HAS_AWK="yes" || HAS_AWK="no"
if [ $HAS_AWK != "yes" ]
	then
		echo -e '\E[31m awk not installed'
		tput sgr0
		exit 1
fi

# checking grep
grep --version &> /dev/null && HAS_GREP="yes" || HAS_GREP="no"
if [ $HAS_GREP != "yes" ]
	then
		echo -e '\E[31m grep not installed'
		tput sgr0
		exit 1
fi

# checking find
find --version &> /dev/null && HAS_FIND="yes" || HAS_FIND="no"
if [ $HAS_FIND != "yes" ]
	then
		echo -e '\E[31m findutils not installed'
		tput sgr0
		exit 1
fi

# checking stat
stat --version &> /dev/null && HAS_STAT="yes" || HAS_STAT="no"
if [ $HAS_STAT != "yes" ]
	then
		echo -e '\E[31m coreutils not installed'
		tput sgr0
		exit 1
fi

}
