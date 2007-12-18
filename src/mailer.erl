-module(mailer).
-include_lib("eunit/include/eunit.hrl").

-export([init/2, send/2, send/3]).

%% APIs
init(Parent, SocketWrapper) ->
	proc_lib:init_ack(Parent, {ok, self()}),
	loop(SocketWrapper).

send([], _Table) -> ok;
send([Frame | Others], Table) ->
	Dest = stomp_frame:get_header(Frame, "destination"),
	Body = stomp_frame:get_body(Frame),
	Subscribers = subscription:find_subscribers(Dest, Table),
	case message_queue:is_queue(Dest) of 
		true ->
			message_queue:produce(Table, Dest, Body),
			notify(Subscribers, Dest, Table);
		false -> send(Subscribers, Body, Dest)
	end,
	send(Others, Table).

send([], _, _) -> ok;
send([Subscriber | Others], Body, Dest) ->
	log:debug("Sending to subscriber: ~w~n", [Subscriber]),
	Subscriber ! {send, Body, Dest},
	send(Others, Body, Dest).

notify([], _, _) -> ok;
notify([Subscriber | Others], Dest, Table) ->
	log:debug("Notifying subscriber: ~w~n", [Subscriber]),
	Subscriber ! {notify, Dest, Table},
	notify(Others, Dest, Table).

%% Mailer process
loop(SocketWrapper) ->
	receive
		{send, Body, Dest} ->
			send_to_socket(SocketWrapper, Body, Dest),
			loop(SocketWrapper);
		{notify, Dest, Table} ->
			check_queue(SocketWrapper, Table, Dest),
			loop(SocketWrapper);
		Other ->
			log:debug("I don't know how to handle this: ~p~n", [Other]),
			loop(SocketWrapper)
	end.

check_queue(SocketWrapper, Table, Dest) ->
	case message_queue:consume(Table, Dest) of
		undefined -> ok;
		Message -> 
			MessageId = send_to_socket(SocketWrapper, Message, Dest),
			case subscription:need_client_ack(self(), Dest, Table) of
				false -> ok;
				true ->
					receive
						{acked, MessageId} -> ok
					end
			end,
			check_queue(SocketWrapper, Table, Dest)
	end.

send_to_socket(SocketWrapper, Body, Dest) ->
	log:debug("Sending message to ~s from ~w~n", [Dest, self()]),
	MessageId = integer_to_list(rand:new()),
	MessageFrame = stomp_frame:new("MESSAGE", [{"destination", Dest}, {"message-id", MessageId}], Body),
	Message = stomp_frame:to_text(MessageFrame),
	socket_wrapper:send(SocketWrapper, list_to_binary(Message)),
	log:debug("MESSAGE sent from ~w:~n~s", [self(), Message]),
	MessageId.


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
