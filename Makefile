PROJECT := tcli
BUILDROOT := build
EXE := tcli
EXEPATH := $(BUILDROOT)/$(EXE)
CONF_PREFIX := /etc/$(PROJECT)

LOGFILE := tcli.log
CONFIGFILE := config.toml

.PHONY: all
all: $(EXEPATH)

$(EXEPATH): $(wildcard *.go)
	go build -o $(EXEPATH) -ldflags='-X main.logfile=$(LOGFILE) -X main.config=$(CONFIGFILE)'

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
	rm -rf $(BUILDROOT)

.PHONY: release
release:
	go build -o $(EXEPATH) -ldflags='-X main.logfile=$(CONF_PREFIX)/$(LOGFILE) -X main.config=$(CONF_PREFIX)/$(CONFIGFILE)'

.PHONY: install
install: $(EXEPATH)
	strip $(EXEPATH)
	install -D -m 644 $(CONFIGFILE) $(DESTDIR)/etc/tcli/$(CONFIGFILE)
	install -D -m 755 $(EXEPATH) $(DESTDIR)/usr/bin/$(EXE)
