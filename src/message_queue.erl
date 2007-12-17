-module(message_queue).

-include_lib("eunit/include/eunit.hrl").

is_queue([$q, $u, $e, $u, $e, $: | _Name]) -> true;
is_queue(_Dest) -> false.

%% Tests

is_queue_test_() ->
	[
	?_assertMatch(true, is_queue("queue:a")),
	?_assertMatch(false, is_queue("topic:a")),
	?_assertMatch(false, is_queue("a"))
	].
