
# the help module
# This module shows the help for a user

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
