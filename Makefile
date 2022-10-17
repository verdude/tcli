all: tcli

tcli: $(wildcard *.go)
	go build

clean:
	rm -f tcli *.txt *.log
