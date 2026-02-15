local http_headers = require("http.headers")

local rtmt = {}

local splmeth = function(match)
	return string.match(match, "(%u+)%s+(.+)")
end

rtmt.handle = function(self, match, how)
	local t = {}

	if type(how) == "table" then
		t.handle = function(r, ...)
			how:serve(r, ...)
		end
	else
		t.handle = how
	end

	local meth, pth = splmeth(match)

	if meth then
		t.method = meth
		t.match = pth
	else
		t.match = match
	end

	table.insert(self.handlers, t)
	return self
end

rtmt.notfound = function(self, server, stream, headers)
	local res_headers = http_headers.new()
	res_headers:append(":status", "404")
	res_headers:append("content-type", "text/plain")
	assert(stream:write_headers(res_headers, false, 30))
	assert(stream:write_chunk("Not found\n", true, 30))
end

rtmt.serve = function(self, server, stream)
	local found
	local headers = assert(stream:get_headers())
	local p = headers:get(":path")
	local meth = headers:get(":method")

	for i, m in ipairs(self.handlers) do
		local methmatch = not m.method or m.method == meth
		local matches = { string.match(p, m.match) }
		if methmatch and #matches > 0 then
			found = true
			if m.handle(server, stream, headers, table.unpack(matches)) == false then
				found = false
			end
			break
		end
	end

	if not found then
		self:notfound(server, stream, headers)
	end
end

local router = {}

router.new = function()
	local t = { handlers = {} }
	local rt = setmetatable(t, { __index = rtmt })
	if not router.default then
		router.default = rt
	end

	return rt
end

return router
