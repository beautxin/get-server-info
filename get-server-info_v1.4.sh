#!/bin/bash  
#****************************************
#This script is used to check the server    
# Write by Ligong at 2019-07-18
#How to use:
#Copy this script to the server you want to check, and then execute 'sh get-server-info_v1.2.sh’
#It will get the information of the test server, such as OS, CPU, Disk, Memory.
#Also, it will generage log at /tmp/$hostname/$datetime.info, that you can check offline.

#Change log:
# Modified by ZhuFeihu at 2019-08-07
# add ssh command which we can get informations of remote servers by ssh. 
# add disk_flag which cancle the space of ouput log.
# add Network port Speed module
# change the memory function, make it more visible. Modified at 2019-09-19
#****************************************

add_color_str(){
    str=$1
    echo -e "\033[1;32m ${str}\033[0m"

}

System_info() {    
    echo "**********************************************"
    echo -e "\033[40;44m System info: \033[0m"
    echo    
    echo "        HostName:             `hostname`"
    echo "        Platform :            `uname -i`"
    #echo -e "        System-release :        \033[1;32m `cat /etc/redhat-release`\033[0m"
    echo -e "        System-release :     \c" 
    if [ `uname -i` = "aarch64" ];then
        add_color_str "`cat /etc/issue|tr -s '\n'`"
    elif [ `uname -i` = "x86_64" ];then
	if  [[ `uname -a` =~ "Ubuntu" ]];then
            add_color_str "`cat /etc/issue|tr -s '\n'`"
	else
            add_color_str "`/etc/redhat-release`"
	fi
    fi

    echo "        Kernel-release :      `uname -a|awk '{print $1,$3}'`"
    #echo "`dmidecode |grep -A4 'System Information' | grep -A1 Manufacturer`"
    echo "        Manufacturer :        `dmidecode |grep -A4 'System Information'|grep 'Manufacturer'|awk -F ": " '{print $2}'`"
    echo "        Product Name :        `dmidecode |grep -A4 'System Information'|grep 'Product'|awk -F ": " '{print $2}'|sed '2,$s/^/                              /g'`"
    echo    
}    
         
Cpu_info() {    
    echo "**********************************************"
    echo -e "\033[40;44m CPU info: \033[0m"
    echo    
    printf  "        CPU Module name :    \033[1;32m `cat /proc/cpuinfo | grep "model name" | uniq |awk -F': ' '{print $2}'` \033[0m\n" # change Frequency to CPU Module name
    echo -e "        Physical Count :     \033[1;32m `cat /proc/cpuinfo | grep -w "physical id" | sort -u| wc -l` \033[0m"
    echo    
}    
         
Mem_info() {    
    echo "**********************************************"
    echo -e "\033[40;44m Memory info: \033[0m"
    echo    
    echo "        Manufacturer:         `dmidecode |grep -A16 "Memory Device$" | grep Manufacturer | awk '{if($2!~/NO/) print $0}'|uniq |awk -F": " '{print $2}'|sed '2,$s/^/                              /g'`" # Manufacturer
    echo -e "        Type:                \033[1;32m `dmidecode |grep -A16 "Memory Device$" | grep Type: | awk '{if($2!~/Unknown/) print $0}' | uniq|awk -F": " '{print $2}'` \033[0m" # type
    echo -e "        Speed:               \033[1;32m `dmidecode |grep -A16 "Memory Device$" | grep Speed | awk '{if($2!~/Unknown/) print $0}' | uniq|awk -F": " '{print $2}'` \033[0m" # speed
    echo -e "        Count:               \033[1;32m `dmidecode |grep -A16 "Memory Device$"|grep Size|awk '{if($2!~/No/) print $0}'|wc -l` \033[0m" # count
    dmidecode |grep -A20 "Memory Device$"|grep Size|sed '{s/^*//g};{/No/d}'|sed 's/: /:                 /g' # size
    echo    
    echo "**********************************************"
}    
         
Disk_info() {    
    echo -e "\033[40;44m Disk info: \033[0m"
    echo    
    echo "        Count : `lsblk -d | grep disk |wc -l`             Disk : `lsblk -d | grep disk |awk '{print $1}'|tr "\n" ","|sed -e 's/,$/\n/'`"
    echo ""
    echo ""
    for disks in `lsblk -d | grep disk |awk '{print $1}'`
    do
        echo "        Disk [$disks]            `fdisk -l /dev/$disks 2>/dev/null | egrep -o '(/dev/[^,]*),' | egrep -o '([^,]*)'|awk '{print $2,$3}'`"

        #for i in 'Vendor' 'Product' 'Capacity' 'Model Family' 'Device Model' 'Serial Number' 'LU WWN Device Id' 'SATA Version is'
        for i in 'Vendor' 'Product' 'Model Family' 'Device Model' 'Serial Number:' 'LU WWN Device Id' 'SATA Version is'
            do
                disk_flag=`smartctl -i /dev/$disks | grep "$i"`
                if [[ $disk_flag != '' ]];then   # test if disk_flag is Null
                    echo "        $disk_flag"
                fi
        #	echo "        `smartctl -i /dev/$disks | grep "$i"`"
	    done
        echo 
    done
    #echo "        `lsblk -d | grep disk |awk '{print $1,$4}'`" # 1000 not 1024
    echo "**********************************************"
}    

Network_info() {
    echo -e "\033[40;44m Network port speed: \033[0m"    # try to get Speed of the network port
    echo 
    for eths in `ip a |grep "^[0-9]"|awk -F ":" '{print $2}'`
    do 
        if [[ `ip link show|grep "${eths}:"|awk -F ' ' '{print $9}'` == "UP" ]];then
           #echo -e "        \033[1;32m$eths `ethtool $eths|grep "Speed"|sed 's/^[[:space:]]//g'`\033[0m"
           echo -e "        $eths Speed:          \033[1;32m `ethtool $eths|grep "Speed"|sed 's/^[[:space:]]//g'|awk -F ": " '{print $2}'` \033[0m"
        fi
    done
    echo
    echo "**********************************************"
    echo -e "\033[40;44m NETWORK info: \033[0m"
    echo
    if [ `lspci|grep Ethernet|awk -F "Ethernet controller:" {'print $2'}|awk -F \( {'print $1'}|uniq|wc -l` -eq 1 ]
    then
        echo -e "        `lspci|grep Ethernet|awk -F "Ethernet controller:" {'print $2'}|awk -F \( {'print $1'}|wc -l` * `lspci|grep Ethernet|awk -F "Ethernet controller:" {'print $2'}|awk -F \( {'print $1'}|uniq`"
    else
        echo -e "        `lspci|grep Ethernet|awk -F "Ethernet controller:" {'print $2'}|awk -F \( {'print $1'}|sed '2,$s/^/        /g'`"  #add sed
    fi
    echo
    echo "**********************************************"
}
#######execute funcitons area
D="/tmp/$(hostname)"
if [ ! -d $D ]
then
	mkdir $D
fi
F="${D}/$(hostname)_$(date +%Y-%m-%d_%T).info" # change %m%d%y to %Y-%m-%d
if [ ! -f $F ]
then
	touch $F
fi
System_info | tee -a $F
Cpu_info | tee -a $F
Mem_info | tee -a $F
Disk_info | tee -a $F
Network_info | tee -a $F
