# module to only create a comment 
# for example when you want to leave a note for other admins
post_comment()
{
COMMENT=$(echo "$args"|awk '{$1=$2;print}')
DATE=$(date +%F-%H-%M)
# fix problems with german umlauts
# if already set do nothing
git config --global core.quotepath false || :

echo ${COMMENT[*]}	
}
