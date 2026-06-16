// Constructed K claims for the FVK audit.
// This file was not parsed, compiled, or proved.

requires "mini-python-hash.k"

module MODEL-CHOICE-ITERATOR-VALUE-SPEC
  imports MINI-PYTHON-HASH

  // SPEC-PROVENANCE:
  // - E1/E4: public issue and hint require hashability by hash(self.value).
  claim
    <k> hash(MCIV(V:Value, O:Value)) => pyHash(V) </k>
    requires hasHash(V)
    [all-path]

  // SPEC-PROVENANCE:
  // - E3: list membership already works through value-based equality.
  claim
    <k> eq(MCIV(V:Value, O:Value), X:Value) => pyEq(V, X) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E3: wrapper-to-wrapper equality unwraps both values.
  claim
    <k> eq(MCIV(V1:Value, O1:Value), MCIV(V2:Value, O2:Value)) => pyEq(V1, V2) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E2: dict membership with key equal to the wrapped value must succeed.
  claim
    <k> contains((K:Value |-> P:Value), MCIV(V:Value, O:Value)) => true </k>
    requires hasHash(K)
     andBool hasHash(V)
     andBool pyHash(K) ==Int pyHash(V)
     andBool pyEq(K, MCIV(V, O))
    [all-path]

  // SPEC-PROVENANCE:
  // - E2: dict getitem after membership must return the payload for the equal key.
  claim
    <k> get((K:Value |-> P:Value), MCIV(V:Value, O:Value)) => P </k>
    requires hasHash(K)
     andBool hasHash(V)
     andBool pyHash(K) ==Int pyHash(V)
     andBool pyEq(K, MCIV(V, O))
    [all-path]
endmodule
