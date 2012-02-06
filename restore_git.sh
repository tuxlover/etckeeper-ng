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
