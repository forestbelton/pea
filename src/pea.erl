-module(pea).

-export([succeed/1, alt/2, seq/1, string/1, parse/2, map/2]).

-record(parser, {run}).

%% API

succeed(X) ->
    #parser{ run =
                 fun(S) ->
                         {pass, S, X}
                 end
           }.

alt(#parser{run = A}, #parser{run = B}) ->
    #parser{ run =
                 fun(S) ->
                         case A(S) of
                             {pass, T, X} ->
                                 {pass, T, X};
                             _Any ->
                                 B(S)
                         end
                 end
           }.

map(F, #parser{run = P}) when is_function(F, 1) ->
    #parser{ run =
                 fun(S) ->
                         case P(S) of
                             {pass, T, X} ->
                                 {pass, T, F(X)};
                             Any ->
                                 Any
                         end
                 end
           }.

parse(#parser{run = P}, S) when is_list(S) ->
    P(S).

seq(Xs) when is_list(Xs) ->
    seq(succeed([]), Xs).

string(S) when is_list(S) ->
    #parser{ run =
                 fun(T) ->
                         if length(T) < length(S) ->
                                 Msg = io_lib:format("Found EOF when expecting ~s", [S]),
                                 {fail, T, lists:flatten(Msg)};
                            true ->
                                 {A, B} = lists:split(length(S), T),
                                 if A == S ->
                                         {pass, B, S};
                                    true ->
                                         Msg = io_lib:format("Expected ~s, got ~s", [S, A]),
                                         {fail, T, lists:flatten(Msg)}
                                 end
                         end
                 end
           }.

%% Internals

seq(P, []) ->
    P;

seq(P, [Q = #parser{run = _} | T]) ->
    seq(seq2(P, Q), T).

seq2(#parser{run = A}, #parser{run = B}) ->
    #parser{ run =
                 fun(S) ->
                         case A(S) of
                             {pass, T, X} ->
                                 case B(T) of
                                     {pass, U, Y} ->
                                         {pass, U, [X, Y]};
                                     Any ->
                                         Any
                                 end;
                             Any ->
                                 Any
                         end
                 end
           }.

%% End of Module.
