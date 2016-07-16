.PHONY: all init submods pylint preflight sota test pristine

RMRF = $(shell which rmrf)
ifeq ($(RMRF),)
    RMRF = rm -rf
endif
PYTHON := $(shell which python)
RPYTHON = src/pypy/rpython/bin/rpython
BUILDDIR = build
SRCDIR = src
BINDIR = $(BUILDDIR)/bin
LIBDIR = $(BUILDDIR)/lib
TARGET = targetsota.py
VERSION=\"$(shell git describe)\"
GSM = git submodule

PYLINT = pylint
PYLINTFLAGS = -E -j4 --rcfile .pylint.rc
PYFILES := $(wildcard src/*.py)

SUBMODS := $(shell $(GSM) status | awk '{print $$2}')

all: sota

#submods:
#	$(GSM)  init
#	$(GSM) status | awk '{print $$2}' | xargs -P5 -n1 $(GSM) update

init:
	$(GSM) init

submods: init $(patsubst %, %.submod,$(SUBMODS))

%.submod:
	$(GSM) update $*

pylint: $(patsubst %.py,%.pylint,$(PYFILES))

%.pylint:
	$(PYLINT) $(PYLINTFLAGS) $*.py

preflight: pylint
	exit 0

sota: preflight submods $(BINDIR)/sota

test: sota
	exit 0

clean:
	@echo rmrf $(RMRF)
	$(RMRF) $(BUILDDIR)/

pristine:
	$(GSM) deinit --all
	git clean -xfd
	git reset --hard HEAD

$(BINDIR)/sota:
	mkdir -p $(BINDIR) $(LIBDIR)
	$(PYTHON) -B $(RPYTHON) --output $(BINDIR)/sota $(SRCDIR)/$(TARGET)

