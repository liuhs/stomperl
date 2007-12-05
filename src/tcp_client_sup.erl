-module(tcp_client_sup).
-behaviour(supervisor).

-include_lib("eunit/include/eunit.hrl").

-include("tcp_server.hrl").

% External API
-export([start_link/1, start_child/1]). 

% Callbacks
-export([init/1]). 

% External API
start_link(Module) ->
  supervisor:start_link({local, ?MODULE}, ?MODULE, [Module]).

start_child(Socket) ->
  supervisor:start_child(?MODULE, [Socket]).

% Callbacks
init([Module]) ->
  {ok, {{simple_one_for_one, ?MAX_RESTART, ?MAX_TIME}, [{
    undefined,
    {Module, start_link, []},
    temporary,
    ?SHUTDOWN_WAITING_TIME,
    worker,
    []
  }]}}.

  
%% Tests

truth_test_() ->
	[
	?_assertMatch(1, 1)
	].
  