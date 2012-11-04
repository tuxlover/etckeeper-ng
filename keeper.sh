#!/bin/bash

# keeper.sh
# This varibale is use to indicate the working dir for keeper modules
EWD="/usr/local/sbin/keeper_modules"
is_sourced="yes"

# the location of the configuration file
# checking whether we have keeper.conf present
source /etc/keeper.conf || is_sourced="no"


# selftest before sourcing the modules
# if a module could not get sourced corectly we will stop here
# these functions are needed by keeper
source $EWD/get_help.sh || is_sourced="no"
source $EWD/check_tools.sh || is_sourced="no"
source $EWD/check_root.sh || is_sourced="no"
source $EWD/exclude.sh || is_sourced="no"
source $EWD/initial_git.sh || is_sourced="no"
source $EWD/backup_single.sh || is_sourced="no"
source $EWD/backup_git.sh || is_sourced="no"
# source $EWD/restore_git.sh || is_sourced="no"
source $EWD/compare_etc.sh || is_sourced="no"
source $EWD/check_perms.sh || is_sourced="no"
source $EWD/reset_etc.sh || is_sourced="no"
source $EWD/keep_log.sh || is_sourced="no"
source $EWD/post_comment.sh || is_sourced="no"


if [ $is_sourced == "no" ]
	then
		echo "OOps: Internal Script failure."
		exit 1
fi

# This Programm should be able to backup and restore a complete etc-tree
# It uses git and rsync to do this
# After backup has completed a complete restore should easy be possible 

# check functions gets executed before doing anything else
check_root
check_tools
# options starts here
# getting rid of those stupid options using words instead
if [ $# -lt 1 ]
	then
		get_help
		exit 0
fi

if [ $# -eq 1 ]
	then
		case "$1" in
			"init") initial_git
					exit 0
			;;
			"backup") backup_git
					  exit 0
			;;
			"list") list_git || echo "no backup and no git repo found."
					 exit 0
			;;
			"journal") show_journal
						exit 0
			;;
			"check") compare_etc
					  exit 0
			;;
			"reperm") INTERACTIVE="no"
					  DATE=$(date +%F-%H-%M)
					  echo "#$DATE" >> $JOURNAL
					  check_perms && sed -i '$d' $JOURNAL || echo "###" >> $JOURNAL
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
		unset arg
		case "$1" in 
		"exclude") shift
				   arg=$(echo $*)
				   exclude
				   exit 0
			;;
		"add")  shift
				arg=$(echo $*)
				backup_single
				exit 0
			;;
		"comment") args=$(echo $*) 			
				   post_comment
				   exit 0
			;;				
		*) get_help
		   exit 0
		esac
else
	get_help
fi
			
					
exit 0
