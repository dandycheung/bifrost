SHELL = bash
OSARCHES := "darwin/amd64 linux/386 linux/amd64 linux/arm linux/arm64 linux/ppc64 linux/ppc64le linux/s390x"
OUTPUT := "build/bifrost-$(VERSION)-{{.OS}}-{{.Arch}}/bifrost"


test:
	@socat pty,link=/tmp/bifrostmaster,echo=0,crnl pty,link=/tmp/bifrostslave,echo=0,crnl & echo "$$!" > "socat.pid"
	go test -v
	@if [ -a socat.pid ]; then \
		kill -TERM $$(cat socat.pid) || true; \
		rm socat.pid || true; \
	fi


test_coverage:
	@socat pty,link=/tmp/bifrostmaster,echo=0,crnl pty,link=/tmp/bifrostslave,echo=0,crnl & echo "$$!" > "socat.pid"
	go test -v -coverprofile=cover.out && go tool cover -html=cover.out
	@if [ -a socat.pid ]; then \
		kill -TERM $$(cat socat.pid) || true; \
	fi
	@rm socat.pid


# build darwin/amd64 separately when building on Linux
# use cross compiler xgo
# xgo --targets=darwin/amd64 github.com/ishuah/bifrost
build_all:
	if [ -z $(VERSION) ]; then \
	  echo "You need to specify a VERSION"; \
	  exit 1; \
	fi

	mkdir -p build
	if [ -d "build/" ]; then \
    	rm -rf build/*; \
	fi
	gox -osarch=$(OSARCHES) -output=$(OUTPUT) # add -cgo flag when building on MacOS
	echo "compressing build files"
	cd build && for d in */; do filepath=$${d%/*}; echo $$filepath; zip "$${filepath##*/}.zip" "$${filepath##*/}/bifrost"; done