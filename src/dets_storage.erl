-module(dets_storage).

-include_lib("eunit/include/eunit.hrl").

-export([do/2, clear/1]).

do(Name, Action) ->
	case dets:open_file(Name, [{file, table_file()}]) of
		{ok, Name} ->
			Result = Action(Name),
			dets:close(Name),
			Result;
		{error,_Reason} ->
			io:format("cannot open dets table: ~s~n", [table_file()]),
			exit(eDetsOpen)
	end.

clear(Name) -> do(Name, fun(N) -> dets:delete_all_objects(N) end).

table_file() -> "storage/1.table".

%% Tests

storage_test_() ->
	clear(?MODULE),
	do(?MODULE, fun(Name) -> dets:insert(Name, {key, value}) end),
	[
	?_assertMatch([{key, value}], do(?MODULE, fun(Name) -> dets:lookup(Name, key) end)),
	?_assertMatch([], do(?MODULE, fun(Name) -> dets:lookup(Name, does_not_exist) end))
	].