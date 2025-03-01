Definitions.

%whitespace
WS = [\000-\s]

% separators
S = ->|\+\+|when|\(|\)|\[|\]|{|}|;|:|#|,|:=|=>|=|#{|/|\|

% types
T = atom|integer|list|number|pid|port|reference|tuple|map|binary|function

% comparison operators, binary
C = >|>=|<|=<|=:=|==|=/=|/=

% arithmetic operators, binary
A = \+|-|\*|div|rem|band|bor|bxor|bnot|bsl|bsr

% boolean operators, unary/binary
B1 = not
B2 = and|or|andalso|orelse|xor

% BIFs, split by arity
F0 = self
F1 = abs|hd|length|node|round|size|tl|trunc
F2 = element

VAR = [A-Z_][A-Za-z0-9_]*
STR = "([^"]|\\")*"
INTC = \$[\s-~]
INTI = -?[0-9]+
INTR = {INTI}#[0-9a-zA-Z]+
INT  = ({INTI}|{INTR}|{INTC})

ATOM = [a-z][A-Z0-9a-z_]*
ATOMQ = '([^'|\\'])*'

BINTS = {ATOM}(:({INTI}|{INTR}))?
BINC = ({STR}|{INT})(:{INT})?(/{BINTS}(-{BINTS})*)?
BIN  = <<{WS}*(({BINC}({WS}*,{WS}*{BINC})*){WS}*)?>>

PID = <[0-9]+\.[0-9]+\.[0-9]+>
REF = #Ref<[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+>
PORT = #Port<[0-9]+\.[0-9]+>

Rules.

{WS}+ :
  skip_token.

{PID} :
  {token, {'pid', TokenLine, list_to_pid(TokenChars)}}.

{REF} :
  {token, {'ref', TokenLine, list_to_ref(TokenChars)}}.

{PORT} :
  {token, {'port', TokenLine, list_to_port(TokenChars)}}.

({S}) :
  {token, {to_atom(TokenChars), TokenLine}}.

is_({T}) :
  {token, {'type_test1', TokenLine, to_atom(TokenChars)}}.

is_record :
  {token, {'type_isrec', TokenLine, to_atom(TokenChars)}}.

({F0}) :
  {token, {'bif0', TokenLine, to_atom(TokenChars)}}.

({F1}) :
  {token, {'bif1', TokenLine, to_atom(TokenChars)}}.

({F2}) :
  {token, {'bif2', TokenLine, to_atom(TokenChars)}}.

({C}) :
  {token, {'comparison_op', TokenLine, to_atom(TokenChars)}}.

({A}) :
  {token, {'arithmetic_op', TokenLine, to_atom(TokenChars)}}.

({B1}) :
  {token, {'boolean_op1', TokenLine, to_atom(TokenChars)}}.

({B2}) :
  {token, {'boolean_op2', TokenLine, to_atom(TokenChars)}}.

{INTC} :
  {token, {'int', TokenLine, char_to_int(TokenChars)}}.

{INTR} :
  {token, {'int', TokenLine, radix_to_int(TokenChars)}}.

{INTI} :
  {token, {'int', TokenLine, int_to_int(TokenChars)}}.

{VAR} :
  {token, {'variable', TokenLine, TokenChars}}.

{STR} :
  {token, {'string', TokenLine, trim(TokenChars)}}.

{ATOM} :
  {token, {'atom', TokenLine, to_atom(TokenChars)}}.

{ATOMQ} :
  {token, {'atom', TokenLine, to_atom(trim(TokenChars))}}.

{BIN} :
  {token, {'bin', TokenLine, to_binary(TokenChars)}}.

Erlang code.

%% @hidden

to_atom(Str) ->
    list_to_atom(Str).

char_to_int([$$, C]) ->
    C.

radix_to_int(Str) ->
    case erl_scan:tokens([], Str++". ", 0) of
        {done, {ok, [{integer, _, Int}, {dot, _}], 0}, []} -> Int;
        _ -> throw({error, {0, ?MODULE, "malformed_int: "++Str}, 0})
    end.

int_to_int(Str) ->
    list_to_integer(Str).

to_binary(Str) ->
    try
        {done, {ok, Toks, _}, []} = erl_scan:tokens([], Str++". ", 0),
        {ok, Exprs} = erl_parse:parse_exprs(Toks),
        {value, Val, _} = erl_eval:exprs(Exprs, erl_eval:new_bindings()),
        Val
    catch
        _:_ -> throw({error, {0, ?MODULE, "malformed_binary: "++Str}, 0})
    end.

trim(Str) ->
    lists:reverse(tl(lists:reverse(tl(Str)))).
