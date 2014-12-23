%%%-------------------------------------------------------------------
%%% @author karama
%%% @copyright (C) 2014, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 22. дек 2014 19:08
%%%-------------------------------------------------------------------
-module(bully).
-author("karama").

-export([start/1]).

-define(WAIT_FOR_RESPONSE, 100).
-define(REGISTRED_NAME, node).

% MESSAGES
-define(ELECTION_REQUEST, election_request).
-define(ELECTION_RESPONSE, election_ok).
-define(COORDINATOR_NOTIFY, coordinator).

-record(node, {connected = [], coordinator = node(), timeout = infinity}).

start(Nodes) ->
  register(?REGISTRED_NAME, self()),
  log_info("Connected"),
  Initiator = start_voting(#node{connected = Nodes}),
  wait_message(Initiator).

wait_message(Node) ->
  Coordinator = Node#node.coordinator,
  Timeout = Node#node.timeout,
  ResNode = receive
    {?ELECTION_RESPONSE, _} -> %wait for coordinator
        Node#node{timeout = infinity};
    {?ELECTION_REQUEST, From} when From < node() -> %send response => start voting
        send_election_response(From), start_voting(Node);
    {?COORDINATOR_NOTIFY, From} -> % set coordinator
        set_coordinator(Node, From);
    {nodedown, Coordinator} -> % start voting
        start_voting(Node)
    after Timeout ->
        win_voting(Node)
    end,
    wait_message(ResNode).


send(Node, Message) ->
  {?REGISTRED_NAME, Node} ! {Message, node()}.

send_election_request(Node) ->
  send(Node, ?ELECTION_REQUEST).

send_election_response(Node) ->
  send(Node, ?ELECTION_RESPONSE).

send_coordinator_notify_message(Node) ->
  send(Node, ?COORDINATOR_NOTIFY).

start_voting(Initiator) ->
  log_info("Start voting"),
  lists:foreach(fun send_election_request/1, lists:filter(fun(X) -> X > node() end, Initiator#node.connected)),
  Initiator#node{timeout = ?WAIT_FOR_RESPONSE}.

set_coordinator(Node, Coordinator) ->
  log_info("Set coordinator"),
  monitor_node(Node#node.coordinator, false),
  monitor_node(Coordinator, true),
  Node#node{coordinator = Coordinator, timeout = infinity}.

win_voting(Node) ->
  log_info("Win voting"),
  lists:foreach(fun send_coordinator_notify_message/1, Node#node.connected),
  Node#node{coordinator = node(), timeout = infinity}.

log_info(Info) ->
  io:format("Node ~s PID ~s : ~s ~n", [atom_to_list(node()), os:getpid(), [Info]]).

