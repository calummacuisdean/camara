#!/bin/bash

echo "Camara Education Ltd"
MYTIMEVAR=`date +'%a %d %b %Y %k:%M:%S'`
echo
echo "$MYTIMEVAR"
echo
read -p "Please enter barcode, or press CTRL C to exit: " -r BARCODE
BARCODE=`echo "$BARCODE" | tr -cd [:alnum:] | tr '[:lower:]' '[:upper:]'`
echo
echo "Entered Clean Barcode is $BARCODE"
echo
echo "Please wait while system is analysed..."
echo
export NWIPEVERSION=`nwipe --version`
MEMFREE=`free | grep -w 'Mem' | awk '{print $2}'`
let MEMFREE=$MEMFREE/1024 # less accurate (32 bit limit)
MEMSYS="`lshw -C memory -short | grep 'System' | awk '{print $3}'`"
PROCSPEED="`cat /proc/cpuinfo | grep -m 1 -i 'cpu mhz' | awk '{print $4, $2}'`"	
PROCNAME="`cat /proc/cpuinfo | grep -m 1 -i 'model name' | cut -d : -f 2`"

Barcode=$BARCODE 
System_Manufacturer=`dmidecode -s system-manufacturer`
System_Serial_Number=`dmidecode -s system-serial-number`
System_Product_Name=`dmidecode -s system-product-name`
Chassis_Asset_Tag=`dmidecode -s chassis-asset-tag`
Baseboard_Asset_Tag=`dmidecode -s baseboard-asset-tag`
Baseboard_Serial_Number=`dmidecode -s baseboard-serial-number`
Chassis_Serial_Number=`dmidecode -s chassis-serial-number`
Chassis_Asset_Tag=`dmidecode -s chassis-asset-tag`
Chassis_Type=`dmidecode -s chassis-type`
System_UUID=`dmidecode -s system-uuid`
System_version=`dmidecode -s system-version`
Eth0_MAC_Addr=`ip link show eth0 | awk '/ether/ {print $2}'`
Memory=$MEMSYS
Memory_Type=`dmidecode type 17 | grep DDR | awk -F: 'NR==1{print $2}'`
Memory_MB=$MEMFREE
CPU_MHz=$PROCSPEED
CPU_Model_Name=$PROCNAME
Disks=(`dmesg | grep "SCSI disk" | awk -F'[][]' '{print $4}'`)
#####################################################
echo "Enumerating hard disks..."
Disk_Count=`dmesg | grep "SCSI disk" | awk -F'[][]' '{print $4}' | grep -c sd`
echo
if [ $Disk_Count != 0 ]; then
echo -e "\e[32m$Disk_Count hard disk(s) detected: ${Disks[@]}\e[0m"
else
echo -e "\e[31mNo hard disk(s) found!\e[0m"
echo
read -p "Press any key to exit." -n1 -s
exit
fi
echo
#
# Begin loop
#
for disk in ${Disks[@]}
do
#
# Begin variables
#
Disk_Frozen=`hdparm -I /dev/$disk | grep frozen | grep -c not`
Disk_Health=`smartctl -H /dev/$disk | grep -i "test result" | tail -c15 |awk -F":" '{print $2}' | sed -e 's/^[ <t]*//;s/[ <t]*$//'`
Disk_Lock=`hdparm -I /dev/$disk | grep locked | grep -c not`
Disk_Model=`hdparm -I /dev/$disk | grep "Model Number" | awk -F":" '{print $2}' | sed -e 's/^[ <t]*//;s/[ <t]*$//'`
Disk_Serial=`hdparm -I /dev/$disk | grep "Serial Number" | awk -F":" '{print $2}' | sed -e 's/^[ <t]*//;s/[ <t]*$//'`
Disk_Size=`hdparm -I /dev/$disk | grep 1000: | grep -oP '(?<=\()[^\)]+'`
Enhanced_Erase=`hdparm -I /dev/$disk | grep -i enhanced | grep -c not`
Erase_Estimate=`hdparm -I /dev/$disk | grep -i "for security erase" | awk '{print $1}'`
Security_Erase=`hdparm -I /dev/$disk | grep -c "Security Mode"`
Smart_Check=`hdparm -I /dev/$disk | grep -i "SMART feature set" | grep -c "*"`
MYFILENAMEA="`date +'%Y%m%d-%H%M%S_%N'`"
MYLOGFILENAME="/root/camwipe.log"
touch $MYLOGFILENAME
ID_Date_No=$MYFILENAMEA 
#
# End Variables
#
# Check if disk is locked and unlock if necessary
#
if [ $Security_Erase != 0 ] && [ $Disk_Lock == 0 ]; then
echo "Unlocking device /dev/$disk..."
hdparm --security-disable password /dev/$disk >/dev/null
echo
fi
# Print basic disk info to screen and log
#
echo "Device /dev/$disk is a $Disk_Model" && echo "Disk Model: $Disk_Model" > $MYLOGFILENAME
echo >> $MYLOGFILENAME
echo "Serial Number is $Disk_Serial" && echo "Serial Number: $Disk_Serial" >> $MYLOGFILENAME
echo >> $MYLOGFILENAME
echo "Capacity is $Disk_Size" && echo "Capacity: $Disk_Size" >> $MYLOGFILENAME
echo && echo >> $MYLOGFILENAME
#
# Check if SMART is supported and print SMART status to screen and log
#
if [ $Smart_Check != 0 ]; then
echo "SMART status for device /dev/$disk: $Disk_Health" && echo "SMART status: $Disk_Health" >> $MYLOGFILENAME && echo >> $MYLOGFILENAME
else
echo -e "\e[33mDevice /dev/$disk does not support SMART or it is disabled.\e[0m" && echo "Disk Health Check: SMART unsupported" >> $MYLOGFILENAME && echo >> $MYLOGFILENAME
fi
echo
#
# If drive is healthy or if SMART is unavailable, check for security erase support and wipe using hdparm or nwipe
#
if [ $Smart_Check == 0 ] || [ $Disk_Health == PASSED ]; then
  if [ $Security_Erase != 0 ]; then
