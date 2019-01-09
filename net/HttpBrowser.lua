require("socket.http")
require("logger.LoggingClass");

_HttpBrowser=Class
{
	type="HttpBrowser",
	HOST="statika.imperiaonline.org",
	port=80,
	SLEEP=1500
};

function _HttpBrowser:setHost(host)
	self.host=host;
end

function _HttpBrowser:getHost()
	return self.host;
end

function _HttpBrowser:setPort(port)
	self.port=port;
end

function _HttpBrowser:getPort()
	return self.port;
end

function _HttpBrowser:setCookie(cookie)
	self.cookie=cookie;
end

function _HttpBrowser:getCookie()
	return self.cookie;
end

function _HttpBrowser:browse(uri, sink, headers)
	self:log_debug("browse "..uri);
	process.usleep(math.random(_HttpBrowser.SLEEP));
	return socket.http.request
	{
		host=self.host, 
		port=self.port,
		method="GET",
		uri=uri,
		sink=sink,
		headers=headers or self:getDefaultHeaders()
	};
end

function _HttpBrowser:storeSleepTime(newSleepTime)
	self.sleep=newSleepTime;
end

function _HttpBrowser:restoreSleepTime()
	self.sleep=_HttpBrowser.SLEEP;
end

function _HttpBrowser:saveAs(uri, fileName, headers)
	local file=io.open(fileName, "wb");
	self:browse(uri, function(data) file:write(data); end, headers);
	file:close();
end

function _HttpBrowser:get(uri, headers)
	local buffer="";
	self:browse(uri, function(data) buffer=buffer..data; end, headers);
	return buffer;
end

function _HttpBrowser:getDefaultHeaders()
	return 
	{
		["Host"]=self.host;
		["Pragma"]="no-cache";
		["Accept"]="image/gif, image/x-xbitmap, image/jpeg, image/pjpeg, application/x-shockwave-flash, application/vnd.ms-excel, application/vnd.ms-powerpoint, application/msword, */*";
		["User-Agent"]="Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1; .NET CLR 1.0.3705; .NET CLR 2.0.50727; .NET CLR 1.1.4322)";
		["Accept-Language"]="en-us",
		["Cookie"]=self.cookie
	};
end

function _HttpBrowser:getHeaders(newHeaders)
	newHeaders=newHeaders or {};
	table.foreach(self:getDefaultHeaders(), function(k, v) newHeaders[k]=v; end);
	return newHeaders;
end

function _HttpBrowser:post(uri, postdata, headers)
	headers=headers or {};
	headers["Content-Length"]=30+string.len(postdata);
	print("Content-Length = "..headers["Content-Length"])
	headers["Content-Type"]="application/x-www-form-urlencoded";
	headers["Proxy-Connection"]="Keep-Alive";
	process.usleep(math.random(self.sleep));
	return socket.http.request("http://"..self.host..uri, postdata, headers);
end

function HttpBrowser()
	if not _HttpBrowser.initialized then
		_HttpBrowser=_HttpBrowser:inherit(LoggingClass());
		_HttpBrowser.initialized=true;
		_HttpBrowser.sleep=_HttpBrowser.SLEEP;
	end
	return _HttpBrowser;
end
