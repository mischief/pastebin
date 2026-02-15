local unistd = require("posix.unistd")
local libgen = require("posix.libgen")
local pwd = require("posix.pwd")
local ext = require("pastebin.ext")

local M = {}

function M.setup(settings)
	assert(unistd.geteuid() == 0, "need root privs")
	local pwent, err, eno = pwd.getpwnam(settings.user)
	assert(pwent, err or "missing user")

	local dbdir = libgen.dirname(settings.db)
	local rv, err = ext.unveil(dbdir, "rwc")
	assert(rv == 0, err)

	local rv, err = ext.chroot(dbdir)
	assert(rv == 0, err)

	-- cheeky rewrite of dbpath after chroot
	settings.db = libgen.basename(settings.db)

	local rv, err = unistd.chdir("/")
	assert(rv == 0, err)

	local rv, err = ext.setgroups(pwent.pw_gid)
	assert(rv == 0, err)

	local rv, err = ext.setresgid(pwent.pw_gid, pwent.pw_gid, pwent.pw_gid)
	assert(rv == 0, err)

	local rv, err = ext.setresuid(pwent.pw_uid, pwent.pw_uid, pwent.pw_uid)
	assert(rv == 0, err)

	-- TODO: daemon(3)

	local rv, err = ext.pledge("stdio unix rpath wpath cpath inet flock", "")
	assert(rv == 0, err)
end

return M
