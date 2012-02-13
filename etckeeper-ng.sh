#!/bin/bash

# etckeeper-ng
# This varibale is use to indicate the working dir for etckeeper modules
EWD="/usr/local/bin"

#the location of the configuration file
source /etc/keeper.conf

#this functions are needed by etckeeper-ng
source $EWD/get_help.sh
source $EWD/check_tools.sh
source $EWD/check_root.sh
source $EWD/exclude.sh
source $EWD/initial_git.sh
source $EWD/backup_single.sh
source $EWD/backup_git.sh
#source $EWD/restore_git.sh
source $EWD/compare_etc.sh
source $EWD/check_perms.sh
source $EWD/check_perms_S.sh
source $EWD/reset_etc.sh


# This Programm should be able to backup and restore a complete etc-tree
# It uses git and rsync to archive this
# After backup has completed a complete restore should easy be possible 

#check functions gets executed before doing anything else
check_root
check_tools
#options starts here
# getting rid of those stupid options using words instead
if [ $# -lt 1 ]
	then
		get_help
		exit 0
fi

if [ $# -eq 1 ]
	then
		case "$1" in
			"init") initial
					exit 0
			;;
			"backup") backup_git
					  exit 0
			;;
			"list") list_git || echo "no backup and no git repo found."
					 exit 0
			;;
			"check") compare_etc
					  exit 0
			;;
			"reperm") check_perms_S
					  exit 0
			;;
			"list-excludes") cat $EXCLUDEFILE
							 exit 0
			;;
			"reset") reset_etc
					 exit 0
			;;
			"help") get_help
					exit 0
			;;
			*) get_help
			   exit 0
		esac
fi
		
if [ $# -ge 2 ]		
	then
		case "$1" in 
		"exclude") args=$(echo $*)
				   exclude
				   exit 0
			;;
		"add")  args=$(echo $*)
				backup_single
				exit 0
			;; 			
								
		*) get_help
		   exit 0
		esac
else
	get_help
fi
			
					
exit 0
