-module(subscription).

-include_lib("eunit/include/eunit.hrl").

subscribe(Pid, Dest) -> 
	dets_storage:do(?MODULE, fun(Module) -> dets:insert(Module, {rand:new(), Dest, Pid}) end).

find_subscribers(Dest) ->
	Action = fun(Module) ->
		Arrays = dets:match(Module, {'_', Dest, '$1'}),
		lists:map(fun(Array) -> lists:nth(1, Array) end, Arrays)
	end, 
	dets_storage:do(?MODULE, Action).

%% Tests

subscribe_test_() ->
	dets_storage:do(?MODULE, fun(Name) -> dets:delete_all_objects(Name) end),

	Pid = self(),
	Dest = "/a",
	subscribe(Pid, Dest),
	OneSubscriber = find_subscribers(Dest),
	subscribe("123", Dest),
	TwoSubscribers = find_subscribers(Dest),
	[
	?_assertMatch([Pid], OneSubscriber),
	?_assertMatch([Pid, "123"], TwoSubscribers)
	].