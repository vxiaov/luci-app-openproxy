local uci = require("luci.model.uci").cursor()
local fs = require "nixio.fs"
local http = require "luci.http"
local sys = require "luci.sys"
local home_dir = "/etc/openproxy/"
local config_dir = "/etc/openproxy/config/"
local custom_proxy_dir = "/etc/openproxy/custom_proxy/"
local custom_rule_dir = "/etc/openproxy/custom_rule/"
local core_dir = "/etc/openproxy/core/"
local backup_dir = "/etc/openproxy/.backup/"

local function is_yaml(file)
    return string.match(file, "%.yaml$") or string.match(file, "%.yml$")
end

--- 功能：验证文件类型是否符合要求
---@param file string 文件名
---@param file_type string 文件类型
local function is_valid_file_type(file, file_type)
	local lower_file = string.lower(file)
    local allowed_extensions = {
        config = {".yaml", ".yml"},
        ["proxy-provider"] = {".yaml", ".yml", ".txt"},
        ["rule-provider"] = {".yaml", ".yml"},
        clash = {".gz"},
        ["country.mmdb"] = {".mmdb"},
        ["backup-file"] = {".tar.gz"}
    }
    -- 获取当前选择的扩展名列表
    local extensions = allowed_extensions[file_type] or {}
    -- 检查文件名是否以允许的扩展名结尾
    for _, ext in ipairs(extensions) do
        if string.match(lower_file, "%" .. string.lower(ext) .. "$") then
            return true
        end
    end

    return false
end

ful = Form("upload", translate("Config Manage"), nil)
ful.reset = false
ful.submit = false

sul = ful:section(SimpleSection, "")
o = sul:option(FileUpload, "")
o.template = "openproxy/options_upload"
um = sul:option(DummyValue, "", nil)
um.template = "openproxy/dvalue"

local fd
local save_dir
http.setfilehandler(
	function(meta, chunk, eof)
		local ftype = http.formvalue("file_type")
		-- 目录创建并打开文件
		if not fd then
			if ftype == "config" then
				save_dir = config_dir
			elseif ftype == "proxy-provider" then
				save_dir = custom_proxy_dir
			elseif ftype == "rule-provider" then
				save_dir = custom_rule_dir
			elseif ftype == "clash" then
				save_dir = core_dir
			elseif ftype == "backup-file" then
				save_dir = backup_dir
			elseif ftype == "country.mmdb" then
				save_dir = home_dir
			end
			-- 文件后缀验证，避免前端失效导致上传错误的文件类型
			if not is_valid_file_type(meta.file, ftype) then
				um.value = translate("invalid file type") .. meta.file
				return
			end

			if not meta then return end
			fs.mkdir(save_dir)
			if meta and chunk then fd = nixio.open(save_dir .. meta.file, "w") end
			if not fd then
				um.value = translate("open file error.")
				return
			end
		end
		-- 写入数据
		if chunk and fd then  fd:write(chunk) end
		-- 写完数据后的处理
		if eof and fd then
			fd:close()
			fd = nil
			um.value = translate("File saved to") .. save_dir
			if ftype == "clash" then
				if string.lower(string.sub(meta.file, -7, -1)) == ".tar.gz" then
					os.execute(string.format("tar -C %s -xzf %s >/dev/null 2>&1", core_dir..".temp", (core_dir .. meta.file)))
					os.execute(string.format("mv %s %s >/dev/null 2>&1", core_dir..".temp/*", core_dir ))
					fs.unlink(core_dir..".temp")
				elseif string.lower(string.sub(meta.file, -3, -1)) == ".gz" then
					os.execute("gzip -fd %s >/dev/null 2>&1" % (core_dir .. meta.file))
				end
				os.execute("chmod +x ".. home_dir .. "core/* >/dev/null 2>&1")
				fs.unlink((core_dir .. meta.file))
			elseif ftype == "backup-file" then
				-- 上传备份文件-快速恢复配置
				os.execute("tar -C ".. home_dir .. " -xzf ".. backup_dir .. meta.file .. " >/dev/null 2>&1")
				os.execute("mv " .. home_dir .. "openproxy /etc/config/") -- 恢复配置变量
				fs.unlink(home_dir .. "openproxy")
				fs.unlink(backup_dir .. meta.file)
				um.value = translate("Backup File Restore Successful!")
				sys.call("rm -rf " .. backup_dir )
			end
		end
	end
)

if http.formvalue("upload") then
    if not um.value then
        um.value = translate("No Specify Upload File")
    end
end

--- DNS 配置
fdns = Form("dns_config", translate("Dns Config"), nil)
fdns.reset = false
fdns.submit = false

sdns = fdns:section(SimpleSection, "")
o = sdns:option(Flag, "custom_dns", "")
o.template = "openproxy/options_dns"

return ful, fdns
