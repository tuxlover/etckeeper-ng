#!/bin/bash

# etckeeper-ng
# This varibale is use to indicate the working dir for etckeeper modules
EWD="/usr/local/bin"

#the location of the configuration file
source /etc/keeper.conf
source $EWD/get_help.sh
source $EWD/check_tools.sh
source $EWD/check_root.sh
source $EWD/exclude.sh
source $EWD/initial_git.sh
source $EWD/backup_single.sh
source $EWD/backup_git.sh
#soruce $EWD/restore_git.sh
source $EWD/compare_etc.sh
source $EWD/check_perms.sh
source $EWD/check_perms_S.sh


# This Programm should be able to backup and restore a complete etc-tree
# It uses git and rsync to archive this
# After backup has completed a complete restore should easy be possible 

# WARNING: work in progress. for details read the todo section on the bottom of this script




#check functions gets executed before doing anything else
check_root
check_tools
#options starts here
while getopts ibcClhe:f: opt
	do
		case "$opt" in
			i) initial_git
			;;
			e) shift $((OPTIND -1))
				args=$(echo $*)
				exclude
				break
			;;
			f) backup_git_single 
			;;
			b) backup_git
			;;
			c) compare_etc
			;;
			C) check_perms_S
			;;
			l) list_git || echo "no initial backup and no git repo found"
			;;
			h) get_help
			;;
			\?) get_help
		esac
	done
shift `expr $OPTIND - 1`

exit 0
