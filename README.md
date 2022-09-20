# dscpclassify
An nftables based service for applying DSCP classifications to connections, compatible with OpenWrt's firewall4 for dynamically setting DSCP packet marks (this only works in OpenWrt 22.03 and above).

This should be used in conjunction with layer-cake SQM queue with ctinfo configured to restore DSCP on the device ingress.
The nft-dscpclassify rules use the last 8 bits of the conntrack mark (0x000000ff).

![image](https://user-images.githubusercontent.com/46714706/188151111-9167e54d-482e-4584-b43b-0759e0ad7561.png)

<br />

## Service installation
To install the dscpclassify service via command line you can use the following:

```
mkdir -p "/etc/dscpclassify.d"
[ -f "/etc/config/dscpclassify" ] && mv /etc/config/dscpclassify /etc/config/dscpclassify.bak
rm -f /etc/dscpclassify.d/dscpclassify.nft
rm -f /etc/hotplug.d/iface/21-dscpclassify
rm -f /etc/init.d/dscpclassify
wget https://raw.githubusercontent.com/jeverley/dscpclassify/main/etc/config/dscpclassify -P /etc/config
wget https://raw.githubusercontent.com/jeverley/dscpclassify/main/etc/dscpclassify.d/dscpclassify.nft -P /etc/dscpclassify.d
wget https://raw.githubusercontent.com/jeverley/dscpclassify/main/etc/hotplug.d/iface/21-dscpclassify -P /etc/hotplug.d/iface
wget https://raw.githubusercontent.com/jeverley/dscpclassify/main/etc/init.d/dscpclassify -P /etc/init.d
chmod +x "/etc/init.d/dscpclassify"
/etc/init.d/dscpclassify enable
/etc/init.d/dscpclassify start
```

Ingress DSCP marking requires the SQM queue setup script 'layer_cake_ct.qos' and the package 'kmod-sched-ctinfo'.

To install these via command line you can use the following:

```
opkg update
opkg install kmod-sched-ctinfo
rm -f /usr/lib/sqm/layer_cake_ct.qos
rm -f /usr/lib/sqm/layer_cake_ct.qos.help
wget https://raw.githubusercontent.com/jeverley/dscpclassify/main/usr/lib/sqm/layer_cake_ct.qos -P /usr/lib/sqm
wget https://raw.githubusercontent.com/jeverley/dscpclassify/main/usr/lib/sqm/layer_cake_ct.qos.help -P /usr/lib/sqm
```

The 'layer_cake_ct.qos' qdisc setup script must then be selected for your wan device in SQM setup:

![image](https://user-images.githubusercontent.com/46714706/190709086-c2e820ed-11ed-4be4-8e57-fba4ab6db190.png)


<br />

## Service configuration
The user rules in '/etc/config/dscpclassify' use the same syntax as OpenWrt's firewall config, the 'class' option is used to specified the desired DSCP.

The OpenWrt firewall syntax is outlined here https://openwrt.org/docs/guide-user/firewall/firewall_configuration

A working default configuration is provided with the service.

**The service supports the following global classification options:**

|  Config option | Description  | Type  | Default  |
|---|---|---|---|
| lan_hints | Adopt the DSCP class set by a LAN client (this exludes CS6 and CS7 classes to avoid abuse)  | boolean  |  1 |
| threaded_client_kbps | The rate in kBps when a threaded client port (i.e. P2P) is classed as bulk (cs1)  | int  |  10 |
| threaded_service_bytes | The total bytes before a threaded service's connections are classed as high-throughput (af13)  | int  |  1000000 |
| wmm  | When enabled the service will mark LAN bound packets with DSCP values respective of WMM (RFC-8325)  | boolean  |  1 |

<br />
<br />

**Below is a tested working SQM config for use with the service:**

| Config parameter | Value |
| ----------- | ----------- |
| qdisc_advanced | '1' |
| squash_dscp | '0' |
| squash_ingress | '0' |
| qdisc_really_really_advanced | '1' |
| iqdisc_opts | 'nat dual-dsthost ingress diffserv4' |
| eqdisc_opts | 'nat dual-srchost ack-filter diffserv4' |
| script | 'layer_cake_ct.qos'
