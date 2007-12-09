-module(tcp_acceptor).

-include_lib("eunit/include/eunit.hrl").

% External API
-export([start_link/2]). 

% Callbacks
-export([init/3, accept/2]).

% External API
start_link(Port, Table) ->
  proc_lib:start_link(?MODULE, init, [self(), Port, Table]).

% Callbacks
init(Parent, Port, Table) ->
  case gen_tcp:listen(
    Port, [{active, false}, binary, {packet, raw}, {reuseaddr, true}]
  ) of
    {ok, ListenSocket} ->
      proc_lib:init_ack(Parent, {ok, self()}),
      accept(ListenSocket, Table);
    {error, Reason} ->
      proc_lib:init_ack(Parent, {error, Reason}),
      error
  end.

accept(ListenSocket, Table) ->
  {ok, Socket} = gen_tcp:accept(ListenSocket),
  tcp_client_sup:start_child(Socket, Table),
  accept(ListenSocket, Table).

  
%% Tests

truth_test_() ->
	[
	?_assertMatch(1, 1)
	].
  