# What is DSCP Classify? ⭐
DSCP Classify is a service for applying DSCP class to connection packets (supporting **OpenWrt 22.03 and above**).\
It can be used with SQM layer cake QoS to manage priority of client connections (VoIP/gaming/downloads/P2P etc) and reduce [Bufferbloat](https://en.wikipedia.org/wiki/Bufferbloat).

The service supports both **automatic** and **user rule** classification of connections.

DSCP Classify can mark LAN destined packets with [WMM mapped](https://datatracker.ietf.org/doc/html/rfc8325#section-4.3) classes to improve transmit prioritisation with 3rd party WiFi access points and switches, see the [wmm_mark_lan](#section-service) service configuration option.

_Users of layer-cake SQM should install the [layer_cake_ct](#layer_cake_ctqos) SQM script for setting DSCP marks on inbound packets, see [SQM Configuration](#sqm-configuration-)❗_

## User Rules 📝
You can create rules to classify new connections in the service [config file](#configuration-%EF%B8%8F).\
These use a similar syntax to the OpenWrt firewall config and can match source and destination ports, addresses, ipsets, firewall zones etc.

More information and examples can be found in the [rules section](#section-rule).

## Automatic Classification 🪄
Connections that don't match a rule will be automatically classified by the service using one of the below methods.

### Client class adoption ✨
The service can automatically adopt the DSCP mark supplied by a non-WAN client.\
By default this ignores classes CS6 and CS7 to avoid abuse from clients such as IoT devices.

### Bulk client detection for P2P traffic 🌎
These connections are one of the largest causes of [Bufferbloat](https://en.wikipedia.org/wiki/Bufferbloat), as a result they are classified as **Low Effort (LE)** by default and therefore prioritised **below Best Effort (BE/DF/CS0)** traffic when using the layer-cake qdisc.

### High Throughput service detection for Steam downloads, cloud storage etc 🚛
Services such as Steam make use of parralel connections to maximise download bandwith, this can also cause bufferbloat and so these connections are classified as **High-Throughput (AF13)** by default and prioritised as follows by cake:
  * **diffserv8**: prioritised **below Best Effort (BE/DF/CS0)** traffic and **above Low Effort (LE)** traffic
  * **diffserv3/4**: prioritised **equal to Best Effort (BE/DF/CS0)** traffic

## Service Architecture 🏗️ 

The dscpclassify service uses the last 8 bits of the conntrack mark (0x000000**ff**), leaving the remaining bits for use by other applications.

<img src="https://user-images.githubusercontent.com/46714706/188151111-9167e54d-482e-4584-b43b-0759e0ad7561.png" width="80%">

# Service Installation ⚙️
To install dscpclassify service via command line you can use the following sets of commands.

### dscpclassify 

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

### layer_cake_ct.qos
#### _Ingress DSCP marking for SQM cake requires installation and [configuration](#sqm-configuration-) of 'layer_cake_ct.qos' and the package 'kmod-sched-ctinfo'❗_

```
repo="https://raw.githubusercontent.com/jeverley/dscpclassify/main"
opkg update
opkg install kmod-sched-ctinfo
wget "$repo/usr/lib/sqm/layer_cake_ct.qos" -O "/usr/lib/sqm/layer_cake_ct.qos"
wget "$repo/usr/lib/sqm/layer_cake_ct.qos.help" -O "/usr/lib/sqm/layer_cake_ct.qos.help"
```
# Configuration ⚙️
The service configuration is located in '/etc/config/dscpclassify'.

**A working default configuration is provided with the service which should work for most users.**

### Section "service"
|Name | Type | Required | Default | Description|
|--- | --- | --- | --- | ---|
|class_low_effort | string | no | le <sup>1</sup> | The default DSCP class applied to low effort connections |
|class_high_throughput | string | no | af13 | The default DSCP class applied to high-throughput connections |
|wmm_mark_lan | boolean | no | 0 | Mark packets going out of LAN interfaces with DSCP values respective of [WMM (RFC-8325)](https://datatracker.ietf.org/doc/html/rfc8325#section-4.3) |
|**Advanced** | | | | _**The below options are typically only required on non-standard setups**_ |
|_lan_zone_ | list | no | lan | Used to specify LAN firewall zones (lan/guest etc) |
|_wan_zone_ | list | no | wan | Used to specify WAN firewall zones |
|_lan_device_ | list | no | | Used to specify LAN network interfaces (L3 physical interface i.e. `br-lan`) |
|_wan_device_ | list | no | | Used to specify WAN network interfaces (L3 physical interface) |

_1. When running on older OpenWrt releases with kernels < 5.13 the service defaults to class CS1 for low effort connections_

### Section "client_class_adoption"
|Name | Type | Required | Default | Description|
|--- | --- | --- | --- | ---|
|enabled | boolean | no | 1 | Adopt the DSCP class supplied by a non-WAN client |
|exclude_class | list | no | cs6, cs7 | Classes to ignore from client class adoption |
|src_ip | list | no | | Include/Exclude source IPs for class adoption, preface excluded IPs with ! |

### Section "bulk_client_detection"
|Name | Type | Required | Default | Description|
|--- | --- | --- | --- | ---|
|enabled | boolean | no | 1 | Detect and classify bulk client connections (i.e. P2P)|
|class | string | no | | Override the service level class_high_throughput setting |
|**Advanced** | | | | _**The default configuration for the below should work for most users**_ |
|_min_connections_ | number | no | 10 | Minimum established connections for a client port to be considered as bulk |
|_min_bytes_ | number | no | 10000 | Minimum bytes before a client port is classified as bulk |

### Section "high_throughput_service_detection"
|Name | Type | Required | Default | Description|
|--- | --- | --- | --- | ---|
|enabled | boolean | no | 1 | Detect and classify high throughput service connections (i.e. Windows Update/Steam downloads) 
|class | string | no | | Override the service level class_high_throughput setting |
|**Advanced** | | | | _**The default configuration for the below should work for most users**_ |
|_min_connections_ | number | no | 3 | Minimum established connections for a service to be considered as high-throughput |
|_min_bytes_ | number | no | 1000000 | Minimum bytes before the connection is classified as high-throughput |

### Section "rule"
The rule sections in `/etc/config/dscpclassify` use the same syntax as OpenWrt's firewal, the **class** option is used to specified the desired DSCP.\
The OpenWrt fw4 rule syntax is outlined in the [OpenWrt Wiki](https://openwrt.org/docs/guide-user/firewall/firewall_configuration#rules), dscpclassify default rules can be viewed [here](https://github.com/jeverley/dscpclassify/blob/main/etc/config/dscpclassify)'. 

The rules support matching source/destination addresses in nft **sets**, these can be dynamically updated from external sources such as dnsmasq.

#### Example user rule 📃

```
config rule
	option name	'DNS'
	list proto	'tcp'
	list proto	'udp'
	list dest_port	'53'
	list dest_port	'853'
	list dest_port	'5353'
	list dest_ip	'8.8.8.8'
	list dest_ip	'2001:4860:4860::8888'
	list dest_ip	'@DoH'
	list dest_ip	'@DoH6'
	option class	'cs5'
	option counter	'0'
```
The counter option can be enabled to count the number of matched connections for a rule.

**Vervsions ≥ 2.0 allow a mix of ipsets, ipv4 and ipv6 addresses.**

### Section "ipset"
The ipset sections in `/etc/config/dscpclassify` use the same syntax as OpenWrt's firewall, they can be used in conjunction with rules for dynamically populated ip matching.\
The OpenWrt fw4 ipset syntax is outlined in the [OpenWrt Wiki](https://openwrt.org/docs/guide-user/firewall/firewall_configuration#options_fw4), dscpclassify default rules can be viewed [here](https://github.com/jeverley/dscpclassify/blob/main/etc/config/dscpclassify).

**Vervsions ≥ 2.0 will attempt to autodetect an ipset's family if the option is not specified.**

#### Example ipset and rule 📃

```
config ipset
	option name 'ms_teams'
	option interval '1'
	list entry '13.107.64.0/18'
	list entry '52.112.0.0/14'
	list entry '52.122.0.0/15'

config ipset
	option name 'ms_teams6'
	option family 'ipv6'
	option interval '1'
	list entry '2603:1063::/39'

config rule
	option name 'Microsoft Teams Voice'
	option proto 'udp'
	option src_port '50000-50019'
	option dest_port '3478-3481'
	list dest_ip '@ms_teams'
	list dest_ip '@ms_teams6'
	option class 'ef'
```


# SQM configuration 🚀

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

<img src="https://user-images.githubusercontent.com/46714706/190709086-c2e820ed-11ed-4be4-8e57-fba4ab6db190.png" width="50%">
<img src="https://user-images.githubusercontent.com/46714706/210797512-a2419605-5bd4-469b-8c99-2d881c2c8706.png" width="50%">
