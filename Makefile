.PHONY: clean all sota submods

PYTHON := $(shell which python)
RPYTHON = src/pypy/rpython/bin/rpython
BUILDDIR = build
SRCDIR = src
BINDIR = $(BUILDDIR)/bin
LIBDIR = $(BUILDDIR)/lib
TARGET = targetsota.py
VERSION=\"$(shell git describe)\"

all: sota

sota: $(BINDIR)/sota

submods:
	git submodule init
	git submodule status | awk '{print $$2}' | xargs -P5 -n1 git submodule update

$(BINDIR)/sota: submods
	mkdir -p $(BINDIR) $(LIBDIR)
	$(PYTHON) -B $(RPYTHON) --output $(BINDIR)/sota $(SRCDIR)/$(TARGET)

clean:
	rm -rf $(BUILDDIR)
