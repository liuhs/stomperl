EBIN = ebin
SRC = src

SRC_FILES = $(shell ls src/*.erl)
MODULES = $(SRC_FILES:src/%.erl=%)
OBJECTS = $(MODULES:%=$(EBIN)/%.beam)

all: update test status

.PHONY: update
update:
	svn up

.PHONY: status
status: clean
	svn st

.PHONY: compile
compile: ${OBJECTS}

# this should be default task
# but it's quite slow in cygwin
.PHONY: fulltest
fulltest: test
	make start &
	make acceptance

.PHONY: test
test: compile
	@for module in $(MODULES); do \
			(echo Testing Module $$module ...); \
			(erl -noshell -pa ${EBIN} -s $$module test -s init stop); \
	done

.PHONY: acceptance
acceptance:
	cd acceptance && ant
	pkill -9 erl

$(EBIN)/%.beam: ${SRC}/%.erl
	erlc -pa $(EBIN) -W  -o$(EBIN) $<

.PHONY: clean
clean:
	rm -f ${OBJECTS} erl_crash.dump src/*.beam storage/*.table
	cd acceptance && ant clean
	
.PHONY: start
start: compile
	erl -noshell -boot start_sasl -pa ${EBIN} -s tcp_server_sup