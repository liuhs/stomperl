-module(mailer).
-include_lib("eunit/include/eunit.hrl").

-export([init/2, send/2, send/3]).

init(Parent, SocketWrapper) ->
	proc_lib:init_ack(Parent, {ok, self()}),
	loop(SocketWrapper).

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

	
loop(SocketWrapper) ->
	receive
		{send, Body, Dest} ->
			send_to_socket(SocketWrapper, Body, Dest),
			loop(SocketWrapper);
		Other ->
			log:debug("I don't know how to handle this: ~p~n", [Other]),
			loop(SocketWrapper)
	end.

send_to_socket(SocketWrapper, Body, Dest) ->
	log:debug("Sending message to ~s from ~w~n", [Dest, self()]),
	MessageFrame = stomp_frame:new("MESSAGE", [{"destination", Dest}, {"message-id", integer_to_list(rand:new())}], Body),
	Message = stomp_frame:to_text(MessageFrame),
	socket_wrapper:send(SocketWrapper, list_to_binary(Message)),
	log:debug("MESSAGE sent from ~w:~n~s", [self(), Message]).


%% Tests

send_to_socket_test_() ->
	SocketWrapper = socket_wrapper:test_new(),
	send_to_socket(SocketWrapper, "hello", "/a/b"),
	[SentMessage | _] = socket_wrapper:get_sent_messages(SocketWrapper),
	[MessageFrame] = stomp_frame:parse_frames(SentMessage),
	[
	?_assertMatch("MESSAGE", stomp_frame:get_command(MessageFrame)),
	?_assertMatch("/a/b", stomp_frame:get_header(MessageFrame, "destination")),
	?_assertMatch("hello", stomp_frame:get_body(MessageFrame))
	].
