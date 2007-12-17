-module(message_queue).

-include_lib("eunit/include/eunit.hrl").

is_queue([$q, $u, $e, $u, $e, $: | _Name]) -> true;
is_queue(_Dest) -> false.

produce(Table, Dest, Message) ->
	ets:insert(Table, {{queue, Dest, rand:new()}, Message}).

peek(Table, Dest) -> 
	Messages = get_messages(Table, Dest),
	case Messages of 
		[Message | _] -> Message;
		_ -> undefined
	end.

consume(Table, Dest) ->
	Message = peek(Table, Dest),
	case Message of
		undefined -> ok;
		_ ->
			[[IdToDelete] | _] = ets:match(Table, {{queue, Dest, '$1'}, '_'}),
			ets:match_delete(Table, {{queue, Dest, IdToDelete}, '_'})
	end,
	Message.

get_messages(Table, Dest) ->
	Arrays = ets:match(Table, {{queue, Dest, '_'}, '$1'}),
	case Arrays of
		[] -> [];
		_ -> lists:map(fun(Array) -> lists:nth(1, Array) end, Arrays)
	end.
	
%% Tests

setup() ->
	ets:new(test, [ordered_set]).

is_queue_test_() ->
	[
	?_assertMatch(true, is_queue("queue:a")),
	?_assertMatch(false, is_queue("topic:a")),
	?_assertMatch(false, is_queue("a"))
	].

produce_test_() ->
	Table = setup(),
	Dest = "queue:test",
	produce(Table, Dest, "hi"),
	produce(Table, Dest, "hello"),
	[
	?_assertMatch(["hi", "hello"], get_messages(Table, Dest))
	].
	
peek_and_consume_test_() ->
	Table = setup(),
	Dest = "queue:test",
	produce(Table, Dest, "hi"),
	produce(Table, Dest, "hello"),
	PeekedMessage = peek(Table, Dest),
	ConsumedMessage = consume(Table, Dest),
	[
	?_assertMatch(["hello"], get_messages(Table, Dest)),
	?_assertMatch("hi", PeekedMessage),
	?_assertMatch("hi", ConsumedMessage)
	].
	
peek_and_consume_empty_queue_test_() ->
	Table = setup(),
	Dest = "queue:test",
	[
	?_assertMatch([], get_messages(Table, Dest)),
	?_assertMatch(undefined, peek(Table, Dest)),
	?_assertMatch(undefined, consume(Table, Dest))
	].