# check root module 
# check whether we are root
# this is bash shell module for keeper.sh
# see install instructions to see how to install and use this and other modules
## State needed
check_root()
{
if [ $UID -ne 0 ]
	then 
		echo -e '\E[31m not root'
		tput sgr0
		exit 1
fi
}
