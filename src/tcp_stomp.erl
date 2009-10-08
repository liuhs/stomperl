-module(tcp_stomp).

-include_lib("eunit/include/eunit.hrl").

% External API
-export([start_link/2]). 

% Callbacks
-export([init/3, recv/4]).

% External API
start_link(Socket, Table) ->
  proc_lib:start_link(?MODULE, init, [self(), Socket, Table]).

% Callbacks
init(Parent, Socket, Table) ->
  proc_lib:init_ack(Parent, {ok, self()}),
	SocketWrapper = socket_wrapper:new(Socket),
  {ok, Mailer} = proc_lib:start_link(mailer, init, [self(), SocketWrapper]),
  recv(SocketWrapper, Mailer, Table, "").

recv(SocketWrapper, Mailer, Table, PreviousText) ->
  case socket_wrapper:recv(SocketWrapper, 0) of
    {ok, B} ->
%    	log:debug("GOT DATA :\n~w~n", [B]),
	  FrameText = string:concat(PreviousText, binary_to_list(B)),
	  recv_frame(SocketWrapper, Mailer, Table, FrameText, string:substr(FrameText, string:len(FrameText)));
    {error, closed} ->
    	subscription:unsubscribe(Mailer, Table),
      ok
  end.

recv_frame(SocketWrapper, Mailer, Table, FrameText, [0]) ->
	log:debug("GOT FRAME:~n~s~n", [FrameText]),
    process_frame(SocketWrapper, FrameText, Mailer, Table),
    recv(SocketWrapper, Mailer, Table, "");
recv_frame(SocketWrapper, Mailer, Table, FrameText, _Any) ->
	recv(SocketWrapper, Mailer, Table, FrameText).

process_frame(SocketWrapper, FrameText, Mailer, Table) ->
	Frames = stomp_frame:parse_frames(FrameText),
	ProcessSingleFrame = fun(Frame) ->
		log:debug("[~w]FRAME COMMAND: ~s~n", [self(), stomp_frame:get_command(Frame)]),
		case stomp_frame:get_command(Frame) of
			"CONNECT" ->
				SessionId = integer_to_list(rand:new()),
				Message = "CONNECTED\nsession:" ++ SessionId ++ "\n\n\000\n",
				socket_wrapper:send(SocketWrapper, list_to_binary(Message)),
				log:debug("CONNECTED: ~s~n", [SessionId]);
			"DISCONNECT" ->
				subscription:unsubscribe(Mailer, Table),
				socket_wrapper:close(SocketWrapper),
				log:debug("DISCONNECTED: mailer ~w~n", [Mailer]);
			"SUBSCRIBE" ->
				Dest = stomp_frame:get_header(Frame, "destination"),
				Ack = stomp_frame:get_header(Frame, "ack", "auto"),
				subscription:subscribe(Mailer, Dest, Ack, Table),
				mailer:notify([Mailer], Dest, Table),
				log:debug("Client of ~w SUBSCRIBED ~s~n", [Mailer, Dest]);
			"UNSUBSCRIBE" ->
				Dest = stomp_frame:get_header(Frame, "destination"),
				subscription:unsubscribe(Mailer, Dest, Table),
				log:debug("Client of ~w UNSUBSCRIBED ~s~n", [Mailer, Dest]);
			"SEND" ->
				case stomp_frame:get_header(Frame, "destination") of
					undefined -> error(SocketWrapper, "destination not specified", FrameText);
					_ ->
						case transaction:is_in_transaction() of
							false -> mailer:send([Frame], Table);
							true ->	transaction:add_frame(Frame)
						end
				end;
			"BEGIN" ->
				TransactionId = stomp_frame:get_header(Frame, "transaction", "transaction_id"),
				transaction:new(TransactionId),
				log:debug("BEGIN transaction ~s~n", [TransactionId]);
			"COMMIT" ->
				TransactionId = stomp_frame:get_header(Frame, "transaction", "transaction_id"),
				log:debug("COMMIT transaction ~s~n", [TransactionId]),
				FramesInTx = transaction:commit(TransactionId),
				mailer:send(FramesInTx, Table);
			"ABORT" ->
				TransactionId = stomp_frame:get_header(Frame, "transaction", "transaction_id"),
				transaction:abort(TransactionId),
				log:debug("ABORT transaction ~s~n", [TransactionId]);
			"ACK" ->
				MessageId = stomp_frame:get_header(Frame, "message-id"),
				mailer:ack(Mailer, MessageId);
			_Other ->
				ErrorMessage = stomp_frame:get_command(Frame) ++ " is unsupported command",
				log:debug("~s~n", [ErrorMessage]),
				error(SocketWrapper, ErrorMessage, FrameText)
		end,
		case stomp_frame:get_header(Frame, "receipt") of
			undefined -> ok;
			ReceiptId ->
				Receipt = "RECEIPT\nreceipt-id:" ++ ReceiptId ++ "\n\n\000\n",
				socket_wrapper:send(SocketWrapper, list_to_binary(Receipt)), 
				log:debug("RECEIPT ~s sent out~n", [ReceiptId])
		end
	end,
	lists:map(ProcessSingleFrame, Frames).

error(SocketWrapper, Message, Text) ->
	ErrorFrame = stomp_frame:new("ERROR", [{"message", Message}], Text),
	socket_wrapper:send(SocketWrapper, list_to_binary(stomp_frame:to_text(ErrorFrame))),
	log:debug("ERROR: ~s~n", [Message]).

%% Tests

report_error_test_() ->
	Text = "Test",
	Message = "test error",
	SocketWrapper = socket_wrapper:test_new(),
	error(SocketWrapper, Message, Text),
	[SentMessage | _] = socket_wrapper:get_sent_messages(SocketWrapper),
	[MessageFrame] = stomp_frame:parse_frames(SentMessage),	
	[
	?_assertMatch("ERROR", stomp_frame:get_command(MessageFrame)),
	?_assertMatch(Message, stomp_frame:get_header(MessageFrame, "message")),
	?_assertMatch(Text, stomp_frame:get_body(MessageFrame))
	].