#
# Run hdparm
#
echo -e "\e[32mThis device supports security erase.\e[0m"
echo
#
# Check if disk is frozen and sleep machine if necessary
#
if [ $Disk_Frozen == 0 ]; then
echo "Device /dev/$disk is frozen. Sleeping machine to unfreeze..."
echo
sleep 3s
rtcwake -u -s 10 -m mem >/dev/null
sleep 5s
fi
echo "Setting password..."
echo
hdparm --security-set-pass password /dev/$disk >/dev/null
if [ $? -eq 0 ]; then
   echo -e "\e[32mPassword set\e[0m"
   else 
   echo -e "\e[31mFailed to set password!\e[0m"
   echo
   read -p "Press any key to continue." -n1 -s
fi
echo
MYTIMEVAR=`date +'%k:%M:%S'`
if [ $Enhanced_Erase == 0 ]; then
echo "Enhanced secure erase of $Disk_Model (/dev/$disk) started at $MYTIMEVAR." && echo "Wiping device using enhanced secure erase." >>  $MYLOGFILENAME && echo >> $MYLOGFILENAME
if [[ $Erase_Estimate ]]; then
echo "Estimated time for erase is $Erase_Estimate."
else
echo "Estimated time for erase is unknown. It may take one or more hours..."
fi
hdparm --security-erase-enhanced password /dev/$disk >/dev/null
else
echo "Secure erase of $Disk_Model (/dev/$disk) started at $MYTIMEVAR." && echo -e "This may take one or more hours..."  && echo "Wiping device using secure erase." >>  $MYLOGFILENAME && echo >> $MYLOGFILENAME
if [[ $Erase_Estimate ]]; then
echo "Estimated time for erase is $Erase_Estimate."
else
echo "Estimated time for erase is unknown. It may take one or more hours..."
fi
hdparm --security-erase password /dev/$disk >/dev/null
fi
if [ $? -eq 0 ]; then
echo
echo -e "\e[32mDisk erased successfully.\e[0m" && echo "Blanked device successfully." >> $MYLOGFILENAME && echo >> $MYLOGFILENAME
echo
else
echo
echo -e "\e[31mErase failed. Replace hard disk.\e[0m" && echo "Wipe of device failed." >> $MYLOGFILENAME && echo >> $MYLOGFILENAME
echo
fi
  else
