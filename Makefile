.PHONY: all version init submods pylint preflight sota test pristine

RMRF = rm -rf
REPO := $(shell git rev-parse --show-toplevel)
PYTHON := $(shell which python)
RPYTHON = src/pypy/rpython/bin/rpython
BUILDDIR = $(REPO)/build
SRCDIR = src
BINDIR = $(BUILDDIR)/bin
LIBDIR = $(BUILDDIR)/lib
TARGET = targetsota.py
GSM = git submodule
PYLINT = pylint
PYLINTFLAGS = -E -j4 --rcfile .pylint.rc
PYFILES	:= $(wildcard src/*.py)
SOTA_VERSION := $(shell git describe)

export LD_LIBRARY_PATH=$(BUILDDIR)/lib/

define VERSIONH
#ifndef __SOTA_VERSION__
#define __SOTA_VERSION__

#include <string>
static const std::string SOTA_VERSION = "$(SOTA_VERSION)";

#endif /*__SOTA_VERSION__*/
endef
export VERSIONH

define VERSIONPY
SOTA_VERSION = '$(SOTA_VERSION)'
endef
export VERSIONPY

SUBMODS := $(shell $(GSM) status | awk '{print $$2}')

all: sota

version: src/version.h src/version.py

init:
	$(GSM) init

submods: init $(patsubst %, %.submod,$(SUBMODS))

pylint: $(patsubst %.py,%.pylint,$(PYFILES))
	@echo pylint complete

preflight: pylint
	@echo prelight complete

libcli: $(LIBDIR)/libcli.so

colm: $(BUILDDIR)/bin/colm

ragel: $(BUILDDIR)/bin/ragel

liblexer: $(LIBDIR)/liblexer.so

sota: preflight submods $(BINDIR)/sota
	@echo sota built

test: sota
	@echo [test]

clean:
	@echo [clean]
	$(RMRF) $(BUILDDIR)/

pristine:
	@echo [pristine]
	$(GSM) deinit .
	git clean -xfd
	git reset --hard HEAD

src/version.h:
	echo "$$VERSIONH" > $@

src/version.py:
	echo "$$VERSIONPY" > $@

%.submod:
	$(GSM) update $*

%.pylint:
	$(PYLINT) $(PYLINTFLAGS) $*.py

$(LIBDIR)/libcli.so: src/version.h
	@echo [libcli]
	cd src/cli && make
	install -C -D src/cli/libcli.so $(LIBDIR)/libcli.so

$(BUILDDIR)/bin/colm:
	@echo [colm]
	cd src/colm && autoreconf -f -i
	cd src/colm && ./configure --prefix=$(BUILDDIR)
	cd src/colm make && make install

$(BUILDDIR)/bin/ragel: $(BUILDDIR)/bin/colm
	@echo [ragel]
	cd src/ragel && autoreconf -f -i
	cd src/ragel && ./configure --prefix=$(BUILDDIR) --with-colm=$(BUILDDIR)  --disable-manual
	(cd src/ragel/src && make parse.c)
	cd src/ragel && make && make install

$(LIBDIR)/liblexer.so: $(BUILDDIR)/bin/ragel
	@echo [liblexer]
	cd src/lexer && make RAGEL=$(BUILDDIR)/bin/ragel
	install -C -D src/lexer/liblexer.so $(LIBDIR)/liblexer.so

$(BINDIR)/sota: $(LIBDIR)/libcli.so $(LIBDIR)/liblexer.so
	@echo [sota]
	mkdir -p $(BINDIR) $(LIBDIR)
	$(PYTHON) -B $(RPYTHON) --output $(BINDIR)/sota $(SRCDIR)/$(TARGET)

