-module(tcp_stomp).

-include_lib("eunit/include/eunit.hrl").

% External API
-export([start_link/2]). 

% Callbacks
-export([init/3, recv/3]).

% External API
start_link(Socket, Table) ->
  proc_lib:start_link(?MODULE, init, [self(), Socket, Table]).

% Callbacks
init(Parent, Socket, Table) ->
  proc_lib:init_ack(Parent, {ok, self()}),
  {ok, Mailer} = proc_lib:start_link(mailer, init, [self(), Socket]),
  recv(Socket, Mailer, Table).

recv(Socket, Mailer, Table) ->
  case gen_tcp:recv(Socket, 0) of
    {ok, B} ->
%    	io:format("GOT DATA :\n~w~n", [B]),
			FrameText = binary_to_list(B),
      io:format("GOT FRAME:~n~s~n", [FrameText]),
      process_frame(Socket, FrameText, Mailer, Table),
      recv(Socket, Mailer, Table);
    {error, closed} ->
    	subscription:unsubscribe(Mailer, Table),
      ok
  end.

process_frame(Socket, FrameText, Mailer, Table) ->
	Frames = stomp_frame:parse_frames(FrameText),
	ProcessSingleFrame = fun(Frame) ->
		io:format("[~w]FRAME COMMAND: ~s~n", [self(), stomp_frame:get_command(Frame)]),
		case stomp_frame:get_command(Frame) of
			"CONNECT" ->
				SessionId = integer_to_list(rand:new()),
				Message = "CONNECTED\nsession:" ++ SessionId ++ "\n\n\000\n",
				gen_tcp:send(Socket, list_to_binary(Message)),
				io:format("CONNECTED: ~s~n", [SessionId]);
			"SUBSCRIBE" ->
				Dest = stomp_frame:get_header(Frame, "destination"),
				subscription:subscribe(Mailer, Dest, Table),
				io:format("Client of ~w SUBSCRIBED ~s~n", [Mailer, Dest]);
			"SEND" ->
				Dest = stomp_frame:get_header(Frame, "destination"),
				Body = stomp_frame:get_body(Frame),
				Subscribers = subscription:find_subscribers(Dest, Table),
				send(Subscribers, Body, Dest);
			_Other ->
				ok
		end
	end,
	lists:map(ProcessSingleFrame, Frames).

send([], _, _) -> ok;
send([Subscriber | Others], Body, Dest) ->
	io:format("SUBCSRIBER: ~w~n", [Subscriber]),
	Subscriber ! {send, Body, Dest},
	send(Others, Body, Dest).

%% Tests

truth_test_() ->
	[
	?_assertMatch(1, 1)
	].
