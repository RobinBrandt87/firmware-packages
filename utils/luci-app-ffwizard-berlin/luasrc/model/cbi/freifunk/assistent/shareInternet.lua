local uci = require "luci.model.uci".cursor()
local fs = require "nixio.fs"
local tools = require "luci.tools.freifunk.assistent.tools"
local defaults = require "luci.tools.freifunk.assistent.defaults"

f = SimpleForm("ffvpn","","")
f.submit = "Next"
f.cancel = "Back"
f.reset = false

css = f:field(DummyValue, "css", "")
css.template = "freifunk/assistent/snippets/css"

vpninfo = f:field(DummyValue, "apinfo", "")
vpninfo.template = "freifunk/assistent/snippets/vpninfo"

local cert = f:field(FileUpload, "cert", translate("Local Certificate"),"freifunk_client.crt")
cert.default="/etc/openvpn/freifunk_client.crt"
cert.rmempty = false
cert.optional = false

local key = f:field(FileUpload, "key", translate("Local Key"),"freifunk_client.key")
key.default="/etc/openvpn/freifunk_client.key"
key.rmempty = false
key.optional = false

local usersBandwidth = f:field(Value, "usersBandwidth", "Deine Bandbreite")
local bandwidths = defaults.bandwidths()
usersBandwidth.rmempty = false
for k,v in pairs(bandwidths) do
  usersBandwidth:value(k, v.name)
end
function usersBandwidth.cfgvalue(self, section)
  return uci:get("ffwizard", "settings", "usersBandwidth")
end
local share = f:field(Value, "share", "Wieviel möchtest du teilen?")
share.default = 100
share.rmempty = false
share:value(25,"25%")
share:value(50,"50%")
share:value(75,"75%")
share:value(100,"100%")
function share.cfgvalue(self, section)
	return uci:get("ffwizard", "settigs", "shareBandwidth")
end

main = f:field(DummyValue, "openvpnconfig", "", "")
main.forcewrite = true

function main.parse(self, section)
  local fvalue = "1"
  if self.forcewrite then
    self:write(section, fvalue)
  end
end

function main.write(self, section, value)

  uci:set("ffwizard", "settings", "sharenet", 1)
  uci:set("ffwizard", "settings", "usersBandwidth", usersBandwidth:formvalue(section) or "")
  uci:set("ffwizard", "settings", "shareBandwidth", share:formvalue(section) or "")

  uci:section("openvpn", "openvpn", "ffvpn", {
    --persist_tun='0',
    enabled='1'
  })

  fs.copy("/lib/uci/upload/cbid.ffvpn.1.cert","/etc/openvpn/freifunk_client.crt")
  fs.copy("/lib/uci/upload/cbid.ffvpn.1.key","/etc/openvpn/freifunk_client.key")

  uci:save("openvpn")
  uci:save("ffwizard")

  -- I need to commit this here, don't know why I can not do this in apply changes
  uci:commit("openvpn")

end

function f.handle(self, state, data)
  if state == FORM_VALID then
    luci.http.redirect(luci.dispatcher.build_url("admin/freifunk/assistent/optionalConfigs"))
  end
end

function f.on_cancel()
  luci.http.redirect(luci.dispatcher.build_url("admin/freifunk/assistent/decide"))
end

return f
