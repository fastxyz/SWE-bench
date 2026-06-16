requires "mini-django-autodetector.k"

module MINI-DJANGO-AUTODETECTOR-SPEC
  imports MINI-DJANGO-AUTODETECTOR
  imports MAP-SYMBOLIC
  imports K-EQUAL

  // SPEC-PROVENANCE:
  // - E-003/E-004: accepted model rename maps the new key to the old name and
  //   normalizes old_model_keys to the new key for later processing.
  claim [MODEL-RENAME-NORMALIZES-KEYS]:
    <k> modelRename(A:String, O:String, N:String) => done </k>
    <oldModelKeys>
      (SetItem(key(A, O)) OMS:Set => SetItem(key(A, N)) OMS)
    </oldModelKeys>
    <renamedModels> RMS:Map => RMS [ key(A, N) <- O ] </renamedModels>
    requires key(A, N) =/=K key(A, O)
    [all-path]

  // SPEC-PROVENANCE:
  // - E-005/E-006: old field names are read from from_state[(A,O)] but field
  //   tuples are keyed under the kept new model key (A,N); new field names are
  //   read from to_state[(A,N)].
  claim [FIELD-LISTS-USE-KEPT-NEW-KEY]:
    <k> prepareFieldLists(A:String, O:String, N:String, F:String) => done </k>
    <fromModels> SetItem(key(A, O)) FROM:Set </fromModels>
    <toModels> SetItem(key(A, N)) TO:Set </toModels>
    <renamedModels> ... key(A, N) |-> O ... </renamedModels>
    <oldFieldKeys> OFS:Set => OFS |Set SetItem(fieldKey(A, N, F)) </oldFieldKeys>
    <newFieldKeys> NFS:Set => NFS |Set SetItem(fieldKey(A, N, F)) </newFieldKeys>
    [all-path]

  // SPEC-PROVENANCE:
  // - E-002: the public traceback reports KeyError when V0 looks up
  //   to_state[(A,O)] after the model was renamed to N.
  claim [V0-OLD-TO-STATE-LOOKUP-FAILS]:
    <k> v0Lookup(fieldKey(A:String, N:String, F:String)) => done </k>
    <renamedModels> ... key(A, N) |-> O:String ... </renamedModels>
    <toModels> SetItem(key(A, N)) TO:Set </toModels>
    <lookupDefined> false => false </lookupDefined>
    requires key(A, O) =/=K key(A, N)
     andBool notBool (key(A, O) in SetItem(key(A, N)) TO)
    [all-path]

  // SPEC-PROVENANCE:
  // - E-001/E-006/E-007: intended behavior is no KeyError; the target-state
  //   model is the current kept model key (A,N).
  claim [V1-NEW-TO-STATE-LOOKUP-SUCCEEDS]:
    <k> v1Lookup(fieldKey(A:String, N:String, F:String)) => done </k>
    <toModels> SetItem(key(A, N)) TO:Set </toModels>
    <lookupDefined> false => true </lookupDefined>
    [all-path]

  // SPEC-PROVENANCE:
  // - I-005: without a model rename, old_model_name and model_name are the
  //   same, so V1 preserves the target-state lookup key.
  claim [NO-RENAME-FRAME]:
    <k> noRenameLookup(A:String, M:String, F:String) => done </k>
    <renamedModels> RMS:Map </renamedModels>
    <toModels> SetItem(key(A, M)) TO:Set </toModels>
    <lookupDefined> false => true </lookupDefined>
    requires notBool (key(A, M) in_keys RMS)
    [all-path]
endmodule
