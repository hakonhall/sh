# --no-print-directory avoids messages like:
# make[1]: Entering directory '.../sh'
# make[1]: Leaving directory '.../sh'
#
# Parallel execution (-j4 -l4 -O) doesn't work with 'make clean test': Looks
# like a parallel thread verifies there's nothing to do for 'test', before
# proceeding with 'clean'.  The net result is that only clean has been run.
# If, however, e.g. .Makefile.testdeps.autogen doesn't exist it is regenerated
# after clean and before 'test'.  Confusing.
MAKEFLAGS += --no-print-directory

AUTOGEN_MAKEFILE_DEPS = $(wildcard tests/*_test.sh) $(wildcard src/*.sh)

TEST_TARGET =

.PHONY: test
test: .Makefile.testdeps.autogen
	$(MAKE) -f Makefile.test $(MAKEFLAGS) $(TEST_TARGET)

.PHONY: test-after-clean
test-after-clean: clean .Makefile.testdeps.autogen
	$(MAKE) -f Makefile.test $(MAKEFLAGS) $(TEST_TARGET)

.Makefile.testdeps.autogen: $(AUTOGEN_MAKEFILE_DEPS)
	main/makemake.sh > $@

.PHONY: pass
pass: TEST_TARGET := pass
pass: test

.PHONY: clean
clean:
	rm -f .Makefile.testdeps.autogen
	rm -rf test/*/actual
	rm -rf test/*/pass

.PHONY: re
re: clean test-after-clean
