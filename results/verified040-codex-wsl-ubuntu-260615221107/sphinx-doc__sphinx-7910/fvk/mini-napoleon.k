module MINI-NAPOLEON-SYNTAX
  imports BOOL-SYNTAX

  syntax What ::= "class" | "exception" | "module" | "function" | "method" | "attribute"
  syntax NameKind ::= "init" | "private" | "special" | "weakref" | "public"
  syntax Resolve ::= "resolved" "(" Bool "," Bool ")"
                   | "unresolvedTop"
                   | "unresolvedDotted"
  syntax Config ::= "cfg" "(" Bool "," Bool "," Bool ")"
  syntax Result ::= "forceInclude" | "default"

  syntax Bool ::= isMemberWhat(What) [function]
                | isClassLike(What) [function]
                | ownerFor(Resolve, Bool) [function]
                | includedByConfig(NameKind, Config) [function]
  syntax Result ::= skipMember(What, NameKind, Bool, Resolve, Bool, Config)
endmodule

module MINI-NAPOLEON
  imports MINI-NAPOLEON-SYNTAX
  imports BOOL

  configuration <k> $PGM:K </k>

  rule isMemberWhat(class) => true
  rule isMemberWhat(exception) => true
  rule isMemberWhat(module) => true
  rule isMemberWhat(function) => false
  rule isMemberWhat(method) => false
  rule isMemberWhat(attribute) => false

  rule isClassLike(class) => true
  rule isClassLike(exception) => true
  rule isClassLike(module) => false
  rule isClassLike(function) => false
  rule isClassLike(method) => false
  rule isClassLike(attribute) => false

  // resolved(OWNER, WRAPPED_OWNER) represents resolving obj.__module__ plus
  // obj.__qualname__.  WRAPPED_OWNER models unwrap(cls) for decorated classes.
  rule ownerFor(resolved(OWNER:Bool, WRAPPED_OWNER:Bool), _:Bool)
    => OWNER orBool WRAPPED_OWNER

  // unresolvedTop is the compatibility fallback to obj.__globals__[cls_path].
  // unresolvedDotted preserves the old nested-class failure mode when module
  // resolution cannot walk the dotted qualname path.
  rule ownerFor(unresolvedTop, GLOBAL_OWNER:Bool) => GLOBAL_OWNER
  rule ownerFor(unresolvedDotted, _:Bool) => false

  rule includedByConfig(init, cfg(INIT:Bool, _:Bool, _:Bool)) => INIT
  rule includedByConfig(private, cfg(_:Bool, PRIVATE:Bool, _:Bool)) => PRIVATE
  rule includedByConfig(special, cfg(_:Bool, _:Bool, SPECIAL:Bool)) => SPECIAL
  rule includedByConfig(weakref, _:Config) => false
  rule includedByConfig(public, _:Config) => false

  rule skipMember(WHAT:What, NAME:NameKind, true, RESOLVE:Resolve,
                  GLOBAL_OWNER:Bool, CONFIG:Config)
    => forceInclude
    requires NAME =/=K weakref
     andBool isMemberWhat(WHAT)
     andBool includedByConfig(NAME, CONFIG)
     andBool (WHAT ==K module
              orBool (isClassLike(WHAT) andBool ownerFor(RESOLVE, GLOBAL_OWNER)))

  rule skipMember(_:What, _:NameKind, _:Bool, _:Resolve, _:Bool, _:Config)
    => default
    [owise]
endmodule
