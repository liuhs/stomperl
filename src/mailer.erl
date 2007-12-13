-module(mailer).
-include_lib("eunit/include/eunit.hrl").

-export([init/2, send/2, send/3]).

init(Parent, Socket) ->
	proc_lib:init_ack(Parent, {ok, self()}),
	loop(Socket).

send([], _Table) -> ok;
send([Frame | Others], Table) ->
	Dest = stomp_frame:get_header(Frame, "destination"),
	Body = stomp_frame:get_body(Frame),
	Subscribers = subscription:find_subscribers(Dest, Table),
	send(Subscribers, Body, Dest),
	send(Others, Table).

send([], _, _) -> ok;
send([Subscriber | Others], Body, Dest) ->
	log:debug("SUBCSRIBER: ~w~n", [Subscriber]),
	Subscriber ! {send, Body, Dest},
	send(Others, Body, Dest).

	
loop(Socket) ->
	receive
		{send, Body, Dest} ->
			log:debug("Sending message to ~s from ~w~n", [Dest, self()]),
			MessageFrame = stomp_frame:new("MESSAGE", [{"destination", Dest}, {"message-id", integer_to_list(rand:new())}], Body),
			Message = stomp_frame:to_text(MessageFrame),
			gen_tcp:send(Socket, list_to_binary(Message)),
			log:debug("MESSAGE sent from ~w:~n~s", [self(), Message]),
			loop(Socket);
		Other ->
			log:debug("I don't know how to handle this: ~p~n", [Other]),
			loop(Socket)
	end.

%% Tests

truth_test_() ->
	[
	?_assertMatch(1, 1)
	].
