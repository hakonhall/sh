# --no-print-directory avoids messages like:
# make[1]: Entering directory '.../sh'
# make[1]: Leaving directory '.../sh'
MAKEFLAGS += --no-print-directory -j4 -l4 -O

AUTOGEN_MAKEFILE_DEPS = $(wildcard tests/*_test.sh) $(wildcard src/*.sh)

TEST_TARGET =
maybe_clean = false

.PHONY: test
test: .Makefile.testdeps.autogen
	@$(MAKE) -f Makefile.test $(MAKEFLAGS) $(TEST_TARGET)

.Makefile.testdeps.autogen: $(AUTOGEN_MAKEFILE_DEPS) maybe-clean
	main/makemake.sh > $@

.PHONY: pass
pass: TEST_TARGET := pass
pass: test

.PHONY: clean
clean: maybe_clean = true
clean: maybe-clean

# All of this maybe-clean trickery is to:
#  1. Make sure we print nothing unless we actually try to delete
#  2. Print unexpanded rm command if we actually try to delete
#  3. Make sure maybe-clean is a prerequisite of .Makefile.testdeps.autogen
#     with 're', which guarantees parallel execution works fine.
#  4. Use the same .Makefile.testdeps.autogen target with both 're', 'test',
#     and 'clean'.
.PHONY: maybe-clean
maybe-clean:
	@if $(maybe_clean); then \
  echo rm -rf .Makefile.testdeps.autogen 'test/*/actual' 'test/*/pass'; \
  rm -rf .Makefile.testdeps.autogen test/*/actual test/*/pass; \
fi

.PHONY: re
re: maybe_clean = true
re: clean test
