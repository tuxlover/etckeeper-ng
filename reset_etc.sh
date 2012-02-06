# reset function

reset_etc()
{
cd $BACKUPDIR
git checkout -- *
rsync -rtpogq -clis $BACKUPDIR/etc/ /etc/


}
# TODO:
# check and delete files which are  not in the original directory
# but check if the file is in the excludefile
