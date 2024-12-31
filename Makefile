include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-openproxy
PKG_VERSION:=$(shell git describe --tags --abbrev=0)
PKG_RELEASE:=$(shell git rev-list --count HEAD)
PKG_MAINTAINER:=vxiaov <https://github.com/vxiaov/OpenProxy>
PKG_LICENSE:=GPL-3.0

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	CATEGORY:=LuCI
	SUBMENU:=3. Applications
	TITLE:=Luci support for OpenProxy(driven by Clash)
	PKGARCH:=all
	DEPENDS:=+yq +kmod-nft-nat +kmod-nft-socket +kmod-nft-tproxy +luci-compat +luci +luci-base
	MAINTAINER:=vxiaov
endef

define Package/$(PKG_NAME)/description
    A LuCI support for OpenProxy
endef

define Build/Prepare
	$(CP) $(CURDIR)/root $(PKG_BUILD_DIR)
	$(CP) $(CURDIR)/luasrc $(PKG_BUILD_DIR)
	$(CP) $(CURDIR)/po $(PKG_BUILD_DIR)
	
	chmod 0755 $(PKG_BUILD_DIR)/root/etc/init.d/openproxy
	exit 0
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/i18n
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/po/*.lmo $(1)/usr/lib/lua/luci/i18n/
	$(CP) $(PKG_BUILD_DIR)/root/* $(1)/
	$(CP) $(PKG_BUILD_DIR)/luasrc/* $(1)/usr/lib/lua/luci/
endef

define Package/$(PKG_NAME)/preinst
#!/bin/sh
if [ -f "/etc/config/openproxy" ]; then
	cp -f /etc/config/openproxy /etc/config/openproxy.bak >/dev/null 2>&1
fi
exit 0
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
/etc/init.d/openproxy enable >/dev/null 2>&1
enable=$(uci -q get openproxy.config.enable 2>/dev/null)
if [ "$enable" == "1" ]; then
	/etc/init.d/openproxy restart 2>/dev/null
fi
exit 0
endef

define Package/$(PKG_NAME)/prerm
#!/bin/sh
uci set openproxy.config.enable=0
uci commit openproxy
/etc/init.d/openproxy stop
/etc/init.d/openproxy disable
exit 0
endef

define Package/$(PKG_NAME)/postrm
#!/bin/sh
	rm -rf /etc/openproxy >/dev/null 2>&1
	rm -rf /tmp/openproxy.log >/dev/null 2>&1
	rm -rf /usr/lib/lua/luci/view/openproxy
	rm -rf /usr/lib/lua/luci/mode/cbi/openproxy
	rm -f  /usr/lib/lua/luci/controller/openproxy.lua
	rm -f  /usr/lib/lua/luci/i18n/openproxy.*.lmo
	exit 0
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
