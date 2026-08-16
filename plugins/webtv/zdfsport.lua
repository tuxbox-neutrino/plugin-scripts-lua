  --[[
	ZDF sport live 0.1
	satbaby
]]

-- parse zdfsport 0.4 Satbaby

local n = neutrino(0, 0, SCREEN.X_RES, SCREEN.Y_RES)

json = require "json"

if #arg < 1 then
	return nil
end

local _url0 = arg[1]
local ret0 = {}
local Curl = nil
local sm = nil
local nr = 0

function conv_str(_string)
	if _string == nil then return _string end
	_string = string.gsub(_string,"&amp;","&");
	_string = string.gsub(_string,"&quot;","\"");
	_string = string.gsub(_string,"&#039;","'");
	_string = string.gsub(_string,"\\u0026","&");
	_string = string.gsub(_string,"\\u00a0"," ");
	_string = string.gsub(_string,"\\u00b4","´");
	_string = string.gsub(_string,"\\u00c4","Ä");
	_string = string.gsub(_string,"\\u00d6","Ö");
	_string = string.gsub(_string,"\\u00dc","Ü");
	_string = string.gsub(_string,"\\u00df","ß");
	_string = string.gsub(_string,"\\u00e1","á");
	_string = string.gsub(_string,"\\u00e4","ä");
	_string = string.gsub(_string,"\\u00e8","è");
	_string = string.gsub(_string,"\\u00e9","é");
	_string = string.gsub(_string,"\\u00f4","ô");
	_string = string.gsub(_string,"\\u00f6","ö");
	_string = string.gsub(_string,"\\u00fb","û");
	_string = string.gsub(_string,"\\u00fc","ü");
	_string = string.gsub(_string,"\\u2013","–");
	_string = string.gsub(_string,"\\u201c","“");
	_string = string.gsub(_string,"\\u201e","„");
	_string = string.gsub(_string,"\\u2026","…");
	_string = string.gsub(_string,"&#038;","&");
	_string = string.gsub(_string,"&#8211;","–");
	_string = string.gsub(_string,"&#8212;","—");
	_string = string.gsub(_string,"&#8216;","‘");
	_string = string.gsub(_string,"&#8217;","’");
	_string = string.gsub(_string,"&#8230;","…");
	_string = string.gsub(_string,"&#8243;","?");
	_string = string.gsub(_string,"<[^>]*>","");
	_string = string.gsub(_string,"\\/","/");
	_string = string.gsub(_string,"\\n","");
	return _string
end

function getdata(Url, redir)
	if Url == nil then
		return nil
	end
	if Curl == nil then
		Curl = curl.new()
	end
	local ret, data = Curl:download{
		url = Url,
		followRedir = redir,
		ipv4 = true,
		A = "Mozilla/5.0 (Linux;)"
	}
	if ret == CURL.OK then
		return data
	else
		return nil
	end
end

function godirectkey(d)
	if d == nil then
		return d
	end
	local _dkey = ""
	if d == 1 then
		_dkey = RC.red
	elseif d == 2 then
		_dkey = RC.green
	elseif d == 3 then
		_dkey = RC.yellow
    elseif d == 4 then
		_dkey = RC.blue
	elseif d < 14 then
		_dkey = RC["" .. (d - 4) .. ""]
	elseif d == 14 then
		_dkey = RC["0"]
	else
		-- rest
		_dkey = ""
	end
	return _dkey
end

function getid(id)
	sm:hide()
	nr = tonumber(id)
	return MENU_RETURN.EXIT_ALL
end

function getNeutrinoConf(Pattern)
	local neutrino_conf = "/var/tuxbox/config/neutrino.conf"
	local liveScrPath = nil
	local fh = filehelpers.new()
	if fh:exist(neutrino_conf, "f") == true then
		local config = configfile.new()
		config:loadConfig(neutrino_conf)
		liveScrPath = config:getString(Pattern, "#")
	end
	return liveScrPath
end

function playmenu(data)
	local urls = {}
	local d = 0
	local key = nil

	if data then
		local Hurls = {}
		for page in data:gmatch('ISmartCollectionTracking(.-)episodeInfo') do
			local title = page:match('"title\\":\\"(.-)\\"')
			local id = page:match('"id\\":\\"(.-)"')
			if id then
				if Hurls[id] ~= true then
					Hurls[id] = true
					d = d + 1
					key = godirectkey(d)
					table.insert(urls, {
						title = conv_str(title),
						id = id,
						dkey = key
					})
				end
			end
		end
		for page in data:gmatch('<div class=".-="livestream%-upcoming"(.-)</picture></div>') do
			local date,title = page:match('livestream%-upcoming">(.-)<.-([^<>]+)</div></h3>')
			local id = page:match('aria%-controls="(.-)"')
			local time = page:match('>(ab%s+%d%d:%d%d%s+Uhr)<')
			if title and title and id then
				if Hurls[id] ~= true then
					Hurls[id] = true
					d = d + 1
					key = godirectkey(d)
					if time then date = time .. " " .. date end
					table.insert(urls, {
						title =date .. " " .. conv_str(title),
						id = id,
						dkey = key
					})
				end
			end

		end
		key = nil
	end

	if #urls > 1 then
		sm = menu.new{name = "zdfsport", icon = "icon_blue"}
		for index, w in ipairs(urls) do
			sm:addItem{
				type = "forwarder",
				name = w.title,
				action = "getid",
				id = index,
				directkey = w.dkey
			}
		end
		sm:exec()
		sm:hide()
	end

	if #urls == 1 then
		nr = 1
	end

	if nr > 0 then
		local scpath = getNeutrinoConf("livestreamScriptPath")
		if scpath then
			local jsdata = getdata("https://sportapi.zdf.de/json-sdp/scenes/ex-" .. urls[nr].id)
			local name = nil
			local url_m3u8 = nil
			if jsdata then
				local jsT = json:decode(jsdata)
				if jsT.entry_meta then
					for _, pos in pairs(jsT.entry_meta) do
						if pos.name == "livestream_original" then
							url_m3u8 = pos.value
							name = jsT.name
							break
						end
					end
				end
			end
			if url_m3u8 then
				arg = {}
				arg[1] = url_m3u8
				arg[2] = nil
				local scriptfile = "/best_bitrate_m3u8.lua"
				local r = dofile(scpath .. scriptfile)
				if r then
					local js = json:decode(r)
					for k, v in ipairs(js) do
						js[k].name = name or urls[nr].title
					end
					return json:encode(js)
				end
			end
		end
	end
	return nil
end

function getVideoData(url)
	if url == nil then
		return 0
	end
	local data = getdata(url, true)
	if data then
		ret0 = playmenu(data)
		if ret0 then
			return 1
		end
	end
	return 0
end

if getVideoData(_url0) > 0 then
	return ret0
end

return ""
