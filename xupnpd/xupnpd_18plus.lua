-- ******************************
-- Attention!!! Adult only      *
-- 18+                          *
-- ******************************
-- 22.08.2021
-- 27.06.2022 update by jokel
-- 05.03.2023 update by det-box
-- 06.03.2023 update by jokel

cfg.user_age=18
cfg.youporn_max_pages=5

cfg.maxRes=720
-- 1080 or 720 or 480 or 240

youporn_category=
{
    ['top_rated']='/top_rated/', ['most_viewed']='/most_viewed/', ['amateur']='/category/amateur/', ['anal']='/category/anal/',
    ['asian']='/category/asian/', ['bbw']='/category/bbw/', ['big_butt']='/category/big-butt/', ['big_tits']='/category/big-tits/',
    ['bisexual']='/category/bisexual/', ['blonde']='/category/blonde/', ['blowjob']='/category/blowjob/',
    ['brunette']='/category/brunette/', ['coed']='/category/coed/', ['compilation']='/category/compilation/',
    ['couples']='/category/couples/', ['creampie']='/category/creampie/', ['cumshots']='/category/cumshots/',
    ['cunnilingus']='/category/cunnilingus/', ['dp']='/category/dp/', ['ebony']='/category/ebony/',
    ['european']='/category/european/', ['facial']='/category/facial/', ['fantasy']='/category/fantasy/',
    ['fetish']='/category/fetish/', ['fingering']='/category/fingering/', ['funny']='/category/funny/',
    ['gay']='/category/gay/', ['german']='/category/german/', ['gonzo']='/category/gonzo/',
    ['group_sex']='/category/group-sex/', ['hairy']='/category/hairy/', ['handjob']='/category/handjob/',
    ['hentai']='/category/hentai/', ['instructional']='/category/instructional/', ['interracial']='/category/interracial/',
    ['interview']='/category/interview/', ['kissing']='/category/kissing/', ['latina']='/category/latina/',
    ['lesbian']='/category/lesbian/', ['milf']='/category/milf/', ['masturbate']='/category/masturbate/',
    ['mature']='/category/mature/', ['pov']='/category/pov/', ['panties']='/category/panties/',
    ['pantyhose']='/category/pantyhose/', ['public']='/category/public/', ['redhead']='/category/redhead/',
    ['rimming']='/category/rimming/', ['romantic']='/category/romantic/', ['shaved']='/category/shaved/',
    ['shemale']='/category/trans/', ['solo_male']='/category/solo-male/', ['solo_girl']='/category/solo-girl/',
    ['squirting']='/category/squirting/', ['strt_sex']='/category/strt-sex/', ['swallow']='/category/swallow/',
    ['teen']='/category/teen/', ['threesome']='/category/threesome/', ['vintage']='/category/vintage/',
    ['voyeur']='/category/voyeur/', ['webcam']='/category/webcam/', ['3d']='/category/3d/', ['hd']='/category/hd/',
    ['young-old']='/category/young-old/'
}

function check_if_double(tab,name)
	for index,value in ipairs(tab) do
		if value == name then
			return false
		end
	end
	return true
end

function youporn_updatefeed(feed,friendly_name)
	local rc=false

	local ff=youporn_category[feed]

	if not ff then return false end

	local feed_name='youporn_'..string.gsub(feed,'/','_')
	local feed_m3u_path=cfg.feeds_path..feed_name..'.m3u'
	local tmp_m3u_path=cfg.tmp_path..feed_name..'.m3u'
	local feed_url='https://www.youporn.com'..ff..'?'

	local dfd=io.open(tmp_m3u_path,'w+')

	if dfd then
		dfd:write('#EXTM3U name=\"',friendly_name or feed_name,'\" type=mp4 plugin=youporn\n')
-- 		http.user_agent(cfg.user_agent..'\r\nCookie: age_verified=1')
		http.user_agent('Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/538.1 (KHTML, like Gecko) ' ..'\r\nCookie: age_verified=1')
		local page=1
		local urls = {}
		while(page<=cfg.youporn_max_pages) do
			local url=feed_url..'&page='..page
			if cfg.debug>0 then print('YouPorn try url '..url) end
			local data=http.download(url)
			if not data then  return end

			local skipto = data.find(data, "<div class='container'>")
			if skipto and #data > skipto then
				data = string.sub(data,skipto,#data)
			end
			local anythingtoparse = data.find(data,"<div class=")
			if data  and anythingtoparse then
				local n=0
				for entry in data:gmatch('(<a href="/watch/.-)</a>') do
					local urn = entry:match('<a%s+href="(/watch/.-)"')
					local name = entry:match('alt=[\'"](.-)[\'"]')
					local logo = entry:match('data%-thumbnail="(.-)"')
					if check_if_double(urls,urn) and urn and name then
						urls[#urls+1] =  urn
						local id = urn:match('/watch/(%d+)/')
						if id then
							urn = '/api/video/media_definitions/' .. id .. '/'
						end
						local f = nil
						if logo then
							f = string.find(logo, 'blankvideobox.png')
						end
						if f then
							logo = string.match(entry,'thumbnail="(.-)"')
							if logo == nil then
								logo=""
							end
						end
						if #logo+#name > 235 then
							if #logo < 235 then
								local shortname = logo .. name
								name =shortname:sub(#logo+1, 235)
							else
								name = n .. " : to long name"
							end
						end
						dfd:write('#EXTINF:0 logo=',logo,' ,',name,'\n','https://www.youporn.com',urn,'\n')
						n=n+1
					end
				end
				if n<1 then page=cfg.youporn_max_pages end
				data=nil
			end
			page=page+1
		end
		dfd:close()

		if util.md5(tmp_m3u_path)~=util.md5(feed_m3u_path) then
			if os.rename(tmp_m3u_path, feed_m3u_path) then
				rc=true
			end
			if cfg.debug>0 then print('YouPorn feed \''..feed_name..'\' updated') end
		end
		util.unlink(tmp_m3u_path)
	end

	return rc
end

function youporn_sendurl(youporn_url,range)

	if plugin_sendurl_from_cache(youporn_url,range) then return end
	http.user_agent('Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/538.1 (KHTML, like Gecko) ' ..'\r\n')

	local url=nil
	local data=http.download(youporn_url)
	if data then
		local jnTab = json.decode(data)
		if jnTab then
			for k, v in pairs(jnTab) do
				if v.format == "mp4" then
					if v.videoUrl and #v.videoUrl > 6 then
						local res =  tonumber(v.quality)
						if res == cfg.maxRes then
							url = v.videoUrl
							break
						end
					end
				end
			end
		end
	else
		if cfg.debug>0 then print('Clip is not found') end
	end

	if url then
		url=string.gsub(url,'&amp;','&')
		url=string.gsub(url,'u0026','&')
		url=string.gsub(url,'\\','')
		if cfg.debug>0 then print('Real URL: '..url) end
		plugin_sendurl(youporn_url,url,range)
	else
		if cfg.debug>0 then print('Real URL is not found') end
		plugin_sendfile('www/corrupted.mp4')
	end
end

function youporn_desc()
	local t={}
	for i,j in pairs(youporn_category) do
		t[table.maxn(t)+1]=i
	end
	return table.concat(t,',')
end

plugins['youporn']={}
plugins.youporn.disabled=false
plugins.youporn.name="YouPorn"
plugins.youporn.desc=youporn_desc()
plugins.youporn.sendurl=youporn_sendurl
plugins.youporn.updatefeed=youporn_updatefeed

if cfg.user_age<18 then plugins.youporn.disabled=true end
