-module(transaction).

-include_lib("eunit/include/eunit.hrl").

-export([new/1, add_frame/1, is_in_transaction/0, commit/1, abort/1]).

new(Id) -> put(transaction, {Id, []}).

%% not check transaction ID yet
commit(_Id) -> 
	Frames = get_frames(),
	erase(transaction),
	Frames.

abort(Id) ->
	erase(transaction),
	Id.

is_in_transaction() -> get(transaction) /= undefined.

add_frame(Frame) ->
	{Id, Frames} = get(transaction),
	put(transaction, {Id, lists:reverse([Frame | lists:reverse(Frames)])}).

get_frames() -> 
	{_Id, Frames} = get(transaction),
	Frames.

%% Tests

setup() -> erase(transaction).

begin_transaction_test_() ->
	setup(),
	new("transaction_id"),
	[
	?_assert(is_in_transaction()),
	?_assertMatch([], get_frames())
	].
	
commit_transaction_test_() ->
	setup(),
	TxId = "transaction_id",
	new(TxId),
	State1 = is_in_transaction(),
	Frames = commit(TxId),
	State2 = is_in_transaction(),
	[
	?_assertMatch(true, State1),
	?_assertMatch(false, State2),
	?_assertMatch([], Frames)
	].
	
abort_transaction_test_() ->
	setup(),
	TxId = "transaction_id",
	new(TxId),
	State1 = is_in_transaction(),
	AbortResult = abort(TxId),
	State2 = is_in_transaction(),
	[
	?_assertMatch(true, State1),
	?_assertMatch(false, State2),
	?_assertMatch(TxId, AbortResult)
	].
	
add_frame_test_() ->
	setup(),
	TxId = "transaction_id",
	new(TxId),
	add_frame("frame1"),
	add_frame("frame2"),
	[
	?_assertMatch(["frame1", "frame2"], get_frames())
	].