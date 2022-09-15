# nft-dscpclassify
An nftables based service for applying DSCP classifications to connections, compatible with OpenWrt's firewall4 for dynamically setting DSCP packet marks (this only works in OpenWrt 22.03 and above).

This should be used in conjunction with layer-cake SQM queue with ctinfo configured to restore DSCP on the device ingress.
The nft-dscpclassify rules use the last 8 bits of the conntrack mark (0x000000ff).

![image](https://user-images.githubusercontent.com/46714706/188151111-9167e54d-482e-4584-b43b-0759e0ad7561.png)

To install the dscpclassify service via command line you can use the following:

```
opkg update
mkdir -p "/etc/dscpclassify.d"
[ -f "/etc/config/dscpclassify" ] && mv /etc/config/dscpclassify /etc/config/dscpclassify.bak
rm -f /etc/dscpclassify.d/dscpclassify.nft
rm -f /etc/init.d/dscpclassify
wget https://raw.githubusercontent.com/jeverley/nft-dscpclassify/main/etc/config/dscpclassify -P /etc/config
wget https://raw.githubusercontent.com/jeverley/nft-dscpclassify/main/etc/dscpclassify.d/dscpclassify.nft -P /etc/dscpclassify.d
wget https://raw.githubusercontent.com/jeverley/nft-dscpclassify/main/etc/init.d/dscpclassify -P /etc/init.d
chmod +x "/etc/init.d/dscpclassify"
/etc/init.d/dscpclassify enable
/etc/init.d/dscpclassify start
```

**The dscpclassify user rule syntax in '/etc/config/dscpclassify' follows the same syntax as OpenWrt firewall rules, with a 'dscp' option instead of 'target'**

https://openwrt.org/docs/guide-user/firewall/firewall_configuration

An working default configuration is provided with the service.


**To support ingress (download) DSCP marking you must use the SQM queue setup script 'layer_cake_ct.qos', this requires the package kmod-sched-ctinfo**

To install the layer_cake_ct qdisc via command line you can use the following:

```
opkg update
opkg install kmod-sched-ctinfo
rm -f /usr/lib/sqm/layer_cake_ct.qos
rm -f /usr/lib/sqm/layer_cake_ct.qos.help
wget https://raw.githubusercontent.com/jeverley/nft-dscpclassify/main/usr/lib/sqm/layer_cake_ct.qos -P /usr/lib/sqm
wget https://raw.githubusercontent.com/jeverley/nft-dscpclassify/main/usr/lib/sqm/layer_cake_ct.qos.help -P /usr/lib/sqm
```


**Tested working SQM config for the script:**

| Config parameter | Value |
| ----------- | ----------- |
| qdisc_advanced | '1' |
| squash_dscp | '0' |
| squash_ingress | '0' |
| qdisc_really_really_advanced | '1' |
| iqdisc_opts | 'nat dual-dsthost ingress diffserv4' |
| eqdisc_opts | 'nat dual-srchost ack-filter diffserv4' |
| script | 'layer_cake_ct.qos'
