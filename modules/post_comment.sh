# module to only create a comment 
# this is bash shell module for keeper.sh
# see install instructions to see how to install and use this and other module
## State needed
# for example when you want to leave a note for other admins
post_comment()
{
COMMENT=$(echo "$args"|awk '{$1=$2;print}')
DATE=$(date +%F-%H-%M)
# fix problems with german umlauts
# if already set do nothing
git config --global core.quotepath false || :

echo "#$DATE" >> $JOURNAL
echo "#${COMMENT[*]}"	>> $JOURNAL
echo "###" >> $JOURNAL
}
