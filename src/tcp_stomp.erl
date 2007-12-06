-module(tcp_stomp).

-include_lib("eunit/include/eunit.hrl").

% External API
-export([start_link/1]). 

% Callbacks
-export([init/2, recv/1]).

% External API
start_link(Socket) ->
  proc_lib:start_link(?MODULE, init, [self(), Socket]).

% Callbacks
init(Parent, Socket) ->
  proc_lib:init_ack(Parent, {ok, self()}),
  recv(Socket).

recv(Socket) ->
  case gen_tcp:recv(Socket, 0) of
    {ok, B} ->
%    	io:format("GOT DATA :\n~w~n", [B]),
			FrameText = binary_to_list(B),
      io:format("GOT FRAME:~n~s~n", [FrameText]),
      process_frame(Socket, FrameText),
      recv(Socket);
    {error, closed} ->
      ok
  end.

process_frame(Socket, FrameText) ->
	Frame = stomp_frame:parse(FrameText),
	io:format("[~w]FRAME COMMAND: ~s~n", [self(), stomp_frame:get_command(Frame)]),
	case stomp_frame:get_command(Frame) of
		"CONNECT" ->
			SessionId = session_id(),
			Message = "CONNECTED\nsession:" ++ SessionId ++ "\n\n\000\n",
			gen_tcp:send(Socket, list_to_binary(Message)),
			io:format("CONNECTED: ~s~n", [SessionId]);
		_Other ->
			ok
	end.

session_id() ->
	Number = random:uniform(c:memory(total)),
	integer_to_list(Number).

table_file() -> "storage/sessions.table".

store_session_id(SessionId) ->
	case dets:open_file(?MODULE, [{file, table_file()}]) of
		{ok, ?MODULE} ->
			dets:insert(?MODULE, {self(), SessionId});
		{error,_Reason} ->
			io:format("cannot open dets table: ~s~n", [table_file()]),
			exit(eDetsOpen)
	end.

load_session_id() ->
	case dets:open_file(?MODULE, [{file, table_file()}]) of
		{ok, ?MODULE} ->
			[{_, SessionId}] = dets:lookup(?MODULE, self()),
			SessionId;
		{error,_Reason} ->
			io:format("cannot open dets table: ~s~n", [table_file()]),
			exit(eDetsOpen)
	end.

remove_session_id() ->
	case dets:open_file(?MODULE, [{file, table_file()}]) of
		{ok, ?MODULE} ->
			dets:delete(?MODULE, self());
		{error,_Reason} ->
			io:format("cannot open dets table: ~s~n", [table_file()]),
			exit(eDetsOpen)
	end.
  
%% Tests

session_id_test_() ->
	Id1 = session_id(),
	Id2 = session_id(),
	[
	?_assert(Id1 /= Id2)
	].
  
session_id_storage_test_() ->
	Id = session_id(),
	store_session_id(Id),
	LoadedId = load_session_id(),	
	remove_session_id(),
	[
	?_assertMatch(Id, LoadedId),
	?_assertMatch([], dets:lookup(?MODULE, self()))
	].