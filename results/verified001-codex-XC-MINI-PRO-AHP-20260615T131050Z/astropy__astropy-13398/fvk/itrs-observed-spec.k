requires "mini-coordinate-transforms.k"

module ITRS-OBSERVED-SPEC
  imports MINI-COORDINATE-TRANSFORMS

  // SPEC-PROVENANCE:
  // - E1/E2/E3: explicitly topocentric ITRS to AltAz is a local ITRS rotation.
  claim
    <k> itrsToObserved(itrs(L:Loc, T:Time),
                       observed(altaz, L, TO:Time, noRefrac),
                       V:Vec)
        => coord(observed(altaz, L, TO, noRefrac), rotate(altaz, L, V)) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E1/E2/E3: explicitly topocentric ITRS to HADec is a local ITRS rotation.
  claim
    <k> itrsToObserved(itrs(L:Loc, T:Time),
                       observed(hadec, L, TO:Time, noRefrac),
                       V:Vec)
        => coord(observed(hadec, L, TO, noRefrac), rotate(hadec, L, V)) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E4/E6: geocentric or otherwise mismatched ITRS origins must delegate
  //   to existing ITRS self-transform semantics before local observed rotation.
  claim
    <k> itrsToObserved(itrs(L1:Loc, T:Time),
                       observed(K:ObsKind, L2:Loc, TO:Time, noRefrac),
                       V:Vec)
        => coord(observed(K, L2, TO, noRefrac),
                 rotate(K, L2, selfITRS(L1, L2, T, chooseTime(TO, T), V))) </k>
    requires L1 =/=K L2 andBool L2 =/=K noLoc
    [all-path]

  // SPEC-PROVENANCE:
  // - E1/E3: inverse no-refraction observed transform creates topocentric ITRS
  //   at the observed location and requested output obstime.
  claim
    <k> observedToITRS(observed(K:ObsKind, L:Loc, TO:Time, noRefrac),
                       itrs(L, TOut:Time),
                       V:Vec)
        => coord(itrs(L, TOut), invRotate(K, L, V)) </k>
    requires L =/=K noLoc
    [all-path]

  // SPEC-PROVENANCE:
  // - E4/E6: inverse transform to a different ITRS location delegates origin
  //   movement to the existing ITRS self-transform.
  claim
    <k> observedToITRS(observed(K:ObsKind, L1:Loc, TO:Time, noRefrac),
                       itrs(L2:Loc, TOut:Time),
                       V:Vec)
        => coord(itrs(L2, TOut),
                 selfITRS(L1, L2, TOut, TOut, invRotate(K, L1, V))) </k>
    requires L1 =/=K L2 andBool L1 =/=K noLoc
    [all-path]

  // SPEC-PROVENANCE:
  // - E5: refraction requested without obstime is outside the transform domain
  //   and must fail clearly instead of silently ignoring pressure.
  claim
    <k> itrsToObserved(itrs(L:Loc, T:Time),
                       observed(K:ObsKind, L, none, refrac),
                       V:Vec)
        => errNoObstime </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E5: refraction uses CIRS/observed machinery rather than the no-pressure
  //   local rotation.
  claim
    <k> itrsToObserved(itrs(L:Loc, T:Time),
                       observed(K:ObsKind, L, TO:Time, refrac),
                       V:Vec)
        => coord(observed(K, L, TO, refrac), refract(K, L, TO, toCIRS(TO, V))) </k>
    requires TO =/=K none
    [all-path]

  // SPEC-PROVENANCE:
  // - E7: ITRS->CIRS/TETE intermediate conversion preserves ITRS location.
  claim
    <k> itrsToIntermediate(itrs(L:Loc, T:Time), cirs(L2:Loc, T2:Time), V:Vec)
        => coord(cirs(L, T), toCIRS(T, V)) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E7: CIRS/TETE->ITRS targets the requested ITRS location.
  claim
    <k> intermediateToITRS(cirs(L1:Loc, T1:Time), itrs(L2:Loc, T2:Time), V:Vec)
        => coord(itrs(L2, T2), fromCIRS(T2, V)) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E7: topocentric ITRS data projected as EarthLocation include frame location.
  claim
    <k> earthLocation(itrs(L:Loc, T:Time), V:Vec)
        => coord(itrs(center, none), addLocation(L, V)) </k>
    [all-path]
endmodule
