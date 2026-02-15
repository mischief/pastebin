local pwd = require("posix.pwd")
local grp = require("posix.grp")
local errno = require("posix.errno")
local unistd = require("posix.unistd")
local stat = require("posix.sys.stat")
local libgen = require("posix.libgen")

local M = {}

M.run = function(settings)
	if unistd.geteuid() ~= 0 then
		io.stderr:write("need root privs\n")
		os.exit(1)
	end

	local grent, err, eno = grp.getgrnam(settings.group)
	if err then
		print(err)
		return
	end
	if not grent then
		local ok, err = os.execute(string.format("groupadd %s", settings.group))
		assert(ok, err)
		print(string.format("group %q added", settings.group))
	end

	local pwent, err, eno = pwd.getpwnam(settings.user)
	if err then
		print(err)
		return
	end

	if not pwent then
		local ok, err = os.execute(
			string.format("useradd -L daemon -d /var/empty -s /sbin/nologin -g %q %q", settings.group, settings.user)
		)
		assert(ok, err)
		print(string.format("user %q added", settings.user))
	end

	local pwent, err = pwd.getpwnam(settings.user)
	if err then
		print(err)
		return
	end

	assert(pwent, "missing user?")

	local dirname = libgen.dirname(settings.db)
	local rv, err, eno = stat.mkdir(dirname, 488) -- 0750
	assert(rv == 0 or eno == errno.EEXIST, err)
	local rv, err = unistd.chown(dirname, pwent.pw_uid, pwent.pw_gid)
	assert(rv == 0, err)
end

return M
