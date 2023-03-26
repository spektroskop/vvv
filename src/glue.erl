-module(glue).

-export([
  now/0
]).

now() ->
  calendar:system_time_to_local_time(erlang:system_time(), native).

