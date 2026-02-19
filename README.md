# Pastebin

A pastebin in lua for OpenBSD

## Features

- SQLite storage
- OpenBSD-style priviledge separation

## Usage

### Dependencies

```
pkg_add -vi lua%5.4 luarocks-lua54 openssl%3.6 sqlite3
```

cqueues et al need to be built against OpenSSL, rather than base LibreSSL:
```sh
doas env ALL_LDFLAGS="$(pkg-config --libs eopenssl36) -Wl,-rpath=/usr/local/lib/eopenssl36" \
    CFLAGS="$(pkg-config --cflags eopenssl36)" \
    LDFLAGS="$(pkg-config --libs eopenssl36) -Wl,-rpath=$(pkg-config --variable=libdir eopenssl36)" \
    luarocks install cqueues http
```

### Install

```sh
doas luarocks-5.4 install --force add https://github.com/mischief/pastebin/raw/refs/heads/main/pastebin-dev-1.rockspec
doas pastebin sysinit
doas pastebin serve
```

## Paste

```sh
curl -d 'hello world' http://127.0.0.1:31686
```

## license

Copyright 2026 Nick Owens <mischief@offblast.org>

licensed under the MIT license. [see LICENSE](LICENSE).

