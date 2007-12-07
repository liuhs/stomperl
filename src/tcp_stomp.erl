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
			SessionId = session_id:new(),
			Message = "CONNECTED\nsession:" ++ SessionId ++ "\n\n\000\n",
			gen_tcp:send(Socket, list_to_binary(Message)),
			io:format("CONNECTED: ~s~n", [SessionId]);
		"SUBSCRIBE" ->
			Dest = stomp_frame:get_header(Frame, "destination"),
			subscription:subscribe(self(), Dest),
			io:format("Client of ~w SUBSCRIBED ~s~n", [self(), Dest]);
		_Other ->
			ok
	end.


%% Tests

truth_test_() ->
	[
	?_assertMatch(1, 1)
	].
