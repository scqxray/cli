TEST?=$$(go list ./... | grep -v /vendor/)
VETARGS?=-all

default: vet

# bin generates the releaseable binaries for Arukas
bin: fmtcheck generate
	@sh -c "'$(CURDIR)/scripts/build.sh'"

# dev creates binaries for testing Arukas locally. These are put
# into ./bin/ as well as $GOPATH/bin
dev: fmtcheck generate
	@TF_DEV=1 sh -c "'$(CURDIR)/scripts/build.sh'"

quickdev: generate
	@TF_QUICKDEV=1 TF_DEV=1 sh -c "'$(CURDIR)/scripts/build.sh'"

# Shorthand for quickly building the core of Arukas. Note that some
# changes will require a rebuild of everything, in which case the dev
# target should be used.
core-dev: fmtcheck generate
	go install github.com/arukasio/cli

# Shorthand for quickly testing the core of Arukas (i.e. "not providers")
core-test: generate
	@echo "Testing core packages..." && go test $(shell go list ./... | grep -v -E 'builtin|vendor')

# vet runs the Go source code static analysis tool `vet` to find
# any common errors.
vet:
	@go tool vet 2>/dev/null ; if [ $$? -eq 3 ]; then \
		go get golang.org/x/tools/cmd/vet; \
	fi
	@echo "go tool vet $(VETARGS) ."
	@go tool vet $(VETARGS) $$(ls -d */ | grep -v vendor) ; if [ $$? -eq 1 ]; then \
		echo ""; \
		echo "Vet found suspicious constructs. Please check the reported constructs"; \
		echo "and fix them if necessary before submitting the code for review."; \
		exit 1; \
	fi

# generate runs `go generate` to build the dynamically generated
# source files.
generate:
	@which stringer ; if [ $$? -ne 0 ]; then \
	  go get -u golang.org/x/tools/cmd/stringer; \
	fi
	go generate $$(go list ./... | grep -v /vendor/)

fmt:
	gofmt -w .

fmtcheck:
	@sh -c "'$(CURDIR)/scripts/gofmtcheck.sh'"

.PHONY: bin default generate test updatedeps vet fmt fmtcheck
