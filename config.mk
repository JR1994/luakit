# === Luakit Makefile Configuration ==========================================

# Compile/link options.
CC         ?= gcc
CFLAGS     += -std=gnu99 -ggdb -W -Wall -Wextra -DGDK_DISABLE_DEPRECATED -DGTK_DISABLE_DEPRECATED
LDFLAGS    +=
CPPFLAGS   +=

# Get current luakit version.
VERSION    ?= $(shell ./build-utils/getversion.sh)
CPPFLAGS   += -DVERSION=\"$(VERSION)\"

# === Paths ==================================================================

PREFIX     ?= /usr/local
MANPREFIX  ?= $(PREFIX)/share/man
DOCDIR     ?= $(PREFIX)/share/luakit/docs

INSTALLDIR := $(DESTDIR)$(PREFIX)
MANPREFIX  := $(DESTDIR)$(MANPREFIX)
DOCDIR     := $(DESTDIR)$(DOCDIR)

# Should luakit be built to load relative config paths (./lib ./config) ?
# (Useful when running luakit from it's source directory, disable otherwise).
ifneq ($(DEVELOPMENT_PATHS),0)
	CPPFLAGS += -DDEVELOPMENT_PATHS
endif

# === Platform specific ======================================================

uname_s := $(shell uname -s)

# Mac OSX
ifeq ($(uname_s),Darwin)
	LINKER_EXPORT_DYNAMIC = 0
endif

# Some systems need the --export-dynamic linker option to load other
# dynamically linked C Lua modules (for example lua-filesystem).
ifneq ($(LINKER_EXPORT_DYNAMIC),0)
	LDFLAGS += -Wl,--export-dynamic
endif

# === Lua package name detection =============================================

LUA_PKG_NAMES += lua51 lua-5.1 lua5.1 lua

# Force linking against Lua's Just-In-Time compiler.
# See http://luajit.org/ for more information.
ifeq ($(USE_LUAJIT),1)
	LUA_PKG_NAME  := luajit
else
# User hasn't specificed, use LuaJIT if we can find it.
ifneq ($(USE_LUAJIT),0)
	LUA_PKG_NAMES := luajit $(LUA_PKG_NAMES)
endif
endif

# Search for Lua package name if not forced by user.
ifeq ($(LUA_PKG_NAME),)
LUA_PKG_NAME = $(shell sh -c '(for name in $(LUA_PKG_NAMES); do \
	       pkg-config --exists $$name && echo $$name; done) | head -n 1')
endif

# === Required build packages ================================================

# Packages required to build luakit.
ifeq ($(USE_GTK3),1)
	PKGS += gtk+-3.0
else
	PKGS += gtk+-2.0
endif
PKGS += gthread-2.0
ifeq ($(USE_GTK3),1)
	PKGS += webkitgtk-3.0
else
	PKGS += webkit-1.0
endif
PKGS += sqlite3
PKGS += $(LUA_PKG_NAME)

# For systems using older WebKit-GTK versions which bundle JavaScriptCore
# within the WebKit-GTK package.
ifneq ($(NO_JAVASCRIPTCORE),1)
ifeq ($(USE_GTK3),1)
	PKGS += javascriptcoregtk-3.0
else
	PKGS += javascriptcoregtk-1.0
endif
endif

# Build luakit with single instance support?
ifneq ($(USE_UNIQUE),0)
	CPPFLAGS += -DWITH_UNIQUE
ifneq ($(USE_GTK3),1)
	PKGS     += unique-1.0
endif
endif

# Check user has correct packages installed (and found by pkg-config).
PKGS_OK := $(shell pkg-config --print-errors --exists $(PKGS) && echo 1)
ifneq ($(PKGS_OK),1)
	$(error Cannot find required package(s\) to build luakit. Please \
	check you have the above packages installed and try again.)
endif

# Add pkg-config options to compile flags.
CFLAGS  += $(shell pkg-config --cflags $(PKGS))
CFLAGS  += -I./

# Add pkg-config options to linker flags.
LDFLAGS += $(shell pkg-config --libs $(PKGS))
