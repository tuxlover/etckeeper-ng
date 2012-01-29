#!/bin/bash

# etckeeper-ng

#the locatin of the configuration file
source /etc/keeper.conf


# This Programm should be able to backup and restore a complete etc-tree
# It uses git and rsync to archive this
# After backup has completed a complete restore should easy be possible 

# WARNING: work in progress. for details read the todo section on the bottom of this script

# help function starts here
get_help()
{
echo "$0 [ -i ] [ -b ] [ -l ] [ -r Branch ] [ -h ]"
echo "etckeeper-ng helps you creating a snapshot based backup of the /etc folder using git version control"
echo "-i: create the initial backup. there must be an initial backup to do new branched backups"
echo "-b: create a new branch backup. if no initiallized backup exists you will be asked"
echo "-c: check the /etc direcotry for changes"
echo "-C: check and restore permissions without asking"
echo "-e example: exclude /etc/exaple from versioning"
echo "-f /etc/myfile: add /etc/myfile single file to backup"
echo "-l: lists all existing branches"
echo "-r HEAD|<Commit> restore /etc from HEAD or a specific commit (broken)"
echo "becasue etc-keeper is still under development. the only way to to restore is using git and rsync by hand"
}


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

# check whether we are root
check_root()
{
if [ $UID -ne 0 ]
	then 
		echo -e '\E[31m not root'
		exit 1
fi
}

# function to write exclude patterns to a file
exclude()
{
EXCLUDES=$(echo "$OPTARG $args")

if [ ! -d $BACKUPDIR ]
	then
		mkdir $BACKUPDIR
fi

for e in ${EXCLUDES}	
	do
		# test whether we have any files of a matching pattern
		# if no pattern where matched we dont add this to the exlude file
		is_valid_exclude=$(ls /etc/$e &> /dev/null && echo "yes"|| echo "no")
		if [ "$is_vaild_exclude" == "no" ]
			then
				echo "$e does not match any file"
				continue
		fi
			echo "/$e" >> $EXCLUDEFILE
	done
	
}

#do the initial backup
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
				echo "use -b option to commit new backup branch"
				exit 1
			else
				rm -rf $BACKUPDIR/
		fi
fi

#configure the gloabel git  if allready set do nothing
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
		echo "WARNING: Use -e to wirte a list of filese that will be excluded"
		echo "WARNING: it is highly recommended that you first define what should be exluded"
		sleep 10
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
if [ ! -e $EXCLUDEFILE ]
then
	git add etc/ && git add content.lst && git commit -m "$USER $DATE ${COMMENT[*]}"
else
	git add etc/ && git add content.lst && git add $EXCLUDEFILE && git commit -m "$USER $DATE ${COMMENT[*]}"
fi
}


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

