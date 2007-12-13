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
%    	log:debug("GOT DATA :\n~w~n", [B]),
			FrameText = binary_to_list(B),
      log:debug("GOT FRAME:~n~s~n", [FrameText]),
      process_frame(Socket, FrameText, Mailer, Table),
      recv(Socket, Mailer, Table);
    {error, closed} ->
    	subscription:unsubscribe(Mailer, Table),
      ok
  end.

process_frame(Socket, FrameText, Mailer, Table) ->
	Frames = stomp_frame:parse_frames(FrameText),
	ProcessSingleFrame = fun(Frame) ->
		log:debug("[~w]FRAME COMMAND: ~s~n", [self(), stomp_frame:get_command(Frame)]),
		case stomp_frame:get_command(Frame) of
			"CONNECT" ->
				SessionId = integer_to_list(rand:new()),
				Message = "CONNECTED\nsession:" ++ SessionId ++ "\n\n\000\n",
				gen_tcp:send(Socket, list_to_binary(Message)),
				log:debug("CONNECTED: ~s~n", [SessionId]);
			"DISCONNECT" ->
				subscription:unsubscribe(Mailer, Table),
				gen_tcp:close(Socket),
				log:debug("DISCONNECTED: mailer ~w~n", [Mailer]);
			"SUBSCRIBE" ->
				Dest = stomp_frame:get_header(Frame, "destination"),
				subscription:subscribe(Mailer, Dest, Table),
				log:debug("Client of ~w SUBSCRIBED ~s~n", [Mailer, Dest]);
			"UNSUBSCRIBE" ->
				Dest = stomp_frame:get_header(Frame, "destination"),
				subscription:unsubscribe(Mailer, Dest, Table),
				log:debug("Client of ~w UNSUBSCRIBED ~s~n", [Mailer, Dest]);
			"SEND" ->
				case transaction:is_in_transaction() of
					false -> send([Frame], Table);
					true ->	transaction:add_frame(Frame)
				end;
			"BEGIN" ->
				TransactionId = stomp_frame:get_header(Frame, "transaction", "transaction_id"),
				transaction:new(TransactionId),
				log:debug("BEGIN transaction ~s~n", [TransactionId]);
			"COMMIT" ->
				TransactionId = stomp_frame:get_header(Frame, "transaction", "transaction_id"),
				log:debug("COMMIT transaction ~s~n", [TransactionId]),
				FramesInTx = transaction:commit(TransactionId),
				send(FramesInTx, Table);
			"ABORT" ->
				TransactionId = stomp_frame:get_header(Frame, "transaction", "transaction_id"),
				transaction:abort(TransactionId),
				log:debug("ABORT transaction ~s~n", [TransactionId]);
			_Other ->
				log:debug("~s is unsupported command~n", [stomp_frame:get_command(Frame)]),
				ok
		end,
		case stomp_frame:get_header(Frame, "receipt") of
			undefined -> ok;
			ReceiptId ->
				Receipt = "RECEIPT\nreceipt-id:" ++ ReceiptId ++ "\n\n\000\n",
				gen_tcp:send(Socket, list_to_binary(Receipt)), 
				log:debug("RECEIPT ~s sent out~n", [ReceiptId])
		end
	end,
	lists:map(ProcessSingleFrame, Frames).

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

%% Tests

truth_test_() ->
	[
	?_assertMatch(1, 1)
	].
