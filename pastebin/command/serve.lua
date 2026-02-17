local db = require("pastebin.db")
local privsep = require("pastebin.privsep")
local ext = require("pastebin.ext")
local router = require("pastebin.router")
local cqueues = require("cqueues")
local http_server = require("http.server")
local http_headers = require("http.headers")

local dox = [=[
a shitty pastebin
]=]

local function home(server, stream, headers)
	local req_method = headers:get(":method")
	local res_headers = http_headers.new()
	res_headers:append(":status", "200")
	res_headers:append("content-type", "text/plain")
	-- Send headers to client; end the stream immediately if this was a HEAD request
	assert(stream:write_headers(res_headers, req_method == "HEAD"))
	if req_method ~= "HEAD" then
		-- Send body, ending the stream
		assert(stream:write_chunk(dox, true))
	end
end

local function putpaste(server, stream, headers)
	local host = headers:get(":authority")
	local ct = headers:get("content-type")
	if ct ~= "application/x-www-form-urlencoded" then
		return false
	end

	local body = stream:get_body_chars(10 * 1024 * 1024, 30)
	assert(body)

	local tag = server.db:put(body)

	local res_headers = http_headers.new()
	res_headers:append(":status", "200")
	res_headers:append("content-type", "text/plain")

	assert(stream:write_headers(res_headers, false, 30))
	assert(stream:write_chunk(string.format("http://%s/%s\n", host, tag)))
end

local function getpaste(server, stream, headers, tag)
	local blob = server.db:get(tag)
	if not blob then
		return false
	end

	local res_headers = http_headers.new()
	res_headers:append(":status", "200")
	res_headers:append("content-type", "text/plain")
	assert(stream:write_headers(res_headers, false, 30))
	assert(stream:write_chunk(blob, true))
end

local M = {}
M.run = function(settings)
	local cq = cqueues.new()

	local rt = router.new()
	rt:handle("GET /(%w+)", getpaste)
	rt:handle("POST /", putpaste)
	rt:handle("GET /", home)

	local myserver = assert(http_server.listen({
		cq = cq,
		host = "0.0.0.0",
		port = settings.port,

		onstream = function(server, stream)
			rt:serve(server, stream)
		end,

		onerror = function(myserver, context, op, err, errno) -- luacheck: ignore 212
			local msg = op .. " on " .. tostring(context) .. " failed"
			if err then
				msg = msg .. ": " .. tostring(err)
			end
			assert(io.stderr:write(msg, "\n"))
		end,
	}))

	-- Manually call :listen() so that we are bound before calling :localname()
	assert(myserver:listen())
	do
		local bound_port = select(3, myserver:localname())
		assert(io.stderr:write(string.format("Now listening on port %d\n", bound_port)))
	end

	ext.setproctitle("pastebin")

	if settings.privsep then
		privsep.setup(settings)
	end

	myserver.db = assert(db.new(settings.db))

	cq:wrap(function()
		while true do
			cqueues.sleep(60 * 60 * 24)
			myserver.db:cleanup()
		end
	end)

	-- Start the main server loop
	assert(cq:loop())
end

return M
