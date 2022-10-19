PROJECT := tcli
BUILDROOT := build
EXE := tcli
EXEPATH := $(BUILDROOT)/$(EXE)

LOGFILE := tcli.log
CONFIGFILE := config.toml

.PHONY: all
all: $(EXEPATH)

$(EXEPATH): $(wildcard *.go)
	go build -ldflags='-X main.logfile=$(LOGFILE)'

$(BUILDROOT):
	mkdir -p $(BUILDROOT)

.PHONY: test
test:

.PHONY: fmt
fmt:
	gofmt -s -w -e  $(wildcard *.go)

.PHONY: clean
clean:
	rm -f tcli *.txt *.log

.PHONY: install
install: $(EXEPATH)
	strip $(EXEPATH)
	install -D -m 644 $(CONFIGFILE) $(DESTDIR)/etc/tcli/$(CONFIGFILE)
	install -D -m 511 $(EXEPATH) $(DESTDIR)/usr/bin/$(EXE)
