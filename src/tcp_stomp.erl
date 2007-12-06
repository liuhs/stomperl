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
	io:format("FRAME COMMAND: ~s~n", [stomp_frame:get_command(Frame)]),
	case stomp_frame:get_command(Frame) of
		"CONNECT" ->
			io:format("CONNECTED~n"),
			gen_tcp:send(Socket, <<"CONNECTED\nsession:123\n\n\000\n">>)
	end.
  
%% Tests

truth_test_() ->
	[
	?_assertMatch(1, 1)
	].
  