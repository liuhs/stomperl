-module(dets_storage).

-include_lib("eunit/include/eunit.hrl").

-export([do/2]).

do(TableFile, Action) ->
	case dets:open_file(?MODULE, [{file, TableFile}]) of
		{ok, ?MODULE} ->
			Action(?MODULE);
		{error,_Reason} ->
			io:format("cannot open dets table: ~s~n", [TableFile]),
			exit(eDetsOpen)
	end.

%% Tests

storage_test_() ->
	TableFile = "storage/test.table",
	[
	?_assertMatch([], do(TableFile, fun(Module) -> dets:lookup(Module, does_not_exist) end))
	].