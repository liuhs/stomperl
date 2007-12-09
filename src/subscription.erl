-module(subscription).

-include_lib("eunit/include/eunit.hrl").

-export([subscribe/3, find_subscribers/2, unsubscribe/2, unsubscribe/3]).

subscribe(Pid, Dest, Table) -> 
	ets:insert(Table, {rand:new(), subscription, Dest, Pid}).

find_subscribers(Dest, Table) ->
	Arrays = ets:match(Table, {'_', subscription, Dest, '$1'}),
	lists:map(fun(Array) -> lists:nth(1, Array) end, Arrays).

unsubscribe(Pid, Dest, Table) ->
	ets:match_delete(Table, {'_', subscription, Dest, Pid}).

unsubscribe(Pid, Table) ->
	ets:match_delete(Table, {'_', subscription, '_', Pid}).

%% Tests

setup() -> 
	ets:new(test, [ordered_set]).

subscribe_test_() ->
	Table = setup(),
	Pid = self(),
	Dest = "/a",
	subscribe(Pid, Dest, Table),
	OneSubscriber = find_subscribers(Dest, Table),
	subscribe("123", Dest, Table),
	TwoSubscribers = find_subscribers(Dest, Table),
	unsubscribe(Pid, Dest, Table),
	LastSubscriber = find_subscribers(Dest, Table),
	[
	?_assertMatch([Pid], OneSubscriber),
	?_assertMatch([Pid, "123"], TwoSubscribers),
	?_assertMatch(["123"], LastSubscriber)
	].
	
unsubscribe_test_() ->
	Table = setup(),
	Pid = self(),
	subscribe(Pid, "/a", Table),
	subscribe(anyone, "/a", Table),
	subscribe(Pid, "/b", Table),
	subscribe(anyone, "/b", Table),
	unsubscribe(Pid, Table),
	[
	?_assertMatch([anyone], find_subscribers("/a", Table)), 
	?_assertMatch([anyone], find_subscribers("/b", Table))
	].