# to a branched backup
backup_git()
{

DATE=$(date +%F-%H-%M)
#check if the initial backup exists
if [ ! -s $BACKUPDIR/content.lst ]
	then
		echo "No initial backup found"
		read -p "Would you like to do an initial backup now?(y)" ANSWER
		${ANSWER:="no"} 2> /dev/null
		
		if [ "$ANSWER" != "y"  ]
			then
				echo "use -i option to do an initial backup"
				exit 1
			else
				initial_git && exit 0 || exit  && exit 0 || exit 11
		fi				
fi
# first make sure we are on master
cd $BACKUPDIR
git checkout master

git_return=0
check_perms
return_check=$?
set_mod=0
set_del=0
set_add=0
set_ren=0
set_new=0

# check if exluce file exists
if [ ! -e $EXCLUDEFILE ]
	then
		rsync -rtpog --delete -clis /etc/ $BACKUPDIR/etc/
	else
		rsync -rtpog --delete -clis --exclude-from=$EXCLUDEFILE --delete-excluded /etc/ $BACKUPDIR/etc/
fi


# then track changed files
# create a helper file which will be deleted afterwards
git_status_file="/tmp/git_status_file"
git status -s > $git_status_file
lof=$(wc -l $git_status_file|awk '{print $1}')
until  [ "$lof" == 0  ]
	do	
		if [ $(tail -n $lof $git_status_file|head -1|awk '{print $1}') == "M" 2> /dev/null ]
			then
				mod_file=$(tail -n $lof $git_status_file|head -1|awk '{print $2}')
				echo "modified file: $mod_file"
				git add $mod_file
					
					if [ $set_mod  -eq 0 ]
						then
							return_check=$((return_check+=2 ))
							set_mod=1
					fi			

		elif [ $(tail -n $lof $git_status_file|head -1|awk '{print $1}') == "D"  2> /dev/null ]
			then
				del_file=$(tail -n $lof $git_status_file|head -1|awk '{print $2}')
				echo "deleted file: $del_file"
				
				if [ grep $del_file $EXCLUDEFILE &> /dev/null ]
					then
						echo "$del_file was excluded by exlcude rule and will be removed from backup"
				fi
					git rm $del_file
				
				if [ $set_del -eq 0 ]
					then
						return_check=$((return_check+=4 ))
						set_del=1
				fi


		elif [ $(tail -n $lof $git_status_file|head -1|awk '{print $1}') == "A" 2> /dev/null ]
			then
				a_file=$(tail -n $lof $git_status_file|head -1|awk '{print $2}')
				echo "file was allready added: $a_file"

				if [ $set_add -eq 0 ]
					then
						return_check=$((return_check+=8 ))
						set_add=1
				fi


		elif [$(tail -n $lof $git_status_file|head -1|awk '{print $1}') == "R" 2> /dev/null ]
			then
				ren_file=$(tail -n $lof $git_status_file|head -1|awk '{print $2}')
				echo "renamed file: $ren_file"
				git add $ren_file

				if [ $set_ren -eq 0 ]
					then
						return_check=$((return_check+=16 ))
						set_ren=1
				fi

			else
				new_file=$(tail -n $lof $git_status_file|head -1|awk '{print $2}')
				echo "new file: $new_file"
				git add $new_file
				
				if [ $set_new -eq 0 ]
					then
						return_check=$((return_ceck+=32 ))
						set_new=1
				fi

		fi
		lof=$((lof-=1 ))
	done

echo "Check Code is $return_check"
#remove untracked file git_status_file
rm $git_status_file

#create new content file only when new files were added or permissions have changed
if [[ $return_check -eq 1 || $return_check -ge 32 ]]
	then
		#clean up the old content.lst
		cat /dev/null > $BACKUPDIR/content.lst
		find /etc/ -exec stat -c "%n %a %U %G" {} \; >> $BACKUPDIR/content.lst
		git add $BACKUPDIR/content.lst
fi
		
while [ -z "$COMMENT" ]
	do
		echo "please comment your commit and press Enter when finished:"
		read -e COMMENT 
	done
	
git commit -m "$USER $DATE ${COMMENT[*]}"

#and return back to master branch to make sure we succeed with no errors
git checkout master || return 1			
}

#restore from a certain commit
#restore_git()
#{
#check_perms_S

#if [ "$OPTARG" == "HEAD" ]
#		then
#			cd $BACKUPDIR
#			git checkout master
#			git reset --hard
#			git_status_file="/tmp/git_status_file"
#			git status -s > $git_status_file
#			lof=$(wc -l $git_status_file|awk '{print $1}')
#			until  [ "$lof" == 0  ]
#				do	
#					if [ $(tail -n $lof $git_status_file|head -1|awk '{print $1}') == "M" 2> /dev/null ]
#						then
#							:
#					elif [ $(tail -n $lof $git_status_file|head -1|awk '{print $1}') == "D"  2> /dev/null ]
#						then
#							:
#					elif [ $(tail -n $lof $git_status_file|head -1|awk '{print $1}') == "A" 2> /dev/null ]
#						then
#							:
#					elif [$(tail -n $lof $git_status_file|head -1|awk '{print $1}') == "R" 2> /dev/null ]
#						then
#							:
#					else
#						new_file=$(tail -n $lof $git_status_file|head -1|awk '{print $2}')
#						rm $new_file
#					fi
#					lof=$((lof-=1))
#				done
#		else
#			cd $BACKUPDIR
#			git checkout master
#			git reset --hard "$OPTARG" || echo "This commit does not exist. Use -l to show commits."
#			git_status_file="/tmp/git_status_file"
#			git status -s > $git_status_file
#			of=$(wc -l $git_status_file|awk '{print $1}')
#			until  [ "$lof" == 0  ]
#				do	
#					if [ $(tail -n $lof $git_status_file|head -1|awk '{print $1}') == "M" 2> /dev/null ]
#						then
#							:
#					elif [ $(tail -n $lof $git_status_file|head -1|awk '{print $1}') == "D"  2> /dev/null ]
#						then
#							:
#					elif [ $(tail -n $lof $git_status_file|head -1|awk '{print $1}') == "A" 2> /dev/null ]
#						then
#							:
#					elif [$(tail -n $lof $git_status_file|head -1|awk '{print $1}') == "R" 2> /dev/null ]
#						then
#							:
#					else
#						new_file=$(tail -n $lof $git_status_file|head -1|awk '{print $2}')
#						rm $new_file
#					fi
#					lof=$((lof-=1))
#				done
#fi
#rsync -rtpog -clis $BACKUPDIR/etc/ /etc/
#COMMENT=(backup after restore)
#backup_git
#}

