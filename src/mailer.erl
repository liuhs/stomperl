-module(mailer).
-include_lib("eunit/include/eunit.hrl").

-export([init/2]).

init(Parent, Socket) ->
	proc_lib:init_ack(Parent, {ok, self()}),
	loop(Socket).
	
loop(Socket) ->
	receive
		{send, Body, Dest} ->
			io:format("Sending message to ~s from ~w~n", [Dest, self()]),
			Message = "MESSAGE\ndestination:" ++ Dest ++ "\nmessage-id:" ++ integer_to_list(rand:new()) ++ "\n\n" ++ Body ++ "\n", 
			gen_tcp:send(Socket, list_to_binary(Message)),
			io:format("MESSAGE sent from ~w:~n~s", [self(), Message]),
			loop(Socket);
		Other ->
			io:format("I don't know how to handle this: ~p~n", [Other]),
			loop(Socket)
	end.

%% Tests

truth_test_() ->
	[
	?_assertMatch(1, 1)
	].
