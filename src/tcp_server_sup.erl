-module(tcp_server_sup).
-behaviour(supervisor).

-include_lib("eunit/include/eunit.hrl").

-include("tcp_server.hrl").

% External API
-export([start_server/0, start_link/2, stop/0]). 

% Callbacks
-export([init/1]). 

% External API
start_server() ->	start_link(61613, tcp_stomp).

start_link(Port, Module) when is_integer(Port) ->
  supervisor:start_link({local, ?MODULE}, ?MODULE, [Port, Module]).

stop() ->
  case whereis(?MODULE) of
    Pid when pid(Pid) ->
      exit(Pid, shutdown),
      ok;
    _ -> not_started
  end.

% Callbacks
init([Port, Module]) ->
  {ok, {{one_for_one, ?MAX_RESTART, ?MAX_TIME}, [
    {
      tcp_acceptor,
      {tcp_acceptor, start_link, [Port]},
      permanent,
      ?SHUTDOWN_WAITING_TIME,
      worker,
      [tcp_acceptor]
    },
    {
      tcp_client_sup,
      {tcp_client_sup, start_link, [Module]},
      permanent,
      infinity,
      supervisor,
      []
    }
  ]}}.

  
%% Tests

truth_test_() ->
	[
	?_assertMatch(1, 1)
	].
  