compare()
{
#delete old logfile if exising
if [ -f $LOGFILE ]
	then
		rm $LOGFILE
fi

#check if the initial backup exists
if [ ! -s $BACKUPDIR/content.lst ]
	then
		echo "No initial backup found"
		read -p "Would you like to do an initial backup now?(y)" ANSWER
		${ANSWER:="no"} 2> /dev/null
		
		if [ "$ANSWER" != "y"  ]
			then
				echo "use -i option to do an initial backup"
				exit 1
			else
				initial_git && exit 0 || exit  && exit 0 || exit 11
		fi
	else
		mkdir $COMPAREDIR
		rsync -rtpog --delete -clis $BACKUPDIR $COMPAREDIR	
		rsync -rtpog --delete -clis --exclude-from=$EXCLUDEFILE /etc/ $COMPAREDIR/etc/
fi

return_check=0
check_perms
return_check=$?
set_mod=0
set_del=0
set_add=0
set_ren=0
set_new=0

cd $COMPAREDIR
git checkout master


git_status_file="/tmp/git_status_file"
git status -s > $git_status_file
lof=$(wc -l $git_status_file|awk '{print $1}')
until  [ "$lof" == 0  ]
	do	
		if [ $(tail -n $lof $git_status_file|head -1|awk '{print $1}') == "M" 2> /dev/null ]
			then
				mod_file=$(tail -n $lof $git_status_file|head -1|awk '{print $2}')
				echo "modified file: $mod_file"
				
				if [ $set_mod -eq 0 ]
					then
						return_check=$((return_check+=2))
						set_mod=1
				fi


		elif [ $(tail -n $lof $git_status_file|head -1|awk '{print $1}') == "D"  2> /dev/null ]
			then
				del_file=$(tail -n $lof $git_status_file|head -1|awk '{print $2}')
				echo "deleted file: $del_file"
				
				if [ $set_del -eq 0 ]
					then
						return_check=$((return_check+=4))
						set_del=1
				fi


		elif [ $(tail -n $lof $git_status_file|head -1|awk '{print $1}') == "A" 2> /dev/null ]
			then
				a_file=$(tail -n $lof $git_status_file|head -1|awk '{print $2}')
				echo "file was allready added: $a_file"
				
				if [ $set_add -eq 0 ]
					then
						return_check=$((return_check+=8))
						set_add=1
				fi

		elif [$(tail -n $lof $git_status_file|head -1|awk '{print $1}') == "R" 2> /dev/null ]
			then
				ren_file=$(tail -n $lof $git_status_file|head -1|awk '{print $2}')
				echo "renamed file: $ren_file"		

				if [ $set_ren -eq 0 ]
					then
						return_check=$((return_check+=16))
						set_ren=1
				fi


		else
				new_file=$(tail -n $lof $git_status_file|head -1|awk '{print $2}')
				echo "new file: $new_file"

				if [ $set_new -eq 0 ]
					then
						return_check=$((return_check+=32))
						set_new=1
				fi

				# TODO: print new files here and log to $LOGFILE
			
		fi
		lof=$((lof-=1))
	done

	return_array=(32 16 8 4 2 1 0)
	has_mod=$return_check

	for i in ${return_array[@]}
		do
			if [ $return_check -eq $i ]
				then

					if [ $i -eq 2  ]
						then
							PAGER=cat git diff $COMPAREDIR >> $LOGFILE
					fi
					break
								
			elif [ $return_check -gt $i ]	
				then
					has_mod=$((has_mod - $i))
				
					if [ $i -eq 2  ]
						then
							PAGER=cat git diff $COMPAREDIR >> $LOGFILE
					fi
			fi
		done
						

rm -rf $COMPAREDIR 
rm $git_status_file
}

