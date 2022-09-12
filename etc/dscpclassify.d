table inet dscpclassify {
    ## DSCP classify configuration
    define lan = { br-lan }
    define bytes_ht = 1000000

    ## DSCP matching rules for proto, sports, daddr
    map rules_proto_dport_daddr {
        type inet_proto . inet_service . ipv4_addr : verdict
        flags interval
        elements = {
            udp . 1000-1150 . 13.104.0.0/14 : goto ct_set_af41, # Xbox Cloud Gaming (UK servers)
        }
    }

    ## DSCP matching rules for proto, sports, dports
    map rules_proto_sport_dport {
        type inet_proto . inet_service . inet_service : verdict
        flags interval
        elements = {
            udp . 50000-50019 . 3478-3481 : goto ct_set_ef,     # Teams voice
            udp . 50020-50039 . 3478-3481 : goto ct_set_af41,   # Teams video
            udp . 50040-50059 . 3478-3481 : goto ct_set_af21,   # Teams sharing
        }
    }

    ## DSCP matching rules for proto, dports
    map rules_proto_dport {
        type inet_proto . inet_service : verdict
        flags interval
        elements = {
            tcp . 53 : goto ct_set_cs5,             # DNS
            tcp . 853 : goto ct_set_cs5,            # DNS
            tcp . 5353 : goto ct_set_cs5,           # DNS
            udp . 53 : goto ct_set_cs5,             # DNS
            udp . 853 : goto ct_set_cs5,            # DNS
            udp . 5353 : goto ct_set_cs5,           # DNS
            udp . 68 : goto ct_set_cs5,             # DHCP
            udp . 123 : goto ct_set_cs5,            # NTP
            tcp . 49006 : goto ct_set_af41,         # GeForce NOW
            udp . 49003-49006 : goto ct_set_af41,   # GeForce NOW
            tcp . 44700-44899 : goto ct_set_af41,   # Stadia
            udp . 44700-44899 : goto ct_set_af41,   # Stadia
            tcp . 22 : goto ct_set_cs2,             # SSH
        }
    }

    ## DSCP matching rules for proto
    map rules_proto {
        type inet_proto : verdict
        #elements = { icmp : goto ct_set_cs5 }
    }

    ## Masks for extracting/storing data in the conntrack mark
    define ct_dscp = 0x0000003f
    define ct_dyn = 0x00000080
    define ct_dyn_dscp = 0x000000ff
    define ct_ht = 0x00000040
    define ct_unused = 0xffffff00
    define ct_unused_dyn = 0xffffff80
    define ct_unused_dyn_dscp = 0xffffffbf

    ## DSCP classification values
    define cs0 = 0
    define cs1 = 8
    define af11 = 10
    define af12 = 12
    define af13 = 14
    define cs2 = 16
    define af21 = 18
    define af22 = 20
    define af23 = 22
    define cs3 = 24
    define af31 = 26
    define af32 = 28
    define af33 = 30
    define cs4 = 32
    define af41 = 34
    define af42 = 36
    define af43 = 38
    define cs5 = 40
    define va = 44
    define ef = 46
    define cs6 = 48
    define cs7 = 56

    ## Conntrack mark to DSCP class vmap
    map ct_dscp {
        type mark : verdict
        elements = {
            $cs0 : goto dscp_set_cs0,
            $cs1 : goto dscp_set_cs1,
            $af11 : goto dscp_set_af11,
            $af12 : goto dscp_set_af12,
            $af13 : goto dscp_set_af13,
            $cs2 : goto dscp_set_cs2,
            $af21 : goto dscp_set_af21,
            $af22 : goto dscp_set_af22,
            $af23 : goto dscp_set_af23,
            $cs3 : goto dscp_set_cs3,
            $af31 : goto dscp_set_af31,
            $af32 : goto dscp_set_af32,
            $af33 : goto dscp_set_af33,
            $cs4 : goto dscp_set_cs4,
            $af41 : goto dscp_set_af41,
            $af42 : goto dscp_set_af42,
            $af43 : goto dscp_set_af43,
            $cs5 : goto dscp_set_cs5,
            $va : goto dscp_set_va,
            $ef : goto dscp_set_ef,
            $cs6 : goto dscp_set_cs6,
            $cs7 : goto dscp_set_cs7,
        }
    }

    ## Conntrack mark to WMM class vmap (RFC-8325)
    map ct_wmm {
        type mark : verdict
        elements = {
            $cs0 : goto dscp_set_cs0,   # WMM BE
            $cs1 : goto dscp_set_cs1,   # WMM BK
            $af11 : goto dscp_set_cs0,  # WMM BE
            $af12 : goto dscp_set_cs0,  # WMM BE
            $af13 : goto dscp_set_cs0,  # WMM BE
            $cs2 : goto dscp_set_cs0,   # WMM BE
            $af21 : goto dscp_set_cs3,  # WMM BE
            $af22 : goto dscp_set_cs3,  # WMM BE
            $af23 : goto dscp_set_cs3,  # WMM BE
            $cs3 : goto dscp_set_cs4,   # WMM VI
            $af31 : goto dscp_set_cs4,  # WMM VI
            $af32 : goto dscp_set_cs4,  # WMM VI
            $af33 : goto dscp_set_cs4,  # WMM VI
            $cs4 : goto dscp_set_cs4,   # WMM VI
            $af41 : goto dscp_set_cs4,  # WMM VI
            $af42 : goto dscp_set_cs4,  # WMM VI
            $af43 : goto dscp_set_cs4,  # WMM VI
            $cs5 : goto dscp_set_cs5,   # WMM VI
            $va : goto dscp_set_cs6,    # WMM VO
            $ef : goto dscp_set_cs6,    # WMM VO
            $cs6 : goto dscp_set_cs7,   # WMM VO
            $cs7 : goto dscp_set_cs7,   # WMM VO
        }
    }

    ## DSCP class to conntrack mark vmap
    map dscp_ct {
        type dscp : verdict
        elements = {
            cs0 : goto ct_set_cs0,
            cs1 : goto ct_set_cs1,
            af11 : goto ct_set_af11,
            af12 : goto ct_set_af12,
            af13 : goto ct_set_af13,
            cs2 : goto ct_set_cs2,
            af21 : goto ct_set_af21,
            af22 : goto ct_set_af22,
            af23 : goto ct_set_af23,
            cs3 : goto ct_set_cs3,
            af31 : goto ct_set_af31,
            af32 : goto ct_set_af32,
            af33 : goto ct_set_af33,
            cs4 : goto ct_set_cs4,
            af41 : goto ct_set_af41,
            af42 : goto ct_set_af42,
            af43 : goto ct_set_af43,
            cs5 : goto ct_set_cs5,
            44 : goto ct_set_va,
            ef : goto ct_set_ef,
            cs6 : goto ct_set_cs6,
            cs7 : goto ct_set_cs7,
        }
    }

    ## Classify connections to the router
    chain hook_input {
        type filter hook input priority 2; policy accept
        ct mark and $ct_dyn_dscp == 0 ct direction original jump dscp_match
        ct mark and $ct_dyn == $ct_dyn jump dscp_dynamic
    }

    ## Classify and DSCP mark connections from/forwarded via the router
    chain hook_postrouting {
        type filter hook postrouting priority 2; policy accept
        ct mark and $ct_dyn_dscp == 0 ct direction original jump dscp_match
        ct mark and $ct_dyn == $ct_dyn jump dscp_dynamic
        oifname $lan ct mark and $ct_dscp vmap @ct_wmm
        ct mark and $ct_dscp vmap @ct_dscp
    }

    chain dscp_match {
        ## Match packets against user defined rules
        meta l4proto . th dport . ip daddr vmap @rules_proto_dport_daddr
        meta l4proto . th sport . th dport vmap @rules_proto_sport_dport
        meta l4proto . th dport vmap @rules_proto_dport
        meta l4proto vmap @rules_proto

        ## Store any LAN client's specified DSCP (excluding CS6/7) in the conntrack mark (comment out if undesired)
        iifname $lan ip dscp != { cs0, cs6, cs7 } ip dscp vmap @dscp_ct
        iifname $lan ip6 dscp != { cs0, cs6, cs7 } ip6 dscp vmap @dscp_ct

        ## Unclassified packets get dynamic conntrack mark
        ct mark set ct mark and $ct_unused or $ct_dyn
    }

    ## Dynamically categorise connections
    chain dscp_dynamic {
        meta l4proto != { tcp, udp } return

        ## Detect connection threading by counting new connections
        ct packets < 2 goto dscp_detect_threading

        ## Assess threaded service connections for downgrade to High-Throughput class (AF11)
        meta l4proto . ip saddr . ip daddr and 255.255.255.0 . th dport @threaded_services goto threaded_service
        meta l4proto . ip6 saddr . ip6 daddr and ffff:ffff:ffff:: . th dport @threaded_services6 goto threaded_service
        meta l4proto . ip daddr . ip saddr and 255.255.255.0 . th sport @threaded_services goto threaded_service_response
        meta l4proto . ip6 daddr . ip6 saddr and ffff:ffff:ffff:: . th sport @threaded_services6 goto threaded_service_response

        ## Assess threaded client connections (i.e. P2P) for downgrade to Bulk class (CS1)
        meta l4proto . ip saddr . th sport @threaded_clients goto threaded_client
        meta l4proto . ip6 saddr . th sport @threaded_clients6 goto threaded_client
        meta l4proto . ip daddr . th dport @threaded_clients goto threaded_client_response
        meta l4proto . ip6 daddr . th dport @threaded_clients6 goto threaded_client_response

        ## Assess UDP packets for Real-Time class (CS4)
        meta l4proto udp ct state != new th dport != { 80, 443 } th sport != { 80, 443 } jump dscp_dynamic_rt

        ## Mark unclassified >10mB connections as non-dynamic Best Effort (CS0)
        ct mark and $ct_dscp == 0 ct bytes > 10000000 ct mark set ct mark and $ct_unused or $ct_ht
    }

    chain dscp_dynamic_rt {
        ## Small random chance of removing the high-throughput mark from connections
        ct mark and $ct_ht == $ct_ht numgen random mod 10000 < 50 ct mark set ct mark and $ct_unused_dyn_dscp

        ## Mark connections exceeding 200pps as high-throughput
        meter udpht { ip saddr . ip daddr . th sport . th dport limit rate over 200/second burst 100 packets } ct mark set ct mark and $ct_unused_dyn or $ct_ht return
        meter udpht6 { ip6 saddr . ip6 daddr . th sport . th dport limit rate over 200/second burst 100 packets } ct mark set ct mark and $ct_unused_dyn or $ct_ht return

        ## Prioritize small packet flows as real-time (CS4)
        ct mark and $ct_ht == 0 ct avgpkt 0-450 ct mark set ct mark and $ct_unused_dyn or $cs4 return

        ## Any remaining packets are Best Effort (CS0)
        ct mark set ct mark and $ct_unused_dyn or $cs0
    }

    ## Mark high-throughput threaded connections to a service as AF11
    chain threaded_service {
        ct bytes < $bytes_ht return
        ct mark set ct mark and $ct_unused_dyn or $af11
        update @threaded_services { meta l4proto . ip saddr . ip daddr and 255.255.255.0 . th dport timeout 60s } return
        update @threaded_services6 { meta l4proto . ip6 saddr . ip6 daddr and ffff:ffff:ffff:: . th dport timeout 60s }
    }

    ## Mark high-throughput threaded connections to a service as AF11
    chain threaded_service_response {
        ct bytes < $bytes_ht return
        ct mark set ct mark and $ct_unused_dyn or $af11
        update @threaded_services { meta l4proto . ip daddr . ip saddr and 255.255.255.0 . th sport timeout 60s } return
        update @threaded_services6 { meta l4proto . ip6 daddr . ip6 saddr and ffff:ffff:ffff:: . th sport timeout 60s }
    }

    ## Mark threaded bulk clients as CS1
    chain threaded_client {
        meter bcsport { meta l4proto . ip saddr . th sport limit rate over 10 kbytes/second } update @threaded_clients { meta l4proto . ip saddr . th sport timeout 300s } ct mark set ct mark and $ct_unused_dyn or $cs1 return
        meter bcsport6 { meta l4proto . ip6 saddr . th sport limit rate over 10 kbytes/second } update @threaded_clients6 { meta l4proto . ip6 saddr . th sport timeout 300s } ct mark set ct mark and $ct_unused_dyn or $cs1
    }

    ## Mark threaded bulk clients as CS1
    chain threaded_client_response {
        meter bcdport { meta l4proto . ip daddr . th dport limit rate over 10 kbytes/second } update @threaded_clients { meta l4proto . ip daddr . th dport timeout 300s } ct mark set ct mark and $ct_unused_dyn or $cs1 return
        meter bcdport6 { meta l4proto . ip6 saddr . th sport limit rate over 10 kbytes/second } update @threaded_clients6 { meta l4proto . ip6 daddr . th dport timeout 300s } ct mark set ct mark and $ct_unused_dyn or $cs1
    }

    chain dscp_detect_threading {
        ## Detect multiple connections being opened to a service from a single source address
        meter tsdetect { meta l4proto . ip saddr . ip daddr and 255.255.255.0 . th dport timeout 5s limit rate over 2/minute } add @threaded_services { meta l4proto . ip saddr . ip daddr and 255.255.255.0 . th dport timeout 5s }
        meter tsdetect6 { meta l4proto . ip6 saddr . ip6 daddr and ffff:ffff:ffff:: . th dport timeout 5s limit rate over 2/minute } add @threaded_services6 { meta l4proto . ip6 saddr . ip6 daddr and ffff:ffff:ffff:: . th dport timeout 5s }

        ## Detect multiple connections being opened from a single source port (i.e. P2P)
        meter tcdetect { meta l4proto . ip saddr . th sport timeout 5s limit rate over 10/minute } add @threaded_clients { meta l4proto . ip saddr . th sport timeout 5s }
        meter tcdetect6 { meta l4proto . ip6 saddr . th sport timeout 5s limit rate over 10/minute } add @threaded_clients6 { meta l4proto . ip6 saddr . th sport timeout 5s }
    }

    set threaded_services {
        type inet_proto . ipv4_addr . ipv4_addr . inet_service
        flags timeout
    }

    set threaded_services6 {
        type inet_proto . ipv6_addr . ipv6_addr . inet_service
        flags timeout
    }

    set threaded_clients {
        type inet_proto . ipv4_addr . inet_service
        flags timeout
    }

    set threaded_clients6 {
        type inet_proto . ipv6_addr . inet_service
        flags timeout
    }

    ## IP version agnostic DSCP set chains
    chain dscp_set_cs0 {
        ip dscp set cs0 return
        ip6 dscp set cs0
    }

    chain dscp_set_cs1 {
        ip dscp set cs1 return
        ip6 dscp set cs1
    }

    chain dscp_set_af11 {
        ip dscp set af11 return
        ip6 dscp set af11
    }

    chain dscp_set_af12 {
        ip dscp set af12 return
        ip6 dscp set af12
    }

    chain dscp_set_af13 {
        ip dscp set af13 return
        ip6 dscp set af13
    }

    chain dscp_set_cs2 {
        ip dscp set cs2 return
        ip6 dscp set cs2
    }

    chain dscp_set_af21 {
        ip dscp set af21 return
        ip6 dscp set af21
    }

    chain dscp_set_af22 {
        ip dscp set af22 return
        ip6 dscp set af22
    }

    chain dscp_set_af23 {
        ip dscp set af23 return
        ip6 dscp set af23
    }

    chain dscp_set_cs3 {
        ip dscp set cs3 return
        ip6 dscp set cs3
    }

    chain dscp_set_af31 {
        ip dscp set af31 return
        ip6 dscp set af31
    }

    chain dscp_set_af32 {
        ip dscp set af32 return
        ip6 dscp set af32
    }

    chain dscp_set_af33 {
        ip dscp set af33 return
        ip6 dscp set af33
    }

    chain dscp_set_cs4 {
        ip dscp set cs4 return
        ip6 dscp set cs4
    }

    chain dscp_set_af41 {
        ip dscp set af41 return
        ip6 dscp set af41
    }

    chain dscp_set_af42 {
        ip dscp set af42 return
        ip6 dscp set af42
    }

    chain dscp_set_af43 {
        ip dscp set af43 return
        ip6 dscp set af43
    }

    chain dscp_set_cs5 {
        ip dscp set cs5 return
        ip6 dscp set cs5
    }

    chain dscp_set_va {
        ip dscp set 44 return
        ip6 dscp set 44
    }

    chain dscp_set_ef {
        ip dscp set ef return
        ip6 dscp set ef
    }

    chain dscp_set_cs6 {
        ip dscp set cs6 return
        ip6 dscp set cs6
    }

    chain dscp_set_cs7 {
        ip dscp set cs7 return
        ip6 dscp set cs7
    }

    ## Set conntrack DSCP mark without modifying unused bits
    chain ct_set_cs0 {
        ct mark set ct mark and $ct_unused or $cs0
    }

    chain ct_set_cs1 {
        ct mark set ct mark and $ct_unused or $cs1
    }

    chain ct_set_af11 {
        ct mark set ct mark and $ct_unused or $af11
    }

    chain ct_set_af12 {
        ct mark set ct mark and $ct_unused or $af12
    }

    chain ct_set_af13 {
        ct mark set ct mark and $ct_unused or $af13
    }

    chain ct_set_cs2 {
        ct mark set ct mark and $ct_unused or $cs2
    }

    chain ct_set_af21 {
        ct mark set ct mark and $ct_unused or $af21
    }

    chain ct_set_af22 {
        ct mark set ct mark and $ct_unused or $af22
    }

    chain ct_set_af23 {
        ct mark set ct mark and $ct_unused or $af23
    }

    chain ct_set_cs3 {
        ct mark set ct mark and $ct_unused or $cs3
    }

    chain ct_set_af31 {
        ct mark set ct mark and $ct_unused or $af31
    }

    chain ct_set_af32 {
        ct mark set ct mark and $ct_unused or $af32
    }

    chain ct_set_af33 {
        ct mark set ct mark and $ct_unused or $af33
    }

    chain ct_set_cs4 {
        ct mark set ct mark and $ct_unused or $cs4
    }

    chain ct_set_af41 {
        ct mark set ct mark and $ct_unused or $af41
    }

    chain ct_set_af42 {
        ct mark set ct mark and $ct_unused or $af42
    }

    chain ct_set_af43 {
        ct mark set ct mark and $ct_unused or $af43
    }

    chain ct_set_cs5 {
        ct mark set ct mark and $ct_unused or $cs5
    }

    chain ct_set_va {
        ct mark set ct mark and $ct_unused or $va
    }

    chain ct_set_ef {
        ct mark set ct mark and $ct_unused or $ef
    }

    chain ct_set_cs6 {
        ct mark set ct mark and $ct_unused or $cs6
    }

    chain ct_set_cs7 {
        ct mark set ct mark and $ct_unused or $cs7
    }
}