#
# Run nwipe
#
echo -e "\e[33mDevice /dev/$disk does not support security erase. Falling back to nwipe...\e[0m" && echo "Security erase not supported by device. Falling back to nwipe..." >> $MYLOGFILENAME && echo >> $MYLOGFILENAME
echo
sleep 3s
nwipe --autonuke --method=dodshort --nowait --logfile=$MYLOGFILENAME /dev/$disk
     MYTIMEVAR=`date +'%a %d %b %Y %k:%M:%S'`
     echo "Finished on: $MYTIMEVAR" >> $MYLOGFILENAME
     echo "$NWIPEVERSION" >> $MYLOGFILENAME
  fi
fi
#
# If SMART is supported and drive is unhealthy, print message to replace disk 
#
if [ $Smart_Check != 0 ] && [ $Disk_Health != PASSED ]; then
echo -e "\e[31mSMART check of /dev/$disk failed. Replace hard disk.\e[0m" && echo "SMART check failed." >> $MYLOGFILENAME && echo >> $MYLOGFILENAME && echo "Wipe of device failed." >> $MYLOGFILENAME
echo
read -p "Press any key to continue." -n1 -s
fi
WORDCOUNTF=`grep "Wipe of device" "${MYLOGFILENAME}" | grep -c "failed"`
WORDCOUNTS=`grep "Blanked" "${MYLOGFILENAME}" | grep -c "device"`

MYFILENAMEA="${BARCODE}_$MYFILENAMEA"
MYFILENAMEB=${MYFILENAMEA}.html
MYFILENAMEA="/root/${MYFILENAMEB}"
#<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
touch $MYFILENAMEA
cat >>$MYFILENAMEA <<END_OF_LOGFILENAMEA1
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd"> 
<html>
	<head>
	<meta http-equiv="content-type" content="text/html; charset=ISO-8859-1">
		<title>Camara System Wiping Report</title>

		<style type="text/css">
		p.p1 {
			font-size: 200%;	
			font-style: normal;	
		   font-family: arial, helvetica, sans-serif;
			font-weight: bolder;
			color: green;
			}
		p.p2 {
			font-size: 150%;
			font-style: italic;
   		font-family: arial, helvetica, sans-serif;
			font-weight: bold;
			color: black;
			}
		p.p3 {
			font-size: 100%;
			font-style: normal;
   		font-family: arial, helvetica, sans-serif;
			font-weight: bold;
			color: black;
			}
		p.ptd {
			font-size: 95%;				
			font-style: normal;
   		font-family: arial, helvetica, sans-serif;
			font-weight: bold;
			color: green;
			}
		TH {
			text-align : left;
			font-size: 95%;				
			font-style: normal;
   			font-family: arial, helvetica, sans-serif;
			font-weight: bold;
			color: green;
			padding: 4px;
			}
		TD {
			font-size: 95%;			
			font-style: normal;
   			font-family: courier, fixed, monospace;
			font-weight: normal;
			color: black;
			padding: 4px;
			}
	 CODE {
			font-size: 120%;			
			font-style: normal;
   			font-family: courier, fixed, monospace;
			font-weight: normal;
			color: black;
			}
	a     {
			font-size: 100%;
			font-style: normal;
   		font-family: arial, helvetica, sans-serif;
			font-weight: bold;
			color: green;
			}	
			</style>
	</head>
<body>
	
