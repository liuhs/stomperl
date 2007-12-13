-module(socket_wrapper).

-include_lib("eunit/include/eunit.hrl").

-export([new/1, recv/2, send/2, close/1]).
%% Methods for test
-export([test_new/0, test_new/1, get_sent_messages/1]).

new(Socket) -> new(Socket, false).
new(Socket, Test) -> {?MODULE, Socket, Test}.

is_test({?MODULE, _Socket, Test}) -> Test.
get_socket({?MODULE, Socket, _Test}) -> Socket.

recv(Wrapper, Length) -> 
	case is_test(Wrapper) of
		true -> mock_recv(Wrapper, Length);
		false -> gen_tcp:recv(get_socket(Wrapper), Length)
	end.

send(Wrapper, Binary) ->
	case is_test(Wrapper) of
		true -> mock_send(Wrapper, Binary); 
		false -> gen_tcp:send(get_socket(Wrapper), Binary)
	end.

close(Wrapper) -> gen_tcp:close(get_socket(Wrapper)).

test_new() -> test_new([]).
test_new(Messages) -> 
	Wrapper = new(mock_socket, true),
	put(Wrapper, {Messages, []}),
	Wrapper.

mock_send(Wrapper, Binary) ->
	put(Wrapper, {get_queued_messages(Wrapper), lists:reverse([Binary | lists:reverse(get_sent_binaries(Wrapper))])}).

mock_recv(Wrapper, _Length) ->
	{[Message | Others], Binaries} = get(Wrapper),
	put(Wrapper, {Others, Binaries}),
	list_to_binary(Message).

get_sent_binaries(Wrapper) ->
	{_Messages, Binaries} = get(Wrapper),
	Binaries.

get_queued_messages(Wrapper) ->
	{Messages, _Binaries} = get(Wrapper),
	Messages.

get_sent_messages(Wrapper) -> 
	lists:map(fun binary_to_list/1, get_sent_binaries(Wrapper)).

%% Tests
new_wrapper_test_() ->
	ProductionWrapper = new(sock1),
	TestWrapper = new(sock2, true),
	[
	?_assertMatch(false, is_test(ProductionWrapper)),
	?_assertMatch(sock1, get_socket(ProductionWrapper)),
	?_assertMatch(true, is_test(TestWrapper)),
	?_assertMatch(sock2, get_socket(TestWrapper))
	].
	
send_in_test_environment_test_() ->
	SocketWrapper = test_new(),
	send(SocketWrapper, list_to_binary("hello")),
	send(SocketWrapper, list_to_binary("world")),
	[
	?_assertMatch(["hello", "world"], get_sent_messages(SocketWrapper))
	].
	
recv_in_test_environment_test_() ->
	SocketWrapper = test_new(["hello", "world"]),
	Binary1 = recv(SocketWrapper, 0),
	Binary2 = recv(SocketWrapper, 0),
	[
	?_assertMatch("hello", binary_to_list(Binary1)),
	?_assertMatch("world", binary_to_list(Binary2))
	].