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

init:
	$(GSM) init

submods: init $(patsubst %, %.submod,$(SUBMODS))

pylint: $(patsubst %.py,%.pylint,$(PYFILES))
	@echo pylint complete

preflight: pylint
	@echo prelight complete

sota: preflight submods $(BINDIR)/sota
	@echo sota built

test: sota
	@echo [test]

clean:
	@echo [clean]
	$(RMRF) $(BUILDDIR)/

pristine:
	@echo [pristine]
	$(GSM) deinit --all
	git clean -xfd
	git reset --hard HEAD

%.submod:
	$(GSM) update $*

%.pylint:
	$(PYLINT) $(PYLINTFLAGS) $*.py

$(BINDIR)/sota:
	@echo [sota]
	mkdir -p $(BINDIR) $(LIBDIR)
	$(PYTHON) -B $(RPYTHON) --output $(BINDIR)/sota $(SRCDIR)/$(TARGET)

