.PHONY: all version init submods pylint preflight sota test pristine

REPO := $(shell git rev-parse --show-toplevel)
RMRF = rm -rf
PYTHON := $(shell which python)
RPYTHON = src/pypy/rpython/bin/rpython
BUILDDIR = build
SRCDIR = src
BINDIR = $(BUILDDIR)/bin
LIBDIR = $(BUILDDIR)/lib
TARGET = targetsota.py
GSM = git submodule

PYLINT = pylint
PYLINTFLAGS = -E -j4 --rcfile .pylint.rc
PYFILES := $(wildcard src/*.py)

SOTA_VERSION=$(shell git describe)

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

colm: $(REPO)/bin/colm

ragel: $(REPO)/bin/ragel

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

$(REPO)/bin/colm:
	@echo [colm]
	cd src/colm && ./autogen.sh
	cd src/colm && ./configure --prefix=$(REPO)
	cd src/colm make && make install

$(REPO)/bin/ragel: $(REPO)/bin/colm
	@echo [ragel]
	cd src/ragel && ./autogen.sh
	cd src/ragel && ./configure --prefix=$(REPO) --with-colm=$(REPO)  --disable-manual
	cd src/ragel make && make install

$(LIBDIR)/liblexer.so: $(REPO)/bin/ragel
	@echo [liblexer]
	cd src/lexer && LD_LIBRARY_PATH=$(REPO)/lib make RAGEL=$(REPO)/bin/ragel
	install -C -D src/lexer/liblexer.so $(LIBDIR)/liblexer.so

$(BINDIR)/sota: $(LIBDIR)/libcli.so $(LIBDIR)/liblexer.so
	@echo [sota]
	mkdir -p $(BINDIR) $(LIBDIR)
	$(PYTHON) -B $(RPYTHON) --output $(BINDIR)/sota $(SRCDIR)/$(TARGET)

