// Constructed FVK mini-semantics for pylint ignore-path filtering.
// This is a compact model of the patched control flow, not full Python.

module MINI-PYLINT-IGNORE-SYNTAX
  imports BOOL
  imports STRING

  syntax Names
  syntax Patterns

  syntax String ::= normPath(String) [function]
  syntax String ::= basename(String) [function]

  syntax Bool ::= nameIn(String, Names) [function]
  syntax Bool ::= regexMatch(String, Patterns) [function]

  syntax Bool ::= pathRegexMatch(String, Patterns) [function]
  syntax Bool ::= ignoredFile(String, Names, Patterns, Patterns) [function]
  syntax Bool ::= emitResolved(Bool, Bool) [function]
  syntax Bool ::= shouldTraverse(Bool, Bool, Bool) [function]
endmodule

module MINI-PYLINT-IGNORE
  imports MINI-PYLINT-IGNORE-SYNTAX

  // Candidate paths are retried after normalizing separators to Posix form.
  rule pathRegexMatch(P, PATHS)
    => regexMatch(P, PATHS) orBool regexMatch(normPath(P), PATHS)

  // Mirrors _is_ignored_file.
  rule ignoredFile(P, IGNORE, IGNORE_RE, IGNORE_PATHS)
    => nameIn(basename(P), IGNORE)
       orBool regexMatch(basename(P), IGNORE_RE)
       orBool pathRegexMatch(P, IGNORE_PATHS)

  // Mirrors the V2 expansion decision:
  // a resolved file is emitted only when it is not a namespace and not ignored.
  rule emitResolved(IS_NAMESPACE, IS_IGNORED)
    => notBool IS_NAMESPACE andBool notBool IS_IGNORED

  // Mirrors the package/submodule traversal condition.
  // An ignored resolved __init__.py suppresses that file only; it does not by
  // itself suppress traversal of submodules.
  rule shouldTraverse(HAS_INIT, IS_NAMESPACE, IS_DIRECTORY)
    => HAS_INIT orBool IS_NAMESPACE orBool IS_DIRECTORY
endmodule
