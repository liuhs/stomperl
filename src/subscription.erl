-module(subscription).

-include_lib("eunit/include/eunit.hrl").

subscribe(Pid, Dest) -> 
	dets_storage:do(table_file(), fun(Module) -> dets:insert(Module, {Dest, Pid}) end).

find_subscribers(Dest) -> 
	dets_storage:do(table_file(), fun(Module) -> lists:map(fun({_Dest, Pid}) -> Pid end, dets:lookup(Module, Dest)) end).

table_file() -> "storage/subscriptions.table".

%% Tests

subscribe_test_() ->
	Pid = self(),
	subscribe(Pid, "/a"),
	Subscribers = find_subscribers("/a"),
	[
	?_assertMatch([Pid], Subscribers)
	].