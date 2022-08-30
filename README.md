# nft-dscpclassify
An nftables ruleset for OpenWrt's firewall4 for dynamically setting DSCP packet marks (this only works in OpenWrt 22.03 and above).
This should be used in conjunction with layer-cake SQM queue with ctinfo configured to restore DSCP on the device ingress.

**The nftables rule file should be placed in:**

"/etc/nftables.d"

**The SQM queue setup script 'layer_cake_ct.qos' must be placed in:**

"/usr/lib/sqm"

**Your SQM config must use the new 'layer_cake_ct.qos' queue setup script.**

Recommended SQM config for the device:

| Config parameter | Value |
| ----------- | ----------- |
| qdisc_advanced | '1' |
| squash_dscp | '0' |
| squash_ingress | '0' |
| qdisc_really_really_advanced | '1' |
| iqdisc_opts | 'nat dual-dsthost ingress diffserv4' |
| eqdisc_opts | 'nat dual-srchost ack-filter diffserv4' |
| script | 'layer_cake_ct.qos'
