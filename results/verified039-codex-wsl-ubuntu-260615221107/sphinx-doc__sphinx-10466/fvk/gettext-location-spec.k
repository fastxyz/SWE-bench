// Constructed, not machine-checked.
// Formal claims for V1 of sphinx-doc__sphinx-10466.

requires "mini-python-location-catalog.k"

module GETTEXT-LOCATION-SPEC
  imports MINI-PYTHON-LOCATION-CATALOG

  // SPEC-PROVENANCE:
  // - E1/E2/E3: duplicate rendered location lines are the reported bug.
  // - E4/E5/E6: exact raw de-duplication is not enough; normalize first.
  // - E7: the observable is the rendered source path plus line.
  //
  // Claim C1/C4: after normalization and stable uniqueness, rendered
  // locations contain no duplicate location tuple.
  claim
    <k> noDup(renderLocs(stableUnique(normalizeEntries(ES:List))))
      => true
    </k>

  // SPEC-PROVENANCE:
  // - E4/E5: Catalog.__iter__ must normalize each source before Message stores
  //   the location list.
  //
  // Claim C2: each metadata entry contributes exactly its cwd-normalized
  // location tuple.
  claim
    <k> normalizeEntries(ListItem(entry(P:Path, L:Int, U:Uuid)) REST:List)
      => ListItem(loc(normCwd(P), L)) normalizeEntries(REST)
    </k>

  // SPEC-PROVENANCE:
  // - E1/E2/E3: remove duplicate location tuples.
  // - E8: retain first occurrence order as a compatibility frame condition.
  //
  // Claim C1/C3: stableUnique drops a repeated head when it has already been
  // seen, otherwise it preserves that first occurrence.
  claim
    <k> uniqueSeen(ListItem(LOC:Loc) REST:List, SetItem(LOC) SEEN:Set)
      => uniqueSeen(REST, SetItem(LOC) SEEN)
    </k>

  claim
    <k> uniqueSeen(ListItem(LOC:Loc) REST:List, SEEN:Set)
      => ListItem(LOC) uniqueSeen(REST, SetItem(LOC) SEEN)
    </k>
    requires notBool (LOC in SEEN)

  // SPEC-PROVENANCE:
  // - E7: the template renders source with relpath(source, outdir).
  // - E5/E6: normalizing source relative to cwd before rendering must preserve
  //   the rendered output while exposing duplicate identities.
  //
  // Claim C5: rendering a normalized source is observationally equivalent to
  // rendering the original source.
  claim
    <k> renderOut(normCwd(P:Path)) => renderOut(P) </k>
endmodule
