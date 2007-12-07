-module(subscription).

-include_lib("eunit/include/eunit.hrl").

-export([subscribe/2, find_subscribers/1, unsubscribe/1, unsubscribe/2]).

subscribe(Pid, Dest) -> 
	dets_storage:do(?MODULE, fun(Module) -> dets:insert(Module, {rand:new(), Dest, Pid}) end).

find_subscribers(Dest) ->
	Action = fun(Module) ->
		Arrays = dets:match(Module, {'_', Dest, '$1'}),
		lists:map(fun(Array) -> lists:nth(1, Array) end, Arrays)
	end, 
	dets_storage:do(?MODULE, Action).

unsubscribe(Pid, Dest) ->
	dets_storage:do(?MODULE, fun(Module) -> dets:match_delete(Module, {'_', Dest, Pid}) end).

unsubscribe(Pid) ->
	dets_storage:do(?MODULE, fun(Module) -> dets:match_delete(Module, {'_', '_', Pid}) end).

%% Tests

setup() -> 
	dets_storage:do(?MODULE, fun(Name) -> dets:delete_all_objects(Name) end).

subscribe_test_() ->
	setup(),
	Pid = self(),
	Dest = "/a",
	subscribe(Pid, Dest),
	OneSubscriber = find_subscribers(Dest),
	subscribe("123", Dest),
	TwoSubscribers = find_subscribers(Dest),
	unsubscribe(Pid, Dest),
	LastSubscriber = find_subscribers(Dest),
	[
	?_assertMatch([Pid], OneSubscriber),
	?_assertMatch([Pid, "123"], TwoSubscribers),
	?_assertMatch(["123"], LastSubscriber)
	].
	
unsubscribe_test_() ->
	setup(),
	Pid = self(),
	subscribe(Pid, "/a"),
	subscribe(anyone, "/a"),
	subscribe(Pid, "/b"),
	subscribe(anyone, "/b"),
	unsubscribe(Pid),
	[
	?_assertMatch([anyone], find_subscribers("/a")), 
	?_assertMatch([anyone], find_subscribers("/b"))
	].