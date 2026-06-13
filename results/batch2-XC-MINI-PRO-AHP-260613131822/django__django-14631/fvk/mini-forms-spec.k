// mini-forms-spec.k — reachability claims for the django__django-14631 fix.
// CONSTRUCTED, NOT MACHINE-CHECKED. Proves against mini-forms.k.
//
//   kompile mini-forms.k --backend haskell
//   kast    --backend haskell mini-forms-spec.k
//   kprove  mini-forms-spec.k          # expected: #Top  (all claims proved)

requires "mini-forms.k"

module MINI-FORMS-SPEC-SYNTAX
  imports MINI-FORMS-SYNTAX
endmodule

module VERIFICATION
  imports MINI-FORMS-SPEC-SYNTAX
  imports MINI-FORMS
  imports MAP-SYMBOLIC
  imports K-EQUAL

  // ---- spec-only vocabulary -----------------------------------------------
  // hcPred(N): the per-field "did it change?" predicate, abstracted as a
  // function of the form state (it is what BOTH V0's inline block and V1's
  // BoundField._has_changed compute — see PROOF_OBLIGATIONS PO-HASCHANGED).
  syntax Bool ::= "hcPred" "(" Id ")" [function]
  // keep(Ns): the ordered sublist of Ns whose hcPred is true — the closed form
  // of changed_data, and the loop circularity's postcondition.
  syntax List ::= "keep" "(" List ")" [function]
  rule keep(.List) => .List
  rule keep(ListItem(N) Rest) => ListItem(N) keep(Rest) requires hcPred(N)
  rule keep(ListItem(N) Rest) => keep(Rest)             requires notBool hcPred(N)

  // hasChanged(N) computes exactly hcPred(N) (definition of the abstraction).
  rule <k> hasChanged(N) => hcPred(N) ... </k> [simplification]
endmodule

module MINI-FORMS-SPEC
  imports VERIFICATION

  // =========================================================================
  // (BF-INIT-MISS) First read of BoundField.initial: evaluate the (possibly
  // callable) initial EXACTLY ONCE, normalise, cache it, and return it.
  // =========================================================================
  claim <k> bfInitial(N:Id) => nix(iv(N, C)) ... </k>
        <initCache> Cache => Cache [ N <- nix(iv(N, C)) ] </initCache>
        <evalCount> ... N |-> (C:Int => C +Int 1) ... </evalCount>
        requires notBool (N in_keys(Cache))
        [all-path]

  // =========================================================================
  // (BF-INIT-HIT) Every subsequent read is a pure cache hit: same value, and
  // the callable initial is NOT evaluated again (evalCount unchanged).
  // Together with (BF-INIT-MISS): BoundField.initial is single-evaluation.
  // =========================================================================
  claim <k> bfInitial(N:Id) => V ... </k>
        <initCache> ... N |-> V:Value ... </initCache>
        [all-path]

  // =========================================================================
  // (CLEAN-DISABLED-CONSISTENCY) Core ticket property. For a disabled,
  // non-File field whose initial is not yet cached, _clean_fields writes into
  // cleaned_data the SAME value it caches as BoundField.initial. Hence
  // cleaned_data[N] == form[N].initial (both = nix(iv(N,C))), and the callable
  // initial is evaluated once. `cl` collapses on an already-valid initial
  // (DateTimeField.to_python(datetime) == datetime); see SPEC.md / PO-CLEAN-ID.
  // =========================================================================
  claim <k> cleanOne(N:Id) => .K ... </k>
        <disabled>  ... N |-> true  ... </disabled>
        <isFile>    ... N |-> false ... </isFile>
        <initCache> Cache => Cache [ N <- nix(iv(N, C)) ] </initCache>
        <evalCount> ... N |-> (C:Int => C +Int 1) ... </evalCount>
        <cleaned>   Cl => Cl [ N <- cl(nix(iv(N, C))) ] </cleaned>
        requires notBool (N in_keys(Cache))
        [all-path]

  // =========================================================================
  // (CHANGED-LOOP) Loop-invariant circularity for the changed_data
  // comprehension. Generalised over the remaining names Ns and the
  // accumulator Acc: running the loop appends exactly keep(Ns) to Acc and
  // terminates. K uses this claim as its own coinduction hypothesis.
  // =========================================================================
  claim <k> #changedLoop(Ns:List, Acc:List) => .K ... </k>
        <changed> _ => Acc keep(Ns) </changed>
        [all-path]

  // =========================================================================
  // (CHANGED-DATA) Function contract: changed_data() yields keep(fields), i.e.
  // the field-ordered sublist of names that changed — identical to V0's loop.
  // =========================================================================
  claim <k> changedData() => .K ... </k>
        <fields>  Ns:List </fields>
        <changed> _ => keep(Ns) </changed>
        [all-path]
endmodule
