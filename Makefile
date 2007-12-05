EBIN = ebin
SRC = src

MODULES = tcp_server_sup tcp_acceptor tcp_client_sup tcp_echo tcp_stomp_fsm
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

.PHONY: test
test: compile
	@for module in $(MODULES); do \
			(echo Testing Module $$module ...); \
			(erl -noshell -pa ${EBIN} -s $$module test -s init stop); \
	done

$(EBIN)/%.beam: ${SRC}/%.erl
	erlc -pa $(EBIN) -W  -o$(EBIN) $<

.PHONY: clean
clean:
	rm -f ${OBJECTS} erl_crash.dump src/*.beam