PROJECT := tcli
BUILDROOT := build
EXE := $(PROJECT)
EXEPATH := $(BUILDROOT)/$(EXE)
CONF_PREFIX := .
LOG_PREFIX := $(CONF_PREFIX)

LOGFILE := tcli.log
EXAMPLE_CONFIGFILE := config.toml.example
CONFIGFILE := $(EXAMPLE_CONFIGFILE)

.PHONY: all
all: $(EXEPATH)

$(EXEPATH): $(wildcard *.go)
	go build -o $(EXEPATH) -ldflags='-X main.logfile=$(CONF_PREFIX)/$(LOGFILE) -X main.config=$(CONF_PREFIX)/$(CONFIGFILE)'


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

.PHONY: install
install: $(EXEPATH)
	strip $(EXEPATH)
	cp $(EXAMPLE_CONFIGFILE) $(CONFIGFILE)
	install -D -m 666 $(CONFIGFILE) $(DESTDIR)/etc/tcli/$(CONFIGFILE)
	install -D -m 755 $(EXEPATH) $(DESTDIR)/usr/bin/$(EXE)