check_perms()
{
return_check=0
echo "checking Permissions ..."	
	
count=$(wc -l $BACKUPDIR/content.lst | awk '{print $1}')

until [ $count == 0  ]
	do
		FILE=$(tail -n ${count} $BACKUPDIR/content.lst|head -1)
		NAME=$(echo $FILE|awk '{print $1}')
		PERMS=$(echo $FILE|awk '{print $2}')
		OWNU=$(echo $FILE|awk '{print $3}')
		OWNG=$(echo $FILE|awk '{print $4}')
		
	#if a file is not present, skip test
		if [ ! -e "$NAME" ]
			then
				count=$((count-=1))
				continue
		fi
	
	#cheking whether the Permissions have changed
		if [ "$(stat -c %a $NAME)" != "$PERMS"  ]
			then	
				echo -e '\E[31m permissions'; echo "of file $NAME has changed to $(stat -c %a $NAME)"
				tput sgr0
				echo "Restore permission for $NAME to $PERMS" 
				read -e -n 1 -p	"y(restore)/n(check in these changes)" ANSWER1
				{$ANSWER1:="n"} 2> /dev/null
				
				if [ $ANSWER1 == "y" ]
					then
						chmod $PERMS $NAME
						echo "permissions for file $NAME restored"
				fi
				return_check=1
		fi
		
	#checking whether the Owner or the Group has changed 
		if [[ "$(stat -c %U $NAME)" != "$OWNU" || "$(stat -c %G $NAME)" != "$OWNG" ]]
			then				
				echo -e '\E[31m owner or group'; echo  "of $NAME has changed to $(stat -c "%U:%G" $NAME)"
				tput sgr0
				echo "Restore the owner and the Group of the File $NAME to $OWNU:$OWNG " 
				read -e -n 1 -p	"y(restore)/n (check in these changes)" ANSWER2
				{$ANSWER2:="n"}	2> /dev/null
				
				if [ $ANSWER2 == "y" ]
					then
					chown $OWNU:$OWNG $NAME
					echo "Owner and Group for $FILE restored"
				fi
				return_check=1
		fi

		count=$((count-=1))
		unset FILE
		unset ANSWER1
		unset ANSWER2
	done
	return $return_check
}

check_perms_S()
{
return_check=0
echo "checking Permissions ..."	
	
count=$(wc -l $BACKUPDIR/content.lst | awk '{print $1}')

until [ $count == 0  ]
	do
		FILE=$(tail -n ${count} $BACKUPDIR/content.lst|head -1)
		NAME=$(echo $FILE|awk '{print $1}')
		PERMS=$(echo $FILE|awk '{print $2}')
		OWNU=$(echo $FILE|awk '{print $3}')
		OWNG=$(echo $FILE|awk '{print $4}')
		
	#if a file is not present, skip test
		if [ ! -e "$NAME" ]
			then
				count=$((count-=1))
				continue
		fi
	
	#cheking whether the Permissions have changed
		if [ "$(stat -c %a $NAME)" != "$PERMS"  ]
			then	
				echo -e '\E[31m permissions'; echo "of file $NAME has changed to $(stat -c %a $NAME)"
				tput sgr0
				chmod $PERMS $NAME
				echo "permissions for file $NAME restored"
				return_check=1
		fi
		
	#checking whether the Owner or the Group has changed 
		if [[ "$(stat -c %U $NAME)" != "$OWNU" || "$(stat -c %G $NAME)" != "$OWNG" ]]
			then				
				echo -e '\E[31m owner or group'; echo  "of $NAME has changed to $(stat -c "%U:%G" $NAME)"
				tput sgr0
				chown $OWNU:$OWNG $NAME
				echo "Owner and Group for $FILE restored"
				return_check=1
		fi

		count=$((count-=1))
		unset FILE

	done
	return $return_check
}


list_git()
{

cd $BACKUPDIR 2> /dev/null || return 1
git branch -a
PAGER=cat git log
}

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
			c) compare
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

# Todo:
# report of changed files in diff report file when found in function compare
# add cronjob functionality to do checks in regular intervalls
# use a config file for configuring how etckeeper behaves
# dont remove exlcudefile when reinitializing with -i
# The restore option is still broken
# add a comment funtion if you only need to comment your work for example if you changed files which where exlcluded by excludefile
# make fskeeper use an external config file which gets sourced 
# make the config file options work
#using multiple backups
# option -s to list excludes, -d to delete excludes and -E to edit excludes 
#-b option
# Write checksums for excluded files
#-c options
# do check for the checksums for excluded files 
# -c if no changes were made tell the user
# colorize the output
# -f option can take more than one argument
# use -u options when using -f before. so it goes like this etckeeper-ng -f /etc/bla/foor.conf; etckeeper -u
# check if the argument is an etc file
# -u option to update a repository 
# -s we need to have a status option
# write a simple manpage for this program
# package the program
# get it as official package


# Bugs:
# #1 having german umlaute in datafiles gets data not to be commited
# #2 exluding a file by describing the absolute path does not work
# #3 when using exclude, allready added exlude patterns will get added again
# #4 when using -b option and a file was excluded or deleted etckeeper does sometimes not recognize this 
# #5 when using -f somtimes getting this:
#fatal: Not a git repository (or any parent up to mount parent )
#Stopping at filesystem boundary (GIT_DISCOVERY_ACROSS_FILESYSTEM not set).
