PROJECT := tcli
BUILDROOT := zig-out
EXE := $(PROJECT)
EXEPATH := $(BUILDROOT)/bin/$(EXE)
EXAMPLE_CONFIGFILE := config.toml.example
CONFIGFILE := $(EXAMPLE_CONFIGFILE)

.PHONY: all
all: $(EXEPATH)

$(EXEPATH): build.zig src/*.zig
	zig build -Doptimize=ReleaseFast

.PHONY: test
test:
	zig build test

.PHONY: fmt
fmt:
	zig fmt src/*.zig

.PHONY: clean
clean:
	rm -f tcli *.txt *.log
	rm -rf zig-out .zig-cache

.PHONY: install
install: $(EXEPATH)
ifneq ($(EXAMPLE_CONFIGFILE),$(CONFIGFILE))
	cp $(EXAMPLE_CONFIGFILE) $(CONFIGFILE)
endif
	install -D -m 666 $(CONFIGFILE) $(DESTDIR)/etc/$(PROJECT)/$(CONFIGFILE)
	install -D -m 755 -s $(EXEPATH) $(DESTDIR)/usr/bin/$(EXE)
