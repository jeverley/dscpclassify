# What is DSCP Classify?
DSCP Classify is an nftables based service for applying DSCP class to connections (this only works in OpenWrt 22.03 and above).

This should be used in conjunction with layer-cake SQM queue with ctinfo configured to restore DSCP on the device ingress.
The dscpclassify service uses the last 8 bits of the conntrack mark (0x000000ff).

# Classification modes
The service uses three methods for classifying and DSCP marking connections outlined below.

### 1. User rules
The service will first attempt to classify new connections using rules specified by the user in the config file.

These follow a similar syntax to the OpenWrt firewall config and can match upon source/destination ports and IPs, firewall zones etc.

The rules support the use of nft sets, which could be dynamically updated from external sources such as dnsmasq.

### 2. Client class hinting
The service can be configured to apply the DSCP mark supplied by a non WAN originating client.

This function ignores CS6 and CS7 classes to avoid abuse from inappropriately configed LAN clients such as IoT devices.

### 3. Automatic classification
Connections that do not match a user rule or client class hint will be automatically classified by the service to set their priority.

#### Multi-connection client port detection for detecting P2P traffic
These connections are classified as **Low Effort (LE**) by default and therefore prioritised **below Best Effort** traffic when using the layer-cake qdisc.

#### Multi-threaded service detection for identifying high-throughput downloads from services such as Steam
These connections are classified as **High-Throughput (AF13**) by default and therefore prioritised as follows by cake:
  * **diffserv3/4**: prioritised **equal to Best Effort (CS0**) traffic
  * **diffserv8**: prioritised **below Best Effort (CS0**) traffic, but **above Low Effort (LE**) traffic

## Service architecture
![image](https://user-images.githubusercontent.com/46714706/188151111-9167e54d-482e-4584-b43b-0759e0ad7561.png)

# Service installation
1. To install the main dscpclassify service via command line you can use the following commands:

```
repo="https://raw.githubusercontent.com/jeverley/dscpclassify/main"
mkdir -p "/etc/dscpclassify.d"
if [ ! -f "/etc/config/dscpclassify" ]; then
    wget "$repo/etc/config/dscpclassify" -O "/etc/config/dscpclassify"
else
    wget "$repo/etc/config/dscpclassify" -O "/etc/config/dscpclassify_git"
fi
wget "$repo/etc/dscpclassify.d/main.nft" -O "/etc/dscpclassify.d/main.nft"
wget "$repo/etc/dscpclassify.d/maps.nft" -O "/etc/dscpclassify.d/maps.nft"
wget "$repo/etc/dscpclassify.d/verdicts.nft" -O "/etc/dscpclassify.d/verdicts.nft"
wget "$repo/etc/hotplug.d/iface/21-dscpclassify" -O "/etc/hotplug.d/iface/21-dscpclassify"
wget "$repo/etc/init.d/dscpclassify" -O "/etc/init.d/dscpclassify"
chmod +x "/etc/init.d/dscpclassify"
/etc/init.d/dscpclassify enable
/etc/init.d/dscpclassify start
```
#### _Ingress DSCP marking requires the SQM queue setup script 'layer_cake_ct.qos' and the package 'kmod-sched-ctinfo'._

2. To install the SQM setup script via command line you can use the following commands:

```
repo="https://raw.githubusercontent.com/jeverley/dscpclassify/main"
opkg update
opkg install kmod-sched-ctinfo
wget "$repo/usr/lib/sqm/layer_cake_ct.qos" -O "/usr/lib/sqm/layer_cake_ct.qos"
wget "$repo/usr/lib/sqm/layer_cake_ct.qos.help" -O "/usr/lib/sqm/layer_cake_ct.qos.help"
```
# Configuration
The service configuration is located in '/etc/config/dscpclassify'.

### A working default configuration is provided with the service which should work for most users.

#### Global options
|Option | Description | Type | Default|
|--- | --- | --- | ---|
|class_bulk | The class applied to threaded bulk clients | string | le|
|class_high_throughput | The class applied to threaded high-throughput services | string | af13|
|client_hints | Adopt the DSCP class supplied by a non-WAN client (this exludes CS6 and CS7 classes to avoid abuse) | boolean | 1|
|threaded_client_detection | Automatically and classify threaded client connections (i.e. P2P) as bulk | boolean | 1|
|threaded_service_detection | Automatically and classify threaded service connections (i.e. Windows Update/Steam downloads) as bulk | boolean | 1|
|lan_device | Manually specify devices that the service should treat as LAN | list: string | |
|lan_zone | Manually specify firewall zones that the service should treat as LAN | list: string | lan|
|wan_device | Manually specify devices that the service should treat as WAN | list: string | |
|wan_zone | Manually specify firewall zones that the service should treat as WAN | list: string | wan|
|wmm | When enabled the service will mark LAN bound packets with DSCP values respective of WMM (RFC-8325) | boolean | 0|

#### Advanced global options (not recommended for most users)
|Option | Description | Type | Default|
|--- | --- | --- | ---|
|threaded_client_min_bytes | The total bytes before a threaded client port (i.e. P2P) is classified as bulk | uint | 10000|
|threaded_client_min_connections | The number of established connections for a client port to be considered threaded | uint | 10|
|threaded_service_min_bytes | The total bytes before a threaded service's connection is classed as high-throughput | uint | 1000000|
|threaded_service_min_connections | The number of established connections for a service to be considered threaded | uint | 3|

# User rules
The user rules in '/etc/config/dscpclassify' use the same syntax as OpenWrt's firewall config, the 'class' option is used to specified the desired DSCP.
The OpenWrt firewall syntax is outlined [here](https://openwrt.org/docs/guide-user/firewall/firewall_configuration).

### Example user rule

```
config rule
	option name 'DNS'
	list proto 'tcp'
	list proto 'udp'
	list dest_port '53'
	list dest_port '853'
	list dest_port '5353'
	option class 'cs5'
	option counter '0'
```
The counter option can be enabled to count the number of matched connections for a rule.

# SQM configuration

The **'layer_cake_ct.qos'** queue setup script must be selected for your wan device in SQM setup,

It is important that **Ignore DSCP** on ingress is **Allow** in SQM setup otherwise cake will ignore the service's DSCP classes.

### Below is validated working SQM config for use with the service

| Config parameter | Value |
| ----------- | ----------- |
| qdisc_advanced | 1 |
| squash_dscp | 0, to ensure cake does not remove ingress packet DSCP values|
| **squash_ingress** | **0, to ensure cake looks at packet marks on ingress** |
| qdisc_really_really_advanced | 1 |
| iqdisc_opts | nat dual-dsthost ingress diffserv4 |
| eqdisc_opts | nat dual-srchost ack-filter diffserv4 |
| **script** | **layer_cake_ct.qos** |
<br />

![image](https://user-images.githubusercontent.com/46714706/190709086-c2e820ed-11ed-4be4-8e57-fba4ab6db190.png)
![image](https://user-images.githubusercontent.com/46714706/210797512-a2419605-5bd4-469b-8c99-2d881c2c8706.png)
