#!/bin/bash

NETNS_FILES="/home/lab/ns/*"

ns_list=$(ip netns list)

for f in $NETNS_FILES; do
  ns=$(echo $f | cut -d "/" -f 5)
  if [[ "$ns_list" == *"$ns"* ]]
  then
    printf "\n******* The $ns network namespace already exists. Checking if re-configuration is needed. *******\n"
    while read line; do
    interface=$(echo $line | awk '{print $1}')
    vlan=$(echo $line | awk '{print $2}')
    ipaddress=$(echo $line | awk '{print $3}')
    tmp_interface=$(ip netns exec $ns ip a | egrep "vlan.*if" | awk '{print $2}' | sed 's/\@.*//')
    tmp_vlan=$(ip netns exec $ns ip a | egrep "vlan.*if" | awk '{print $2}' | sed 's/vlan\.//' | sed 's/\@.*//')
    tmp_ipaddress=$(ip netns exec $ns ip a | egrep "inet 192" | awk '{print $2}')
    if [[ ( "$interface" != "$tmp_interface" ) || ( "$vlan" != "$tmp_vlan" ) || ( "$ipaddress" != "$tmp_ipaddress" ) ]]
    then
      printf "\n******* An interface in the $ns network namespace has changed. *******\n"
      printf "\n************************ Reconfiguring **********************\n"
      ip netns exec $ns ip link del $tmp_interface
      ip link add link ens4 name $interface type vlan protocol 802.1Q id $vlan
      ip link set $interface netns $ns
      ip netns exec $ns ip link set dev $interface up
      ip netns exec $ns ip addr add $ipaddress dev $interface
      printf "\n******* The $interface interafce in the $ns network namespace was reconfigured. *******\n\n"
    else
      printf "\n******* The $ns network namespace already exists and no reconfiguration is needed. *******\n"
      printf "\n*************************** Skipping ****************************\n\n"
    fi
    done < /home/lab/ns/$ns
    continue
  fi
  ip netns add $ns
  while read line; do
    interface=$(echo $line | awk '{print $1}')
    vlan=$(echo $line | awk '{print $2}')
    ipaddress=$(echo $line | awk '{print $3}')
    printf "\n******* Creatig and configuring the $ns network namespace. *******\n"
    ip link add link ens4 name $interface type vlan protocol 802.1Q id $vlan
    ip link set $interface netns $ns
    ip netns exec $ns ip link set dev $interface up
    ip netns exec $ns ip addr add $ipaddress dev $interface
    printf "\n******* Configured $interface interface in $ns network namespace *******\n"
    printf "\n******* $interface interface is in $ns network namespace and has $ipaddress address *******\n\n"
  done < /home/lab/ns/$ns
done
