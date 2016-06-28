#!/bin/sh
sek=5
echo "Waiting $sek Seconds For The System!" 
while [ $sek -ge 1 ] 
do 
   echo -ne "Please Wait $sek ... \r" 
   sleep 1 
   sek=$[$sek-1] 
done 
roxterm --title='camara secure erase' -e /root/camwipe.sh

