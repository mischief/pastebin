local getopt = require("posix.unistd").getopt

local settings = {
	privsep = true,
	db = "/var/db/pastebin/pastebin.sqlite3",
	port = "31686",
	user = "_pastebin",
	group = "_pastebin",
}

local function putsf(w, fmt, ...)
	w:write(string.format(fmt, ...) .. "\n")
end

local function usage(w)
	putsf(w, "usage: pastebin [-h] [-P] [-d db] [-p port] [-u user] [-g group]")
	putsf(w, "subcommands:")
	putsf(w, "\tsysinit")
	putsf(w, "\tserve")
end

local opttab = {}
opttab.h = function(opt)
	usage(io.stdout)
end
opttab.P = function(opt)
	settings.privsep = false
end
opttab.d = function(opt)
	settings.db = opt
end
opttab.p = function(opt)
	settings.port = opt
end
opttab.u = function(opt)
	settings.user = opt
end
opttab.g = function(opt)
	settings.group = opt
end

local last_index = 1
for r, optarg, optind in getopt(arg, "hPd:p:u:g") do
	if r == "?" then
		putsf(io.stderr, "unrecognized option: %s", arg[optind - 1])
		usage(io.stderr)
		os.exit(64)
	end

	last_index = optind
	opttab[r](optarg)
end

if last_index > #arg then
	putsf(io.stderr, "missing command")
	usage(io.stderr)
	os.exit(64)
end

local commandnames = { "sysinit", "serve" }
local commandtab = {}

for _, k in ipairs(commandnames) do
	local m = require("pastebin.command." .. k)
	commandtab[k] = m
end

local command = arg[last_index]
commandtab[command].run(settings)
