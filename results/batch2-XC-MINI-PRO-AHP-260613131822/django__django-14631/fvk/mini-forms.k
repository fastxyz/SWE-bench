// mini-forms.k — a minimal K "mini-X" semantics for the fragment of
// django.forms touched by the django__django-14631 fix.
//
// CONSTRUCTED, NOT MACHINE-CHECKED (FVK MVP): this fragment models only the
// constructs the changed code uses — the ordered field list, the per-field
// `disabled` / `show_hidden_initial` / FileField flags, the *cached*
// BoundField.initial (a cached_property), the *impure* get_initial_for_field
// (a callable initial returns a fresh value on every evaluation), and the two
// driver loops `_clean_fields` and `changed_data` plus their helper
// `_has_changed`. Nothing else (HTML rendering, widgets, validators) is in the
// fragment, on purpose.
//
// The single most important thing this fragment captures faithfully is the
// IMPURITY of a callable `initial` (`get_initial_for_field` evaluates it every
// call) versus the CACHING of `BoundField.initial`. That gap is the whole
// ticket; see fvk/FINDINGS.md F1.

module MINI-FORMS-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports ID-SYNTAX

  // ---- Values -------------------------------------------------------------
  // iv(N, C): the value produced by the C-th evaluation of field N's initial.
  //   For a *callable* initial, distinct C give distinct values (the bug).
  //   For a *constant* initial, all C collapse (rule iv-const below).
  // nix(V): the microsecond-normalised value BoundField.initial returns
  //   (deterministic, idempotent; see BoundField.initial in boundfield.py).
  // dv(N): the widget data value for field N (bf.data / _field_data_value).
  syntax Value ::= "iv" "(" Id "," Int ")"
                 | "nix" "(" Value ")"
                 | "dv"  "(" Id ")"
                 | "cl"  "(" Value ")"      // field.clean() as a pure function

  // A "hidden initial" read result: either a python value or a validation error
  syntax HVal  ::= "hv" "(" Value ")" | "verr"

  // ---- Operations (redexes that drive <k>) --------------------------------
  syntax KItem ::= "getRawInitial" "(" Id ")"      // get_initial_for_field (impure!)
                 | "bfInitial"     "(" Id ")"      // BoundField.initial (cached)
                 | "dataOf"        "(" Id ")"      // bf.data
                 | "hiddenOf"      "(" Id ")"      // to_python(hidden widget value)
                 | "cleanVal"      "(" Value ")"   // field.clean(value)
                 | "fileClean"     "(" Value "," Value ")" // FileField.clean(value, initial)
                 | "fieldHasChanged" "(" Id "," Value "," Value ")" // Field.has_changed
                 | "hasChanged"    "(" Id ")"      // BoundField._has_changed
                 | "cleanFields"   "(" ")"         // BaseForm._clean_fields
                 | "changedData"   "(" ")"         // BaseForm.changed_data

  syntax KResult ::= Value | Bool
endmodule

