_encrypt={};

function _encrypt:main(username, realm)
	if not realm then
		string.gsub(username, "(.-)%-(%d+)", function(u, r) 
			username, realm=u, r;
		end);
	end

	function enc(s)
		local r={};
		local i;
		for i=1,string.len(s) do
			local b=string.byte(s, i);
			table.insert(r, b);
		end
		return r;
	end


	function dec(r)
		return string.char(unpack(r));
	end

	function toArray(r)
		local isFirst=true;
		local s="string.char(unpack({";
		table.foreachi(r, function(_, code)
			if not isFirst then s=s..","; end
			s=s..code;
			isFirst=false;
		end);
		return s.."}))";
	end

	if not username then
		io.write("username:"); username=io.read();
	end

	rUser=enc(username);

	print("function UserInfo() return "..toArray(rUser)..", "..realm.."; end");

end

function encrypt() 
	return _encrypt; 
end
