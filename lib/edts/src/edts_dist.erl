%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% @doc edts code to deal with distribution.
%%% @end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%_* Module declaration =======================================================
-module(edts_dist).

%%%_* Exports ==================================================================

%% API
-export([ connect/1
        , connect_all/0
        , init_node/1
        , make_sname/1]).

%%%_* Includes =================================================================

%%%_* Defines ==================================================================

%%%_* Types ====================================================================

%%%_* API ======================================================================

%%------------------------------------------------------------------------------
%% @doc
%% Pings Node registered with the local epmd, so that a connection is
%% established.
%% @end
-spec connect(Node::atom()) -> ok.
%%------------------------------------------------------------------------------
connect(Node) ->
  pong = net_adm:ping(Node),
  ok.

%%------------------------------------------------------------------------------
%% @doc
%% Calls connect/1 for all nodes registered with the local epmd.
%% @end
-spec connect_all() -> ok.
%%------------------------------------------------------------------------------
connect_all() ->
  {ok, Hostname} = inet:gethostname(),
  {ok, Nodes}    = net_adm:names(),
  lists:foreach(fun({Name, _Port}) ->
                    {ok, Nodename} = make_sname(Name, Hostname),
                    connect(Nodename)
                end,
                Nodes).


%%------------------------------------------------------------------------------
%% @doc
%% Initialize edts-related services etc. on remote node. Returns a list of keys
%% to promises that are to be fulfilled by the remote node. These keys can later
%% be used in calls to rpc:yield/1, rpc:nbyield/1 and rpc:nbyield/2.
%% @end
-spec init_node(string()) -> [rpc:key()].
%%------------------------------------------------------------------------------
init_node(Node) ->
  remote_load_modules(Node,   [edts_xref]),
  remote_start_services(Node, [edts_xref]).

%%------------------------------------------------------------------------------
%% @doc
%% Converts a string to a valid erlang sname for localhost.
%% @end
-spec make_sname(string()) -> atom().
%%------------------------------------------------------------------------------
make_sname(Name) ->
  {ok, Hostname} = inet:gethostname(),
  make_sname(Name, Hostname).

%%------------------------------------------------------------------------------
%% @doc
%% Converts a string to a valid erlang sname for Hostname.
%% @end
-spec make_sname(Name::string(), Hostname::string()) -> atom().
%%------------------------------------------------------------------------------
make_sname(Name, Hostname) ->
  try
    {ok, list_to_atom(Name ++ "@" ++ Hostname)}
  catch
    _C:Reason -> {error, Reason}
  end.


%%%_* Internal functions =======================================================

remote_load_modules(Node, Mods) ->
  lists:foreach(fun(Mod) -> remote_load_module(Node, Mod) end, Mods).

remote_load_module(Node, Mod0) ->
  {Mod, Bin, File} = code:get_object_code(Mod0),
  {module, Mod0}   = rpc:call(Node, code, load_binary, [Mod, File, Bin]).

remote_start_services(Node, Servs) ->
  lists:map(fun(Service) -> remote_start_service(Node, Service) end, Servs).

remote_start_service(Node, Service) ->
  rpc:async_call(Node, Service, start, []).

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End: