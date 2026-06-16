requires "domains.md"

module MINI-PYTHON-BLUEPRINT-SYNTAX
  imports STRING-SYNTAX
  imports BOOL-SYNTAX
  imports MAP-SYNTAX

  syntax NameOpt ::= noName | withName(String)

  syntax KItem ::= initBlueprint(String)
                 | registerBlueprint(String, NameOpt, String, Bool)
                 | valueErrorRaised
                 | okInit(String)
                 | okRegister(String)

  syntax String ::= resolvedName(NameOpt, String) [function]
                  | effectiveBlueprintName(String, String) [function]
  syntax Bool ::= hasDot(String) [function]
endmodule

module MINI-PYTHON-BLUEPRINT
  imports MINI-PYTHON-BLUEPRINT-SYNTAX
  imports STRING
  imports BOOL
  imports MAP

  configuration
    <k> $PGM:K </k>
    <bpName> "" </bpName>
    <appBlueprints> .Map </appBlueprints>
    <gotRegistered> false </gotRegistered>

  rule resolvedName(noName, SELF) => SELF
  rule resolvedName(withName(NAME), _) => NAME

  // Abstraction of f"{name_prefix}.{self_name}".lstrip(".").
  // The empty-name property is enforced before this function is used.
  rule effectiveBlueprintName("", NAME) => NAME
    requires NAME =/=String ""

  // Blueprint.__init__: V1 empty-name guard.
  rule <k> initBlueprint(NAME) => valueErrorRaised ... </k>
    requires NAME ==String ""

  // Existing dotted-name guard, framed by the V1 change.
  rule <k> initBlueprint(NAME) => valueErrorRaised ... </k>
    requires NAME =/=String "" andBool hasDot(NAME)

  // Normal constructor path for valid names.
  rule <k> initBlueprint(NAME) => okInit(NAME) ... </k>
       <bpName> _ => NAME </bpName>
    requires NAME =/=String "" andBool notBool hasDot(NAME)

  // Blueprint.register: V1 effective-name guard before app mutation.
  rule <k> registerBlueprint(SELF, OPT, _PREFIX, _CONFLICT) => valueErrorRaised ... </k>
    requires resolvedName(OPT, SELF) ==String ""

  // Duplicate conflict branch, unchanged and outside the empty-name fix.
  rule <k> registerBlueprint(SELF, OPT, _PREFIX, true) => valueErrorRaised ... </k>
    requires resolvedName(OPT, SELF) =/=String ""

  // Normal no-conflict registration path for a non-empty effective name.
  rule <k> registerBlueprint(SELF, OPT, PREFIX, false)
        => okRegister(effectiveBlueprintName(PREFIX, resolvedName(OPT, SELF))) ... </k>
       <appBlueprints> M
        => M [ effectiveBlueprintName(PREFIX, resolvedName(OPT, SELF)) <- SELF ]
       </appBlueprints>
       <gotRegistered> false => true </gotRegistered>
    requires resolvedName(OPT, SELF) =/=String ""
endmodule
