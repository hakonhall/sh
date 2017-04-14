# Make e.g. test_runner.sh accessible in PATH
export PATH

FORCE_PASS =

# The tests are run in order - that's why they are prefixed by a number.
TESTS := $(sort $(wildcard tests/*_test.sh))
PASS_PATHS := $(TESTS:tests/%_test.sh=test/%/pass)

.PHONY: all
all: test

.PHONY: test
test: PATH := $(PWD)/src:$(PWD)/tests:$(PATH)
test: $(PASS_PATHS)

# Always regenerte .Makefile.testdeps.autogen
.PHONY: .Makefile.testdeps.autogen
.Makefile.testdeps.autogen:
	main/makemake.sh > $@

-include .Makefile.testdeps.autogen

.PHONY: pass
pass: FORCE_PASS := --pass
pass: all

.PHONY: clean
clean:
	rm -f .Makefile.testdeps.autogen
	rm -rf test/*/actual
	rm -rf test/*/pass

.PHONY: re
re: clean all
