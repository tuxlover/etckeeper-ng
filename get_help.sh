
# the help module
# This module shows the help for a user

get_help()
{
echo "$0 <command>"
echo "etckeeper-ng helps you creating a snapshot based backup of the /etc folder using git version control"
echo "init: create the initial backup. there must be an initial backup to do new branched backups"
echo "backup: create a new branch backup. if no initiallized backup exists you will be asked"
echo "check: check the /etc direcotry for changes"
echo "reperm: check and restore permissions without asking"
echo "exclude example: exclude /etc/exaple from versioning"
echo "add /etc/myfile: add /etc/myfile single file to backup"
echo "list: lists all existing branches"
echo "list-excludes: list all exclude patterns"
#echo "restore HEAD|<Commit> restore /etc from HEAD or a specific commit (broken)"
echo "reset: restores the last known state if something has changed but not backuped yet"
echo "becasue etc-keeper is still under development. the only way to restore is using git and rsync by hand"
}
