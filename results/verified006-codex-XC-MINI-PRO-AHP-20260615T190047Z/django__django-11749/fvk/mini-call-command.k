module MINI-CALL-COMMAND-SYNTAX
  imports BOOL
  imports INT
  imports STRING
  imports LIST
  imports SET

  syntax Action ::= action(dest: String, opt: String, required: Bool, arity: Int)
  syntax Actions ::= ".Actions" | Action Actions
  syntax Group ::= requiredGroup(Set)
  syntax Groups ::= ".Groups" | Group Groups
  syntax OptionMap ::= Set

  syntax Token ::= token(String)
  syntax Tokens ::= List

  syntax Result ::= parsed(Tokens) | parserError(String)
  syntax KItem ::= callCommand(Actions, Groups, OptionMap, Tokens)
                 | synthRequired(Actions, Groups, OptionMap, Tokens)
                 | parse(Tokens, Groups, OptionMap)
endmodule

module MINI-CALL-COMMAND
  imports MINI-CALL-COMMAND-SYNTAX

  configuration <k> $PGM:K </k>

  // Abstract semantics for the audited slice:
  // call_command() builds synthetic parse tokens for required actions and
  // required mutually exclusive groups, then delegates validation to argparse.
  rule <k> callCommand(AS, GS, OPTS, ARGS)
        => synthRequired(AS, GS, OPTS, ARGS) ... </k>

  // Required plain actions supplied by kwargs are appended to parse tokens.
  rule <k> synthRequired(action(DEST, OPT, true, _ARITY) AS, GS, OPTS, ARGS)
        => synthRequired(AS, GS, OPTS, ARGS ListItem(token(OPT +String "=VALUE"))) ... </k>
       requires DEST in OPTS

  rule <k> synthRequired(action(DEST, _OPT, true, _ARITY) AS, GS, OPTS, ARGS)
        => synthRequired(AS, GS, OPTS, ARGS) ... </k>
       requires notBool DEST in OPTS

  // Required mutually exclusive group actions are not individually required,
  // but supplied group kwargs must still be appended with their option string.
  rule <k> synthRequired(action(DEST, OPT, false, _ARITY) AS, GS, OPTS, ARGS)
        => synthRequired(AS, GS, OPTS, ARGS ListItem(token(OPT +String "=VALUE"))) ... </k>
       requires DEST in OPTS andBool inRequiredGroup(DEST, GS)

  rule <k> synthRequired(action(DEST, _OPT, false, _ARITY) AS, GS, OPTS, ARGS)
        => synthRequired(AS, GS, OPTS, ARGS) ... </k>
       requires notBool (DEST in OPTS andBool inRequiredGroup(DEST, GS))

  rule <k> synthRequired(.Actions, GS, OPTS, ARGS)
        => parse(ARGS, GS, OPTS) ... </k>

  syntax Bool ::= inRequiredGroup(String, Groups) [function]
  rule inRequiredGroup(DEST, requiredGroup(DESTS) GS)
        => true
       requires DEST in DESTS
  rule inRequiredGroup(DEST, requiredGroup(DESTS) GS)
        => inRequiredGroup(DEST, GS)
       requires notBool DEST in DESTS
  rule inRequiredGroup(_DEST, .Groups) => false

  // Parser result is abstract: argparse is the trusted delegated validator for
  // required-group presence and mutual-exclusion conflicts once it sees tokens.
  rule <k> parse(ARGS, _GS, _OPTS) => parsed(ARGS) ... </k>
endmodule
