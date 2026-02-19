local ext = require("pastebin.ext")
local pwd = require("posix.pwd")
local grp = require("posix.grp")
local errno = require("posix.errno")
local unistd = require("posix.unistd")
local stat = require("posix.sys.stat")
local libgen = require("posix.libgen")

local M = {}

M.run = function(settings)
	if unistd.geteuid() ~= 0 then
		ext.err(ext.EX_NOPERM, "need root privileges")
	end

	local grent, err, eno = grp.getgrnam(settings.group)
	if err then
		ext.err(ext.EX_OSERR, err)
	end

	if not grent then
		local ok, err = os.execute(string.format("groupadd %s", settings.group))
		if not ok then
			ext.err(EX_OSERR, err)
		end

		print(string.format("group %q added", settings.group))
	end

	local pwent, err, eno = pwd.getpwnam(settings.user)
	if err then
		ext.err(ext.EX_OSERR, err)
	end

	if not pwent then
		local ok, err = os.execute(
			string.format("useradd -L daemon -d /var/empty -s /sbin/nologin -g %q %q", settings.group, settings.user)
		)

		if not ok then
			ext.err(EX_OSERR, err)
		end

		print(string.format("user %q added", settings.user))
	end

	local pwent, err = pwd.getpwnam(settings.user)
	if err then
		ext.err(ext.EX_OSERR, err)
	end

	if not pwent then
		ext.err(ext.EX_OSERR, "missing user" .. settings.user)
	end

	local dirname = libgen.dirname(settings.db)
	local rv, err, eno = stat.mkdir(dirname, 488) -- 0750
	if rv ~= 0 and eno ~= errno.EEXIST then
		ext.err(ext.EX_OSERR, "mkdir " .. dirname .. ": " .. err)
	end

	if rv == 0 then
		print("created " .. dirname)
	end

	local rv, err = unistd.chown(dirname, pwent.pw_uid, pwent.pw_gid)
	if rv ~= 0 then
		ext.err(ext.EX_OSERR, "chown " .. dirname .. ": " .. err)
	else
		print("chowned " .. dirname)
	end

	return 0
end

return M
