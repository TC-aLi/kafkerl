-module(kafkerl_sup).
-author('hernanrivasacosta@gmail.com').

-behaviour(supervisor).

-export([start_link/0, init/1]).

-define(SERVER, ?MODULE).

-type restart_strategy() :: {supervisor:strategy(),
                             non_neg_integer(),
                             non_neg_integer()}.

%%==============================================================================
%% API
%%==============================================================================
-spec start_link() -> {ok, pid()}.
start_link() ->
  supervisor:start_link({local, ?SERVER}, ?MODULE, []).

%%==============================================================================
%% Utils
%%==============================================================================
-spec init([]) -> {ok, {restart_strategy(), [supervisor:child_spec()]}}.
init([]) ->
  ChildSpecs = case application:get_env(kafkerl, disabled, false) of
                 true ->
                   lager:notice("Kafkerl is disabled, ignoring"),
                   [];
                 false ->
                   [get_connector_child_spec()]
               end,
  {ok, {{one_for_one, 5, 10}, ChildSpecs}}.

get_connector_child_spec() ->
  {ok, ConnConfig} = application:get_env(kafkerl, conn_config),
  Topics = application:get_env(kafkerl, topics, []),
  Params = [[{topics, Topics} | ConnConfig]],
  MFA = {kafkerl_connector, start_link, Params},
  {kafkerl, MFA, permanent, 2000, worker, [kafkerl_connector]}.