module MINI-FORMS
  imports MINI-FORMS-SYNTAX
  imports INT
  imports BOOL
  imports MAP
  imports LIST
  imports K-EQUAL

  configuration
    <k> $PGM:K </k>
    <fields>    .List </fields>     // ordered field names  ListItem(Id)…  (order matters)
    <disabled>  .Map  </disabled>   // Id |-> Bool
    <showHidden>.Map  </showHidden> // Id |-> Bool
    <isFile>    .Map  </isFile>     // Id |-> Bool
    <dataVal>   .Map  </dataVal>    // Id |-> Value     (bf.data)
    <hiddenVal> .Map  </hiddenVal>  // Id |-> HVal      (to_python(hidden), or verr)
    <initCache> .Map  </initCache>  // Id |-> Value     (BoundField.initial cache); empty at start
    <evalCount> .Map  </evalCount>  // Id |-> Int       (#times the callable initial was evaluated)
    <cleaned>   .Map  </cleaned>    // Id |-> Value     (cleaned_data, output)
    <changed>   .List </changed>    // ListItem(Id)…    (changed_data, output)

  // ---- get_initial_for_field: IMPURE for a callable initial ---------------
  // Each evaluation bumps the per-field counter and returns a *fresh* value.
  // This is the modelled crux: two separate calls return iv(N,C) and iv(N,C+1).
  rule <k> getRawInitial(N) => iv(N, C) ... </k>
       <evalCount> ... N |-> (C => C +Int 1) ... </evalCount>

  // A *constant* (non-callable) initial collapses the counter dependence.
  // (Spec-only equational fact, used only for the constant-initial sub-case.)
  // rule iv(N, _) => iv(N, 0)   // [optional] enable to model constant initial

  // ---- BoundField.initial: cached_property + microsecond nix --------------
  // miss: evaluate once, normalise, store, return.
  rule <k> bfInitial(N) => getRawInitial(N) ~> #nixStore(N) ... </k>
       <initCache> Cache </initCache>
       requires notBool (N in_keys(Cache))
  rule <k> V:Value ~> #nixStore(N) => nix(V) ... </k>
       <initCache> Cache => Cache [ N <- nix(V) ] </initCache>
  // hit: pure read, no evaluation, no counter change.
  rule <k> bfInitial(N) => V ... </k>
       <initCache> ... N |-> V ... </initCache>
  syntax KItem ::= "#nixStore" "(" Id ")"

  // ---- bf.data / hidden read ----------------------------------------------
  rule <k> dataOf(N)   => V  ... </k> <dataVal>   ... N |-> V  ... </dataVal>
  rule <k> hiddenOf(N) => H  ... </k> <hiddenVal> ... N |-> H  ... </hiddenVal>

  // ---- field.clean / FileField.clean (pure functions over values) ---------
  rule <k> cleanVal(V)       => cl(V)        ... </k>
  rule <k> fileClean(V, _)   => cl(V)        ... </k>   // initial only matters for File diff; value cleaned

  // ---- Field.has_changed ---------------------------------------------------
  rule <k> fieldHasChanged(N, _, _) => false      ... </k>
       <disabled> ... N |-> true  ... </disabled>          // disabled short-circuit (fields.py:179)
  rule <k> fieldHasChanged(N, I, D) => I =/=K D   ... </k>
       <disabled> ... N |-> false ... </disabled>          // (None~'' folding omitted; orthogonal)

  // ---- BoundField._has_changed (boundfield.py) ----------------------------
  rule <k> hasChanged(N) => #hidden(hiddenOf(N)) ~> #hc(N) ... </k>
       <showHidden> ... N |-> true  ... </showHidden>
  rule <k> hasChanged(N) => fieldHasChanged(N, bfInitial(N), dataOf(N)) ... </k>
       <showHidden> ... N |-> false ... </showHidden>
  rule <k> #hidden(verr)  ~> #hc(_) => true ... </k>       // ValidationError => "changed"
  rule <k> #hidden(hv(V)) ~> #hc(N) => fieldHasChanged(N, V, dataOf(N)) ... </k>
  syntax KItem ::= "#hidden" "(" HVal ")" | "#hc" "(" Id ")"

  // ---- BaseForm._clean_fields (V1) ----------------------------------------
  rule <k> cleanFields() => #cleanLoop(Ns) ... </k> <fields> Ns </fields>
  rule <k> #cleanLoop(.List) => .K ... </k>
  rule <k> #cleanLoop(ListItem(N) Rest) => cleanOne(N) ~> #cleanLoop(Rest) ... </k>
  syntax KItem ::= "#cleanLoop" "(" List ")" | "cleanOne" "(" Id ")"
                 | "#file" "(" Id ")" | "#store" "(" Id ")"
  // value = bf.initial if field.disabled else bf.data
  rule <k> cleanOne(N) => bfInitial(N) ~> #file(N) ... </k> <disabled> ... N |-> true  ... </disabled>
  rule <k> cleanOne(N) => dataOf(N)    ~> #file(N) ... </k> <disabled> ... N |-> false ... </disabled>
  // FileField.clean(value, bf.initial)  vs  field.clean(value)
  rule <k> V:Value ~> #file(N) => fileClean(V, bfInitial(N)) ~> #store(N) ... </k>
       <isFile> ... N |-> true  ... </isFile>
  rule <k> V:Value ~> #file(N) => cleanVal(V) ~> #store(N) ... </k>
       <isFile> ... N |-> false ... </isFile>
  // cleaned_data[name] = value   (clean_<name> hook modelled as identity — see SPEC.md)
  rule <k> V:Value ~> #store(N) => .K ... </k> <cleaned> Cl => Cl [ N <- V ] </cleaned>

  // ---- BaseForm.changed_data (V1 comprehension over _bound_items) ----------
  rule <k> changedData() => #changedLoop(Ns, .List) ... </k> <fields> Ns </fields>
  rule <k> #changedLoop(.List, Acc) => .K ... </k> <changed> _ => Acc </changed>
  rule <k> #changedLoop(ListItem(N) Rest, Acc) => hasChanged(N) ~> #decide(N, Rest, Acc) ... </k>
  rule <k> B:Bool ~> #decide(N, Rest, Acc) => #changedLoop(Rest, Acc ListItem(N)) ... </k> requires B
  rule <k> B:Bool ~> #decide(N, Rest, Acc) => #changedLoop(Rest, Acc) ... </k> requires notBool B
  syntax KItem ::= "#changedLoop" "(" List "," List ")" | "#decide" "(" Id "," List "," List ")"
endmodule
