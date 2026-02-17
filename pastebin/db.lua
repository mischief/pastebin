local sqlite3 = require("lsqlite3")

local db_methods = {}
local db = {
	__index = db_methods,
}

local function randomtag(len)
	local res = ""
	for i = 1, len do
		res = res .. string.char(math.random(97, 122))
	end
	return res
end

function db_methods:put(blob)
	local tag = randomtag(8)

	self.putstmt:reset()
	self.putstmt:bind_values(tag, blob)
	local rv = self.putstmt:step()
	assert(rv == sqlite3.DONE, "put: " .. tostring(rv))

	return tag
end

function db_methods:get(tag)
	self.getstmt:reset()
	self.getstmt:bind_values(tag)
	local rv = self.getstmt:step()
	if rv == sqlite3.DONE then
		return nil
	elseif rv == sqlite3.ROW then
		local v = self.getstmt:get_named_values()
		return v.data
	end

	error("sqlite error")
end

function db_methods:cleanup()
	local s, err = dbf:prepare("DELETE FROM pastes WHERE created < (unixepoch() - unixepoch('now', '-90 days'))")
	assert(s, err)
	local rv = s:step()
	if rv ~= sqlite3.DONE then
		error(rv)
	end
end

local M = {}

M.init = function(dbf)
	local rv = dbf:exec([=[
CREATE TABLE IF NOT EXISTS pastes (
	id INTEGER PRIMARY KEY,
	tag TEXT UNIQUE,
	ext TEXT,
	mime TEXT,
	created INT,
	data BLOB
)
	]=])
	assert(rv == sqlite3.OK, "init error")
	local putstmt, err = dbf:prepare("INSERT INTO pastes (tag, created, data) VALUES (?, unixepoch(), ?)")
	assert(putstmt, err)
	local getstmt, err = dbf:prepare("SELECT id, tag, ext, mime, data FROM pastes WHERE tag == ?")
	assert(getstmt, err)
	return setmetatable({
		db = dbf,
		putstmt = putstmt,
		getstmt = getstmt,
	}, db)
end

M.new = function(path)
	local dbf, _, err = sqlite3.open(path)
	if not dbf then
		return nil, err
	end
	return M.init(dbf)
end

return M
