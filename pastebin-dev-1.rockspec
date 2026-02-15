package = "pastebin"
version = "dev-1"
source = {
	url = "git+https://github.com/mischief/pastebin.git",
}
description = {
	homepage = "https://github.com/mischief/pastebin.git",
	license = "MIT",
}

dependencies = {
	"luaposix",
	"http",
}

build = {
	type = "builtin",

	modules = {
		["pastebin.command.serve"] = "pastebin/command/serve.lua",
		["pastebin.command.sysinit"] = "pastebin/command/sysinit.lua",
		["pastebin.db"] = "pastebin/db.lua",
		["pastebin.privsep"] = "pastebin/privsep.lua",
		["pastebin.router"] = "pastebin/router.lua",

		["pastebin.ext"] = "pastebin/ext.c",
	},

	install = {
		bin = {
			pastebin = "main.lua",
		},
	},
}
