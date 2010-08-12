%%%
%%% @doc Integration tests and demo code generation.
%%% @author David Dossot <david@dossot.net>
%%%
%%% See LICENSE for license information.
%%% Copyright (c) 2010 David Dossot
%%%

-module(cferl_integration_tests).
-author('David Dossot <david@dossot.net>').
-include("cferl.hrl").

-export([start/0]).
-define(PRINT_CODE(Code), io:format("    ~s~n", [Code])).
-define(PRTFM_CODE(Format, Data), ?PRINT_CODE(io_lib:format(Format, Data))).
-define(PRINT_CALL(Call),
          io:format("    ~s.~n", [re:replace(??Call, " ", "", [global])]),
          Call).

start() ->
  application:start(ssl),
  application:start(ibrowse),

  {ok, [Username]} = io:fread("Username : ", "~s"),
  {ok, [ApiKey]} = io:fread("API Key : ", "~s"),
  io:format("~n"),
  run_tests(Username, ApiKey),
  init:stop().
  
%% Tests
run_tests(Username, ApiKey) ->
  CloudFiles = connect_test(Username, ApiKey),
  print_account_info(CloudFiles),
  container_tests(CloudFiles),
  ok.
  
connect_test(Username, ApiKey) ->
  {error, unauthorized} = cferl:connect("_fake_user_name", "_fake_api_key"),
  ?PRINT_CODE("# Connect to Cloud Files (warning: the underlying authentication toke will only last for 24 hours!)"),
  ?PRINT_CALL({ok, CloudFiles} = cferl:connect(Username, ApiKey)),
  ?PRINT_CODE(""),
  CloudFiles.

print_account_info(CloudFiles) ->
  ?PRINT_CODE("# Retrieve the account information record"),
  ?PRINT_CALL({ok, Info} = CloudFiles:get_account_info()),
  ?PRTFM_CODE("Info = #cf_account_info{bytes_used=~B, container_count=~B}",
              [Info#cf_account_info.bytes_used, Info#cf_account_info.container_count]),
  ?PRINT_CODE("").
              
container_tests(CloudFiles) ->
  ?PRINT_CODE("# Retrieve names of all existing containers (within the limits imposed by Cloud Files server)"),
  ?PRINT_CALL({ok, Names} = CloudFiles:get_containers_names()),
  ?PRTFM_CODE("Names=~p~n", [Names]),
  
  ?PRINT_CODE("# Retrieve names of a maximum of 3 existing containers"),
  ?PRINT_CALL({ok, ThreeNames} = CloudFiles:get_containers_names(#cf_query_args{limit=3})),
  ?PRTFM_CODE("ThreeNames=~p~n", [ThreeNames]),
  
  % retrieve 0 container
  {ok, []} = CloudFiles:get_containers_details(#cf_query_args{limit=0}),
  
  ?PRINT_CODE("# Retrieve information for all existing containers (within the server limits)"),
  ?PRINT_CALL({ok, ContainersInfo} = CloudFiles:get_containers_details()),
  ?PRINT_CODE("# ContainersInfo is a list of #cf_container_info records"),
  ?PRINT_CALL([Info|_]=ContainersInfo),
  ?PRTFM_CODE("Info = #cf_container_info{name=~p, bytes=~B, count=~B}",
              [Info#cf_container_info.name,
               Info#cf_container_info.bytes,
               Info#cf_container_info.count]),
  ?PRINT_CODE(""),
  
  ?PRINT_CODE("# Retrieve information for a maximum of 5 containers whose names start at cf"),
  ?PRINT_CALL({ok, CfContainersInfo} = CloudFiles:get_containers_details(#cf_query_args{marker= <<"cf">>, limit=5})),
  ?PRINT_CODE(""),

  ?PRINT_CODE("# Check a container's existence"),
  ?PRINT_CALL(false = CloudFiles:container_exists(<<"new_container">>)),
  ?PRINT_CODE(""),

  ?PRINT_CODE("# Create a new container"),
  ?PRINT_CALL({ok, Container} = CloudFiles:create_container(<<"new_container">>)),
  ?PRINT_CODE(""),
  ?PRINT_CALL(true = CloudFiles:container_exists(<<"new_container">>)),
  ?PRINT_CODE(""),
  
  % TODO show Container:name() count() bytes()
  
  ?PRINT_CODE("# Delete an existing container"),
  ?PRINT_CALL(ok = Container:delete()),
  ?PRINT_CODE(""),
  ok.
