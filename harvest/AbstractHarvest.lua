require("util.Class");

_AbstractHarvest=Class
{
	type="AbstractHarvest",
};

function _AbstractHarvest:escREX(s)
	s=string.gsub(s, "%.", "%%.");
	s=string.gsub(s, "%(", "%%(");
	s=string.gsub(s, "%)", "%%)");
	s=string.gsub(s, "%<", "%%<");
	s=string.gsub(s, "%>", "%%>");
	s=string.gsub(s, "%*", "%%*");
	s=string.gsub(s, "%-", "%%-");
	s=string.gsub(s, "%+", "%%+");
	s=string.gsub(s, "%&", "%%&");
	s=string.gsub(s, "%=", "%%=");
	s=string.gsub(s, "\\%%", "");
	s=string.gsub(s, "\\%%%.", ".");
	s=string.gsub(s, "\\%%%*", "*");
	return s;
end

function AbstractHarvest()
	return _AbstractHarvest:clone();
end
