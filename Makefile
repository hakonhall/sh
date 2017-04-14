AUTOGEN_MAKEFILE_DEPS = $(wildcard tests/*_test.sh) $(wildcard src/*.sh)

TEST_TARGET =

.PHONY: all
all: test

.PHONY: test
test: .Makefile.testdeps.autogen
	$(MAKE) -f Makefile.test $(MAKEFLAGS) $(TEST_TARGET)

.Makefile.testdeps.autogen: $(AUTOGEN_MAKEFILE_DEPS)
	main/makemake.sh > $@

.PHONY: pass
pass: TEST_TARGET := pass
pass: all

.PHONY: clean
clean:
	rm -f .Makefile.testdeps.autogen
	rm -rf test/*/actual
	rm -rf test/*/pass

.PHONY: re
re: clean all
