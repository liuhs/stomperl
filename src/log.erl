-module(log).

-include_lib("eunit/include/eunit.hrl").

-export([debug/1, debug/2]).

debug(Text) -> debug(Text, []).

debug(Text, Params) ->
	case init:get_argument(debug) of
		{ok, [["true"]]} -> io:format(Text, Params);
		_ -> ok
	end.

%% Tests

truth_test_() ->
	[
	?_assertMatch(1, 1)
	].
