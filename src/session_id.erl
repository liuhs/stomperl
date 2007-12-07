-module(session_id).

-include_lib("eunit/include/eunit.hrl").

-export([new/0]).

new() ->
	Number = random:uniform(c:memory(total)),
	integer_to_list(Number).

table_file() -> "storage/sessions.table".

store_session_id(SessionId) ->
	dets_storage:do(table_file(), fun(Module) -> dets:insert(Module, {self(), SessionId}) end).

load_session_id() ->
	dets_storage:do(table_file(), fun(Module) -> [{_, SessionId}] = dets:lookup(Module, self()), SessionId end).

remove_session_id() ->
	dets_storage:do(table_file(), fun(Module) -> dets:delete(Module, self()) end).
  
%% Tests

session_id_test_() ->
	Id1 = new(),
	Id2 = new(),
	[
	?_assert(Id1 /= Id2)
	].
  
session_id_storage_test_() ->
	Id = new(),
	store_session_id(Id),
	LoadedId = load_session_id(),	
	remove_session_id(),
	[
	?_assertMatch(Id, LoadedId),
	?_assertMatch([], dets_storage:do(table_file(), fun(Module) -> dets:lookup(Module, self()) end))
	].