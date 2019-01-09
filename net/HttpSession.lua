require("imperiaonline.net.HttpBrowser");
require("logger.LoggingClass");
require("util.FileUtil");

_HttpSession=Class
{
	type="HttpSession",
	START_URI="/imperia/game/login.php?realm=%d",
	LOGIN_URI="/imperia/game/login.php?realm=%d&resolution=864",
	CODEGEN_URI="/imperia/game/random_pic.php",
	BG_URI="/imperia/game/new.php?language=bg",
	CODE_FILE_NAME="code.gif",
	HOME_URI="/imperia/game/new.php",
	AGREE_BG="Съгласен съм с горенаписаните условия",
	AGREE_EN="I agree",
};

function _HttpSession:create(realm)
	self.realm=realm;
	HttpBrowser():setHost(string.format(_HttpBrowser.HOST, 4));

	local startURI=string.format(_HttpSession.START_URI, self.realm);
	local ok, code, headers=HttpBrowser():browse(startURI);
	ok, code, headers2=HttpBrowser():browse(startURI, nil, {["Cookie"]=headers["set-cookie"]});
	if headers2["set-cookie"] then 
		headers = headers2
	end
	HttpBrowser():saveAs(_HttpSession.CODEGEN_URI, _HttpSession.CODE_FILE_NAME, {["Cookie"]=headers["set-cookie"]});
	string.gsub(headers["set-cookie"], "PHPSESSID=(.*);", function (phpSessID) self.phpSessID=phpSessID; end);
	HttpBrowser():setCookie("PHPSESSID="..self.phpSessID.."; PHPSESSID="..self.phpSessID);
end


function _HttpSession:recreate()
	self:create(self.realm);
end

function _HttpSession:login(username, password, code)
	print(username, password, code)
	local loginURL=string.format(_HttpSession.LOGIN_URI, self.realm);
	self.username=username;
	self.password=password;
	self:log_debug("login user "..username.." with password "..password.." and code "..code);
	local postdata="uname="..username.."&password="..password.."&code="..code.."&submit=+++++++%%C2%%F5%%EE%%E4+++++++";

	table.foreach(HttpBrowser():getDefaultHeaders(), print);
	local result, code, headers, status=HttpBrowser():post(loginURL, postdata, 
		HttpBrowser():getHeaders
			{
				["Referer"]="http://www.imperiaonline.org/imperia/game/login.php?realm="..self.realm,
			}
		);

	self.banned=false;
	FileUtil():writeAll("login.html", result);
	if string.find(result, "Вход", 1, true) or string.find(result, "Login", 1, true) then
		-- Access denied
		return false;
	else
		if string.find(result, _HttpSession.AGREE_BG, 1, true) then
			-- select BG
			headers=HttpBrowser():browse(_HttpSession.BG_URI);
			return true;
		elseif string.find(result, _HttpSession.AGREE_EN, 1, true) then
			-- select BG
			headers=HttpBrowser():browse(_HttpSession.BG_URI);
			return true;
		else
			self.banned=true;
		end
	end
end

function _HttpSession:relogin(code)
	self:login(self.username, self.password, code);
end

function _HttpSession:isBanned()
	return self.banned;
end

function _HttpSession:getUsername()
	return self.username;
end

function _HttpSession:getPassword()
	return self.password;
end

function HttpSession()
	if not _HttpSession.initialized then
		_HttpSession=_HttpSession:inherit(LoggingClass());
		_HttpSession.initialized=true;
	end
	return _HttpSession;
end
