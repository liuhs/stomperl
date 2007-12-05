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
      case B of
        <<"bye\r\n">> ->
          gen_tcp:send(Socket, <<"cya\r\n">>),
          gen_tcp:close(Socket);
        Other ->
          gen_tcp:send(Socket, Other),
          recv(Socket)
      end;
    {error, closed} ->
      ok
  end.

  
%% Tests

truth_test_() ->
	[
	?_assertMatch(1, 1)
	].
  