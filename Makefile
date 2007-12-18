EBIN = ebin
SRC = src

SRC_FILES = $(shell ls src/*.erl)
MODULES = $(SRC_FILES:src/%.erl=%)
OBJECTS = $(MODULES:%=$(EBIN)/%.beam)

# should run all tests (both unit and acceptance)
# but putting server in background makes cygwin very slow
# so only run unit tests for now
# on linux should run something like:
#   $ make startup &
#   $ make test
all: update unit_test status

.PHONY: update
update:
	svn up

.PHONY: status
status: clean
	svn st

.PHONY: compile
compile: ${OBJECTS}

$(EBIN)/%.beam: ${SRC}/%.erl
	erlc -pa $(EBIN) -W  -o$(EBIN) $<

.PHONY: test
test: unit_test acceptance_test

.PHONY: unit_test
unit_test: compile
	@for module in $(MODULES); do \
			(echo Testing Module $$module ...); \
			(erl -noshell -pa ${EBIN} -s $$module test -s init stop); \
	done

.PHONY: acceptance_test
acceptance_test:
	cd acceptance && ant
	cd acceptance/Stomp-0.02 && make
	cd acceptance/Net-Stomp-0.32 && make
	pkill -9 erl
	
.PHONY: startup
startup: compile
	erl -boot start_sasl -pz ${EBIN} -s tcp_server_sup -s erlang halt -debug true

.PHONY: clean
clean:
	rm -f ebin/*.beam erl_crash.dump src/*.beam storage/*.table
	cd acceptance && ant clean	