<!-img src="logo_camara1.gif" width="274" height="70" border="2">
<p class=p1>Camara Education Ltd</p>
	<p class=p2>System Wiping Report</p>
	<p class=p3>$MYTIMEVAR Barcode ID: $BARCODE</p>
 
	<TABLE border=1>
	<tbody>
	<TR><TH>System Info</th><TH>Camara Disk Wipe Log</th></tr>
	<TR>
	<TD style="vertical-align:top" bgcolor="white">
	<TABLE border=2>
	<tbody>
		<TR><TH>Barcode</TH><TD>$BARCODE</TD></TR>
		<TR><TH>ID_Date_No</TH><TD>$ID_Date_No</TD></tr>
		<TR><TH>System_Manufacturer</TH><TD>$System_Manufacturer</TD></tr>
		<TR><TH>System_Serial_Number</TH><TD>$System_Serial_Number</TD></tr>
		<TR><TH>System_Product_Name</TH><TD>$System_Product_Name</TD></tr>
		<TR><TH>Chassis_Asset_Tag</TH><TD>$Chassis_Asset_Tag</TD></tr>
		<TR><TH>Baseboard_Asset_Tag</TH><TD>$Baseboard_Asset_Tag</TD></tr>
		<TR><TH>Baseboard_Serial_Number</TH><TD>$Baseboard_Serial_Number</TD></tr>
		<TR><TH>Chassis_Serial_Number</TH><TD>$Chassis_Serial_Number</TD></tr>
		<TR><TH>Chassis_Asset_Tag</TH><TD>$Chassis_Asset_Tag</TD></tr>
		<TR><TH>Chassis_Type</TH><TD>$Chassis_Type</TD></tr>
		<TR><TH>System_UUID</TH><TD>$System_UUID</TD></tr>
		<TR><TH>System_version</TH><TD>$System_version</TD></tr>
		<TR><TH>Eth0_MAC_Addr</TH><TD>$Eth0_MAC_Addr</TD></tr>
		<TR><TH>Memory</TH><TD>$Memory $Memory_Type</TD></tr>
		<TR><TH>Memory_MB</TH><TD>$Memory_MB</TD></tr>
		<TR><TH>CPU_MHz</TH><TD>$CPU_MHz</TD></tr>
		<TR><TH>CPU_Model_Name</TH><TD>$CPU_Model_Name</TD></tr>
	</tbody>
	</TABLE>
	</td>

	<TD style="vertical-align:top" bgcolor="grey">
<PRE><CODE style="vertical-align:top">
END_OF_LOGFILENAMEA1

cat ${MYLOGFILENAME} >>$MYFILENAMEA

MYTIMEVAR=`date +'%a %d %b %Y %k:%M:%S'`

cat >>$MYFILENAMEA <<END_OF_LOGFILENAMEA2
</code></PRE></TD>
	</tr>
	</tbody>
	</table>

<p class=p3>Finished on: $MYTIMEVAR</p>
<a href="http://camara.org/" target="_blank">camara.org</a> 
</body>
</html>
END_OF_LOGFILENAMEA2

if [ "$WORDCOUNTS" -gt "0" ]
then sed -i 's/<TD style="vertical-align:top" bgcolor="grey">/<TD style="vertical-align:top" bgcolor="green">/g' $MYFILENAMEA
else sed -i 's/<TD style="vertical-align:top" bgcolor="grey">/<TD style="vertical-align:top" bgcolor="grey">/g' $MYFILENAMEA
fi

if [ "$WORDCOUNTF" -gt "0" ]
then sed -i 's/<TD style="vertical-align:top" bgcolor="grey">/<TD style="vertical-align:top" bgcolor="red">/g' $MYFILENAMEA
else sed -i 's/<TD style="vertical-align:top" bgcolor="grey">/<TD style="vertical-align:top" bgcolor="yellow">/g' $MYFILENAMEA
fi

if [ "$WORDCOUNTF" -gt "0" ]
then sed -i 's/<TD style="vertical-align:top" bgcolor="green">/<TD style="vertical-align:top" bgcolor="red">/g' $MYFILENAMEA
else sed -i 's/<TD style="vertical-align:top" bgcolor="grey">/<TD style="vertical-align:top" bgcolor="yellow">/g' $MYFILENAMEA
fi

tftp -l $MYFILENAMEA -r /logwiping/$MYFILENAMEB -p 192.168.56.10

sed -i 's/Camara System Wiping Report/Camara System Wiping Report - Press CTRL Q to exit/g' $MYFILENAMEA

firefox $MYFILENAMEA
echo
done