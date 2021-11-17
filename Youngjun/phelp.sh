#!/bin/sh

scripts=`ls -l ~/SCRIPTS_PLUS | grep "\-rwxrwxr\-x" | awk '{print $9}'`
num_of_scripts=`echo $scripts | wc -w`

echo $scripts

echo " Num        Command                               Discription"
echo "=====||====================||==============================================================="

for i in $(seq $num_of_scripts)
do
list=`echo $scripts | awk '{print $'"$i"'}'`
discription=`sed -n 4p ~/SCRIPTS_PLUS/$list | sed 's/#//'`

pprint=`echo $i -- $list -- $discription`
#echo pprint -s

#printf "%1s$i%-10s$list%-12s$discription \n"
#printf "%s %s %s" $i $list $discription

#echo $pprint
echo $pprint | awk -F"--" '{{printf("%4s", $1);printf("      %-18s",$2);printf("  %-20s",$3);printf("\n")}}'

#echo "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - "
echo ""

#ping -c $np -W 1 "$i" | awk ' 
#BEGIN{button=0}
#{
#   if( $1 == "PING" ){printf("%10s  :  ",$2)}
#   else if( $1 == "rtt" ){button=1;printf("   %s ",$4);printf("\n")}
#   else if( $1 == "rtt" ){button=0;printf("\n")}
#}'

done
echo "================================================================================================"

read -p "Enter the number to use : " num

echo $scripts
plays=`echo $scripts | awk '{print $'"$num"'}'`
echo $plays
$plays
#sh ~/SCRIPTS_PLUS/$play