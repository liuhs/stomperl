-module(rand).

-include_lib("eunit/include/eunit.hrl").

-export([new/0]).

new() -> random:uniform(c:memory(total)).

%% Tests

rand_number_test_() ->
	Id1 = new(),
	Id2 = new(),
	[
	?_assert(Id1 /= Id2)
	].
