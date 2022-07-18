#!/bin/bash

source  /etc/switch-wifi.conf

date
FORCE_SWITCH=$1
IP=$(ip addr show dev wlan1 | grep inet -w | awk '{print $2}')
current_file=$(readlink -f /etc/wpa_supplicant/wpa_supplicant.conf)

echo current profile $current_file
if [ "$FORCE_SWITCH" = "force" ]; then 
	shift; 
else
	ping -c 5 $ping_domain
	if [ $? -eq 0 ]; then
		echo "Internet is working no switching required"
		exit 1
	else
		FORCE_SWITCH=force
	fi
fi

if [ "$FORCE_SWITCH" != "force" -a -n "$IP" ]; then
	echo "Link is up with connection $current_file"
	exit 0
fi

order=("${wpa_order[@]}")

for i in $(seq 0 ${#order[@]})
do
	if [ $((i+1)) -eq ${#order[@]} ]; then
		next_file=${order[0]}
	else
		next_file=${order[$((i+1))]}
	fi
	if [ ! -e $current_file -o $current_file = "/etc/wpa_supplicant/wpa_supplicant.conf.${order[$i]}" ]; then
		current_file=/etc/wpa_supplicant/wpa_supplicant.conf.${next_file}
		break;
	fi
done

ln -sf $current_file /etc/wpa_supplicant/wpa_supplicant.conf
echo new profile $current_file

systemctl stop wpa_supplicant
pkill wpa_supplicant
systemctl restart networking
