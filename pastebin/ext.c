#include <unistd.h>
#include <errno.h>
#include <stdlib.h>
#include <string.h>
#include <sysexits.h>
#include <err.h>

#include <lua.h>
#include <lauxlib.h>

static int
pusherr(lua_State *L, int e)
{
	int rv;
	char estr[NL_TEXTMAX];

	rv = strerror_r(e, estr, sizeof(estr));

	lua_pushnil(L);

	if(rv == 0)
		lua_pushstring(L, estr);
	else
		lua_pushfstring(L, "(unknown error %d)", e);

	lua_pushinteger(L, e);

	return 3;
}

static int
luachroot(lua_State *L)
{
	const char *dirname = luaL_checkstring(L, 1);
	char estr[NL_TEXTMAX];

	if(chroot(dirname) < 0)	
		return pusherr(L, errno);

	lua_pushinteger(L, 0);

	return 1;
}

static int
luapledge(lua_State *L)
{
	const char *promises = luaL_checkstring(L, 1);
	const char *execpromises = luaL_checkstring(L, 2);
	char estr[NL_TEXTMAX];

	if(pledge(promises, execpromises) < 0)
		return pusherr(L, errno);

	lua_pushinteger(L, 0);

	return 1;
}

static int
luaunveil(lua_State *L)
{
	const char *path = luaL_checkstring(L, 1);
	const char *permissions = luaL_checkstring(L, 2);
	char estr[NL_TEXTMAX];

	if(unveil(path, permissions) < 0)
		return pusherr(L, errno);

	lua_pushinteger(L, 0);

	return 1;
}

static int
luaerr(lua_State *L)
{
	int code = luaL_checkinteger(L, 1);
	const char *str = luaL_checkstring(L, 2);

	err(code, "%s", str);
	abort();
}

static int
luasetgroups(lua_State *L)
{
	long ngr, idx;
	int isnum, top;
	gid_t gid, *groups;
	char estr[NL_TEXTMAX];

	top = lua_gettop(L);

	luaL_argcheck(L, (lua_istable(L, 1) || lua_isinteger(L, 1)), top, "must be integer or table");

	gid = lua_tointegerx(L, 1, &isnum);
	if(isnum){
		if(setgroups(1, &gid) < 0)
			return pusherr(L, errno);
		lua_pushinteger(L, 0);
		return 1;
	}

	if((ngr = sysconf(_SC_NGROUPS_MAX)) < 0)
		return pusherr(L, errno);

	groups = lua_newuserdata(L, sizeof(*groups) * ngr);

	idx = 0;

	lua_pushnil(L);
	while(lua_next(L, top) != 0){
		if(idx >= ngr)
			luaL_error(L, "too many groups (%d)", idx);

		gid = luaL_checkinteger(L, 1);
		groups[idx++] = gid;
	}

	if(setgroups(ngr, groups) < 0)
		return pusherr(L, errno);

	lua_pushinteger(L, 0);

	return 1;
}

static int
luasetresgid(lua_State *L)
{
	int rgid = luaL_checkinteger(L, 1);
	int egid = luaL_checkinteger(L, 2);
	int sgid = luaL_checkinteger(L, 3);

	if(setresgid(rgid, egid, sgid) < 0)
		return pusherr(L, errno);

	lua_pushinteger(L, 0);
	return 1;
}

static int
luasetresuid(lua_State *L)
{
	int ruid = luaL_checkinteger(L, 1);
	int euid = luaL_checkinteger(L, 2);
	int suid = luaL_checkinteger(L, 3);

	if(setresuid(ruid, euid, suid) < 0)
		return pusherr(L, errno);

	lua_pushinteger(L, 0);
	return 1;
}

static int
luasetproctitle(lua_State *L)
{
	const char *title = luaL_checkstring(L, 1);

	setproctitle("%s", title);

	return 0;
}

static const luaL_Reg extlib[] = {
	{"chroot", luachroot},
	{"pledge", luapledge},
	{"unveil", luaunveil},
	{"err", luaerr},
	{"setgroups", luasetgroups},
	{"setresgid", luasetresgid},
	{"setresuid", luasetresuid},
	{"setproctitle", luasetproctitle},
	{0, 0},
};

int
luaopen_pastebin_ext(lua_State *L)
{
	luaL_newlib(L, extlib);

	lua_pushinteger(L, EX_USAGE);
	lua_setfield(L, -2, "EX_USAGE");
	lua_pushinteger(L, EX_OSERR);
	lua_setfield(L, -2, "EX_OSERR");
	lua_pushinteger(L, EX_NOPERM);
	lua_setfield(L, -2, "EX_NOPERM");
	return 1;
}
