%% It's not used yet
-module(session_id).

-include_lib("eunit/include/eunit.hrl").

-export([new/0]).

new() -> integer_to_list(rand:new()).

store_session_id(SessionId) ->
	dets_storage:do(?MODULE, fun(Module) -> dets:insert(Module, {self(), SessionId}) end).

load_session_id() ->
	dets_storage:do(?MODULE, fun(Module) -> [{_, SessionId}] = dets:lookup(Module, self()), SessionId end).

remove_session_id() ->
	dets_storage:do(?MODULE, fun(Module) -> dets:delete(Module, self()) end).
  
%% Tests

session_id_storage_test_() ->
	Id = new(),
	store_session_id(Id),
	LoadedId = load_session_id(),	
	remove_session_id(),
	[
	?_assertMatch(Id, LoadedId),
	?_assertMatch([], dets_storage:do(?MODULE, fun(Module) -> dets:lookup(Module, self()) end))
	].