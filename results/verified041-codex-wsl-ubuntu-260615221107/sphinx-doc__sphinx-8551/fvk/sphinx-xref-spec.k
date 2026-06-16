requires "mini-sphinx-xref.k"

module SPHINX-XREF-SPEC
  imports MINI-SPHINX-XREF

  // SPEC-PROVENANCE:
  // - E2/E8: field xrefs must carry the same Python context as explicit roles.
  // CLAIM: FIELD-CONTEXT
  claim
    <k> processFieldXref(M:Mod, C:Cls, ref(NoMod, NoCls, A, false, A))
     => ref(M, C, A, false, A) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E2/E5/E9: ordinary unqualified type names must not request fuzzy lookup.
  // CLAIM: PLAIN-FIELD
  claim
    <k> makeFieldXref(M:Mod, C:Cls, RawA)
     => ref(M, C, A, false, A) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E6: leading dot keeps explicit-role refspecific behavior.
  // CLAIM: DOT-FIELD
  claim
    <k> makeFieldXref(M:Mod, C:Cls, RawDotA)
     => ref(M, C, A, true, A) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E6: tilde shortens display and strips target prefix, but does not set refspecific.
  // CLAIM: TILDE-FIELD
  claim
    <k> makeFieldXref(M:Mod, C:Cls, RawTildeModA)
     => ref(M, C, ModA, false, A) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E1/E2: currentmodule mod, unqualified A resolves to mod.A without ambiguity.
  // CLAIM: RESOLVE-MOD
  claim
    <k> resolveFieldRaw(Mod, NoCls, RawA)
     => resolved(ObjModA) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E1/E3/E4: currentmodule mod.submod, unqualified A resolves to mod.submod.A.
  // CLAIM: RESOLVE-SUBMOD
  claim
    <k> resolveFieldRaw(ModSubmod, NoCls, RawA)
     => resolved(ObjModSubmodA) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E5: plain A outside module scope must not silently suffix-link to mod.A.
  // CLAIM: RESOLVE-NONMODULE-PLAIN
  claim
    <k> resolveFieldRaw(NoMod, NoCls, RawA)
     => noMatch </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E6: leading-dot syntax still exposes suffix ambiguity outside module scope.
  // CLAIM: RESOLVE-NONMODULE-DOT
  claim
    <k> resolveFieldRaw(NoMod, NoCls, RawDotA)
     => ambiguous(ObjModA, ObjModSubmodA) </k>
    [all-path]
endmodule
