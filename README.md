# dscpclassify
An nftables based service for applying DSCP classifications to connections, compatible with OpenWrt's firewall4 for dynamically setting DSCP packet marks (this only works in OpenWrt 22.03 and above).

This should be used in conjunction with layer-cake SQM queue with ctinfo configured to restore DSCP on the device ingress.
The nft-dscpclassify rules use the last 8 bits of the conntrack mark (0x000000ff).

## Classification modes
The service supports three modes for classifying and DSCP marking connections.

### User rules
The service will first attempt to classify new connections using rules specified by the user in the config file.<br />
These follow a similar syntax to the OpenWrt firewall config and can match upon source/destination ports and IPs, firewall zones etc.<br />
Below is an example:

```
config rule
	option name 'DNS'
	list proto 'tcp'
	list proto 'udp'
	list dest_port '53'
	list dest_port '853'
	list dest_port '5353'
	option class 'cs5'
```
### Client DSCP hinting
The service can be configured to apply the DSCP mark supplied by a non WAN originating client.<br />
This function ignores CS6 and CS7 classes to avoid abuse from inappropriately configed LAN clients such as IoT devices.

### Dynamic classification
Connections that do not match a pre-specified rule will be dynamically classified by the service via three mechanisms:

* Multi-threaded client port detection for detecting P2P traffic
  * These connections are classified as Bulk (LE) by default and therefore prioritised below Best Effort traffic when using the layer-cake qdisc.
* Multi-connection service detection for identifying high-throughput downloads from services such as Steam/Windows Update
  * These connections are classified as High-Throughput (AF13) by default and therefore have a higher drop probability than regular traffic in the Best Effort layer-cake tin.
* Increased priority for low throughput small packet UDP streams such as VoIP/game traffic.
  * These connections are classified as Real-Time (CS4) by default and are processed by layer-cake in the Voice tin.
  
### External classification
The service will respect DSCP classification stored by an external service in a connection's conntrack bits, this could include services such as netifyd.

## Service architecture
![image](https://user-images.githubusercontent.com/46714706/188151111-9167e54d-482e-4584-b43b-0759e0ad7561.png)

## Service installation
To install the dscpclassify service via command line you can use the following:

```
mkdir -p "/etc/dscpclassify.d"
[ -f "/etc/config/dscpclassify" ] && mv /etc/config/dscpclassify /etc/config/dscpclassify.bak
rm -f /etc/dscpclassify.d/main.nft
rm -f /etc/hotplug.d/iface/21-dscpclassify
rm -f /etc/init.d/dscpclassify
wget https://raw.githubusercontent.com/jeverley/dscpclassify/main/etc/config/dscpclassify -P /etc/config
wget https://raw.githubusercontent.com/jeverley/dscpclassify/main/etc/dscpclassify.d/main.nft -P /etc/dscpclassify.d
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
| client_hints | Adopt the DSCP class supplied by a non-WAN client (this exludes CS6 and CS7 classes to avoid abuse) | boolean | 1 |
| threaded_client_kbps | The rate in kBps when a threaded client port (i.e. P2P) is classed as bulk | int | 10 |
| threaded_client_class | The class applied to threaded bulk clients | string | le |
| threaded_service_bytes | The total bytes before a threaded service's connection is classed as high-throughput | int | 1000000 |
| threaded_service_class | The class applied to threaded high-throughput services | string | af13 |
| dynamic_realtime_class | The class applied to dynamic real-time connections | string | cs4 |
| unclassified_bytes | The total bytes before an unclassified connection is ignored by the dynamic classifier | int | 5 * threaded_service_bytes |
| wmm | When enabled the service will mark LAN bound packets with DSCP values respective of WMM (RFC-8325) | boolean |  1 |

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
