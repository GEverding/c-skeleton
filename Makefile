
CC=clang
CFLAGS=-g -v -Wall -Werror -Wextra -Isrc -DNDEBUG $(OPTFLAGS)
LDFLAGS=-ldl $(OPTLIBS)
PREFIX=/usr/local

SOURCES=$(wildcard src/**/*.c src/*.c)
OBJECTS=$(patsubst %.c,%.o,$(SOURCES))

TEST_SRC=$(wildcard tests/*_tests.c)
TESTS=$(patsubst %.c,%,$(TEST_SRC))
TEST_OBJECTS=$(wildcard tests/*.o tests/**/*.o)

TARGET=build/libex29.a
SO_TARGET=$(patsubst %.a,%.so,$(TARGET))

# Target Build
all: $(TARGET) $(SO_TARGET) tests

dev: CFLAGS=-g -Wall -Isrc -Wall -Wextra -Werror $(OPTFLAGS)
dev: all

$(TARGET): CFLAGS +=-fPIC
$(TARGET): build $(OBJECTS)
	ar rcs $@ $(OBJECTS)
	ranlib $@

$(SO_TARGET): $(TARGET) $(OBJECTS)
	$(CC) -shared -o $@ $(OBJECTS)

build:
	@mkdir -p build
	@mkdir -p bin

# Unit Tests
.PHONY: tests

tests: CFLAGS += $(TARGET)
tests: $(TESTS)
	sh ./tests/runtests.sh

valgrind:
	VALGRIND="valgrind -log-file=/tmp/valgrind-%p.log" $(MAKE)

clean:
	rm -fr build $(OBJECTS) $(TESTS) $(TEST_OBJECTS)
	rm -f tests/tests.log
	find . -name "*.gc*" -exec rm {} \;
	rm -fr `find . -name "*.dSYM" -print`

format:
	astyle --style=kr \
		-wLs2 \
		--break-blocks \
		--pad-paren-in \
		--align-pointer=type \
		--align-reference=type \
		--max-code-length=80 \
		--suffix=node \
		$(SOURCES) $(HEADERS)

install: all
	install -d $(DESTDIR)/$(PREFIX)/lib/
	install $(TARGET) $(DESTDIR)/$(PREFIX)/lib/

BADFUNCS='[^_.>a-zA-Z0-9](str(n?cpy|n?cat|xfrm|n?dup|str|pbrk|tok|_)|stpn?cpy|a?sn?printf|byte_)'
check:
	@echo Files w/ Potentially Dangerous Functions
	@egrep $(BADFUNCS) $(SOURCES) || true
