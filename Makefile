include $(TOPDIR)/rules.mk

PKG_NAME:=dscpclassify
PKG_VERSION:=1
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/dscpclassify
  CATEGORY:=Extra
  TITLE:=dscpclassify
  DEPENDS:=+nftables
endef

define Build/Prepare
endef

define Build/Compile
endef

define Package/dscpclassify/conffiles
/etc/config/dscpclassify
endef

define Package/dscpclassify/install
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DIR) $(1)/etc/dscpclassify.d
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/etc/hotplug.d/iface
	$(INSTALL_DIR) $(1)/usr/lib/sqm

	$(INSTALL_CONF) ./etc/config/dscpclassify $(1)/etc/config/
	$(INSTALL_CONF) ./etc/dscpclassify.d/main.nft $(1)/etc/dscpclassify.d/
	$(INSTALL_CONF) ./etc/hotplug.d/iface/21-dscpclassify $(1)/etc/hotplug.d/iface/
	$(INSTALL_BIN) ./etc/init.d/dscpclassify $(1)/etc/init.d/

	$(INSTALL_DATA) ./usr/lib/sqm/layer_cake_ct.qos $(1)/usr/lib/sqm/
	$(INSTALL_DATA) ./usr/lib/sqm/layer_cake_ct.qos.help $(1)/usr/lib/sqm/
endef

$(eval $(call BuildPackage,dscpclassify))

