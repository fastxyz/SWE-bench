module MINI-SPHINX-XREF-SYNTAX
  imports BOOL-SYNTAX

  syntax Mod ::= "NoMod" | "Mod" | "ModSubmod"
  syntax Cls ::= "NoCls" | "SomeCls"
  syntax RawTarget ::= "RawA" | "RawDotA" | "RawTildeModA" | "RawModA" | "RawModSubmodA"
  syntax Target ::= "A" | "ModA" | "ModSubmodA"
  syntax FullName ::= "ObjModA" | "ObjModSubmodA"
  syntax Result ::= "resolved" "(" FullName ")"
                  | "noMatch"
                  | "ambiguous" "(" FullName "," FullName ")"
  syntax RefNode ::= "ref" "(" Mod "," Cls "," Target "," Bool "," Target ")"

  syntax Exp ::= RefNode
               | Result
               | "processFieldXref" "(" Mod "," Cls "," RefNode ")"
               | "makeFieldXref" "(" Mod "," Cls "," RawTarget ")"
               | "resolveIssue" "(" RefNode ")"
               | "resolveFieldRaw" "(" Mod "," Cls "," RawTarget ")"

  syntax KResult ::= RefNode | Result
endmodule

module MINI-SPHINX-XREF
  imports MINI-SPHINX-XREF-SYNTAX
  imports BOOL

  configuration <k> $PGM:Exp </k>

  // PythonDomain.process_field_xref copies current Python scope to the node.
  rule <k> processFieldXref(M:Mod, C:Cls, ref(_:Mod, _:Cls, T:Target, R:Bool, D:Target))
        => ref(M, C, T, R, D) ... </k>

  // PyXrefMixin.make_xref for the relevant target families.
  rule <k> makeFieldXref(M:Mod, C:Cls, RawA)
        => ref(M, C, A, false, A) ... </k>
  rule <k> makeFieldXref(M:Mod, C:Cls, RawDotA)
        => ref(M, C, A, true, A) ... </k>
  rule <k> makeFieldXref(M:Mod, C:Cls, RawTildeModA)
        => ref(M, C, ModA, false, A) ... </k>
  rule <k> makeFieldXref(M:Mod, C:Cls, RawModA)
        => ref(M, C, ModA, false, ModA) ... </k>
  rule <k> makeFieldXref(M:Mod, C:Cls, RawModSubmodA)
        => ref(M, C, ModSubmodA, false, ModSubmodA) ... </k>

  // Issue database: exactly the two class objects from the reproduction,
  // mod.A and mod.submod.A. This abstracts only the search-mode-sensitive
  // result that the bug report observes.
  rule <k> resolveIssue(ref(Mod, NoCls, A, false, _:Target))
        => resolved(ObjModA) ... </k>
  rule <k> resolveIssue(ref(ModSubmod, NoCls, A, false, _:Target))
        => resolved(ObjModSubmodA) ... </k>
  rule <k> resolveIssue(ref(NoMod, NoCls, A, false, _:Target))
        => noMatch ... </k>
  rule <k> resolveIssue(ref(NoMod, NoCls, A, true, _:Target))
        => ambiguous(ObjModA, ObjModSubmodA) ... </k>
  rule <k> resolveIssue(ref(Mod, NoCls, A, true, _:Target))
        => resolved(ObjModA) ... </k>
  rule <k> resolveIssue(ref(ModSubmod, NoCls, A, true, _:Target))
        => resolved(ObjModSubmodA) ... </k>
  rule <k> resolveIssue(ref(_:Mod, _:Cls, ModA, _:Bool, _:Target))
        => resolved(ObjModA) ... </k>
  rule <k> resolveIssue(ref(_:Mod, _:Cls, ModSubmodA, _:Bool, _:Target))
        => resolved(ObjModSubmodA) ... </k>

  // Composition used by the spec claims.
  rule <k> resolveFieldRaw(M:Mod, C:Cls, RawA)
        => resolveIssue(ref(M, C, A, false, A)) ... </k>
  rule <k> resolveFieldRaw(M:Mod, C:Cls, RawDotA)
        => resolveIssue(ref(M, C, A, true, A)) ... </k>
  rule <k> resolveFieldRaw(M:Mod, C:Cls, RawTildeModA)
        => resolveIssue(ref(M, C, ModA, false, A)) ... </k>
  rule <k> resolveFieldRaw(M:Mod, C:Cls, RawModA)
        => resolveIssue(ref(M, C, ModA, false, ModA)) ... </k>
  rule <k> resolveFieldRaw(M:Mod, C:Cls, RawModSubmodA)
        => resolveIssue(ref(M, C, ModSubmodA, false, ModSubmodA)) ... </k>
endmodule
