requires "domains.md"

module MINI-PYTHON-FORM-CALLBACK-SYNTAX
  imports BOOL-SYNTAX

  syntax Callback ::= "cbNone"
                    | "cbMeta"
                    | "cbBase"
                    | "cbFactory"
                    | "cbTop"
                    | "cbBad"
                    | "cbFalsey"

  syntax AttrState ::= "absent"
                     | "present" "(" Callback ")"

  syntax Exp ::= "resolve" "(" AttrState "," Callback ")"
               | "factoryClassAttrs" "(" Callback "," Callback ")"
               | "childWithInheritedMeta" "(" Callback ")"
               | "childWithReplacedMeta" "(" Callback ")"

  syntax KResult ::= Callback
endmodule

module MINI-PYTHON-FORM-CALLBACK
  imports MINI-PYTHON-FORM-CALLBACK-SYNTAX
  imports BOOL

  configuration <k> $PGM:Exp </k>

  // ModelFormMetaclass: an explicit top-level class attribute wins.
  rule <k> resolve(present(CB), _META) => CB ... </k>

  // Otherwise, ModelFormMetaclass uses the callback from the resolved Meta.
  rule <k> resolve(absent, META) => META ... </k>

  // modelform_factory: default None is omission, not an explicit override.
  rule <k> factoryClassAttrs(cbNone, META) => resolve(absent, META) ... </k>

  // modelform_factory: any non-None argument is explicit. The generated Meta
  // and the top-level class attribute both carry that callback.
  rule <k> factoryClassAttrs(CB, _META) => resolve(present(CB), CB) ... </k>
    requires CB =/=K cbNone

  // Normal Python name resolution: no replacement Meta means parent Meta.
  rule <k> childWithInheritedMeta(BASE) => resolve(absent, BASE) ... </k>

  // Replacement Meta with no callback has no callback. The base callback is
  // intentionally not a separate fallback.
  rule <k> childWithReplacedMeta(_BASE) => resolve(absent, cbNone) ... </k>
endmodule
