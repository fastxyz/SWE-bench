// FVK artifact for sympy__sympy-16597.
// Constructed, not machine-checked in this session.

requires "mini-assumptions.k"

module ASSUMPTIONS-SPEC
  imports MINI-ASSUMPTIONS

  // SPEC-PROVENANCE:
  // - from_prompt: "a.is_even does not imply a.is_finite" plus "I would
  //   expect that a number should be finite before it can be even."
  // - from_code: `even == integer & !odd`, `integer -> rational`, and V1
  //   `rational -> finite` in sympy/core/assumptions.py.
  claim <k> close(SetItem(even)) => done(?FS:Set) </k>
    ensures has(?FS, finite)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: evenness is a parity property over integers; odd is the
  //   sibling old-assumption parity fact with the same integer projection.
  // - from_code: `odd == integer & !even`, `integer -> rational`, and V1
  //   `rational -> finite` in sympy/core/assumptions.py.
  claim <k> close(SetItem(odd)) => done(?FS:Set) </k>
    ensures has(?FS, finite)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "Similarly: i = Symbol('i', integer=True);
  //   print(i.is_finite) None".
  // - from_code: `integer -> rational` and V1 `rational -> finite`.
  claim <k> close(SetItem(integer)) => done(?FS:Set) </k>
    ensures has(?FS, finite)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_hint: "Perhaps the second rule 'rational -> real' should
  //   be extended to 'rational -> real & finite'"; "safe to add finite to
  //   rational".
  // - from_code: V1 implements that as a separate alpha implication.
  claim <k> close(SetItem(rational)) => done(?FS:Set) </k>
    ensures has(?FS, finite)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_hint: "adding finite to real would probably break a lot of
  //   code"; old-assumptions `real` must not be globally narrowed here.
  claim <k> close(SetItem(real)) => done(?FS:Set) </k>
    ensures notBool has(?FS, finite)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_core_docs: unknown properties return None for a generic symbol.
  // - from_frame_condition: V1 must not make unconstrained symbols finite.
  claim <k> close(.Set) => done(?FS:Set) </k>
    ensures notBool has(?FS, finite)
    [all-path]
endmodule
