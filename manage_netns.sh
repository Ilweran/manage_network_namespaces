#!/bin/bash

NETNS_FILES="/home/lab/ns/*"

ns_list=$(ip netns list)


edit_netns_interface () {
  
  # $1 - netns, $2 - int, $3 - vlan_id, $4 - ip_add
  ip netns exec $1 ip link del $2
  ip link add link ens4 name $2 type vlan protocol 802.1Q id $3
  ip link set $2 netns $1
  ip netns exec $1 ip link set dev $2 up
  ip netns exec $1 ip addr add $4 dev $2

}

create_configure_netns () {

  # $1 - netns, $2 - int, $3 - vlan_id, $4 - ip_add
  if [[ "$ns_list" != *"$ns"* ]]
  then
    ip netns add $ns
  fi
  ip link add link ens4 name $2 type vlan protocol 802.1Q id $3
  ip link set $2 netns $1
  ip netns exec $1 ip link set dev $2 up
  ip netns exec $1 ip addr add $4 dev $2

}

ip link set dev ens4 up

for f in $NETNS_FILES; do
  ns=$(echo $f | cut -d "/" -f 5)
  if [[ "$ns_list" == *"$ns"* ]]
  then
    printf "\n***************************************************************************************\n"
    printf "\n** The $ns network namespace already exists. Checking if re-configuration is needed. **\n"
    printf "\n***************************************************************************************\n"
    tmp_interface=$(ip netns exec $ns ip a | egrep "vlan.*if" | awk '{print $2}' | sed 's/\@.*//')
    tmp_vlan=$(ip netns exec $ns ip a | egrep "vlan.*if" | awk '{print $2}' | sed 's/vlan\.//' | sed 's/\@.*//')
    tmp_ipaddress=$(ip netns exec $ns ip a | egrep "inet 192" | awk '{print $2}')
    while read line; do
    interface=$(echo $line | awk '{print $1}')
    vlan=$(echo $line | awk '{print $2}')
    ipaddress=$(echo $line | awk '{print $3}')
    if [[ ( "$interface" != "$tmp_interface" ) || ( "$vlan" != "$tmp_vlan" ) || ( "$ipaddress" != "$tmp_ipaddress" ) ]]
    then
      printf "\n***************************************************************************************\n"
      printf "\n**                 An interface in the $ns network namespace has changed.            **\n"
      printf "\n***************************************************************************************\n"
      printf "\n***************************************************************************************\n"
      printf "\n**                                  Reconfiguring                                    **\n"
      printf "\n***************************************************************************************\n"
      edit_netns_interface "$ns" "$interface" "$vlan" "$ipaddress"
      printf "\n***************************************************************************************\n"
      printf "\n**      The $interface interafce in the $ns network namespace was reconfigured.      **\n"
      printf "\n***************************************************************************************\n\n"
    else
      printf "\n***************************************************************************************\n"
      printf "\n**      The $ns network namespace already exists and no reconfiguration is needed.   **\n"
      printf "\n***************************************************************************************\n"
      printf "\n***************************************************************************************\n"
      printf "\n**                                    Skipping...                                    **\n"
      printf "\n***************************************************************************************\n\n"
    fi
    done < /home/lab/ns/$ns
    continue
  fi
  while read line; do
    interface=$(echo $line | awk '{print $1}')
    vlan=$(echo $line | awk '{print $2}')
    ipaddress=$(echo $line | awk '{print $3}')
    printf "\n***************************************************************************************\n"
    printf "\n**                 Creatig and configuring the $ns network namespace.                **\n"
    printf "\n***************************************************************************************\n"
    create_configure_netns "$ns" "$interface" "$vlan" "$ipaddress"
    printf "\n***************************************************************************************\n"
    printf "\n**             Configured $interface interface in $ns network namespace.             **\n"
    printf "\n***************************************************************************************\n"
    printf "\n***************************************************************************************\n"
    printf "\n**    $interface interface is in $ns network namespace and has $ipaddress address    **\n"
    printf "\n***************************************************************************************\n\n"
  done < /home/lab/ns/$ns
done
