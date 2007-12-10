-module(tcp_server_sup).
-behaviour(supervisor).

-include_lib("eunit/include/eunit.hrl").

-include("tcp_server.hrl").

% External API
-export([start/0, start_link/3, stop/0]). 

% Callbacks
-export([init/1]). 

% External API

%% ATTENTION
%% start server with this method
%% there's init logic
start() ->	
	Table = ets:new(storage, [set, public, {keypos, 1}]),
	start_link(61613, tcp_stomp, Table),
	receive _ -> ok end.	

start_link(Port, Module, Table) when is_integer(Port) ->
  supervisor:start_link({local, ?MODULE}, ?MODULE, [Port, Module, Table]).

stop() ->
  case whereis(?MODULE) of
    Pid when pid(Pid) ->
      exit(Pid, shutdown),
      ok;
    _ -> not_started
  end.

% Callbacks
init([Port, Module, Table]) ->
  {ok, {{one_for_one, ?MAX_RESTART, ?MAX_TIME}, [
    {
      tcp_acceptor,
      {tcp_acceptor, start_link, [Port, Table]},
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
  