# --no-print-directory avoids messages like:
# make[1]: Entering directory '.../sh'
# make[1]: Leaving directory '.../sh'
MAKEFLAGS += --no-print-directory -j4 -l4 -O

AUTOGEN_MAKEFILE_DEPS = $(wildcard tests/*_test.sh) $(wildcard src/*.sh)

TEST_TARGET =

# This is needed because target-specific variables cannot affect prerequisites.
CLEAN_PREREQ =
ifeq ($(findstring clean,$(MAKECMDGOALS)) ,clean)
CLEAN_PREREQ = clean
else ifeq ($(findstring re,$(MAKECMDGOALS)),re)
CLEAN_PREREQ = clean
endif

.PHONY: test
test: .Makefile.testdeps.autogen
	@$(MAKE) -f Makefile.test $(MAKEFLAGS) $(TEST_TARGET)

.Makefile.testdeps.autogen: $(AUTOGEN_MAKEFILE_DEPS) $(CLEAN_PREREQ)
	main/makemake.sh > $@

.PHONY: pass
pass: TEST_TARGET := pass
pass: test

.PHONY: clean
clean:
	rm -rf .Makefile.testdeps.autogen test/*/actual test/*/pass

# re doesn't have a dependency on clean, since that's taken care of with
# CLEAN_PREREQ.
.PHONY: re
re: test
