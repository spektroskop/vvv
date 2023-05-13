-module(glue).

-export([
    hackney_send/5,
    hackney_body/1
]).

hackney_send(Method, Url, Headers, Body, Options) ->
    case hackney:request(Method, Url, Headers, Body, Options) of
        {ok, Code, Head} ->
            {ok, {response, Code, Head, empty}};

        {ok, Code, Head, Data} when is_bitstring(Data) -> 
            {ok, {response, Code, Head, {body, Data}}};

        {ok, Code, Head, Ref} when is_reference(Ref) -> 
            {ok, {response, Code, Head, {reference, Ref}}};

        {ok, _, _, _} ->
            {error, bad_response};

        {error, {options, Error}} ->
            {error, {bad_option, Error}};

        {error, timeout} ->
            {error, timeout};

        {error, Error} -> 
            {error, {other, Error}}
    end.

hackney_body(Ref) ->
    case hackney:body(Ref) of
        {ok, Body} -> {ok, Body};
        {error, Error} -> {error, {other, Error}}
    end.
