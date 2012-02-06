
# check root module 
# check whether we are root
check_root()
{
if [ $UID -ne 0 ]
	then 
		echo -e '\E[31m not root'
		exit 1
fi
}
