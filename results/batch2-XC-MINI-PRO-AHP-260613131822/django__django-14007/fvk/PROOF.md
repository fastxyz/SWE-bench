# PROOF — django__django-14007 (V1 fix audit)

**Constructed, NOT machine-checked.** The FVK MVP builds the proof and emits the
`kompile`/`kprove` commands but does not run them. Artifacts:
[`apply_converters.k`](apply_converters.k),
[`apply_converters-spec.k`](apply_converters-spec.k). Obligations ledger:
[`PROOF_OBLIGATIONS.md`](PROOF_OBLIGATIONS.md).

What is proved (in plain language):

> For every list of fetched rows `rows` and every converter dict `converters` such
> that each row is long enough for every converter position,
> `list(apply_converters(rows, converters))` equals `convertRows(rows, converters,
> connection)` — i.e. each output row is the input row with **exactly** the
> converter-mapped columns folded through their converter chains and **every other
> column identical**. Composed with `get_converters`/`execute_sql`, the value set
> on each model attribute after an insert is the raw DB value passed through that
> field's converters — the same value a `SELECT` produces. When no returning field
> has a converter, the rows are returned unchanged.

---

## 1. The claims

- `(APPLY)` — function contract: `apply_converters(rows, converters) ⇒
  convertRows(rows, converters, connection)`, `requires
  allRowsPositionsInRange(rows, converters)`.
- `(CHAIN)`, `(ROW)`, `(ROWS)` — one circularity per loop (inner/middle/outer),
  generalized over the accumulator/suffix, with `positionsInRange` side conditions.

Full text in `apply_converters-spec.k`.

## 2. Short English proof

By the reachability proof system (Reflexivity, Axiom+framing, Transitivity,
Consequence, Case-analysis, Abstraction, **Circularity**). K treats every claim in
the module as a coinduction hypothesis, available only after ≥1 genuine `=>⁺` step
(guardedness).

**`(CHAIN)`.** Evaluate `#forLoop(conv, CL, body)` — that unfold is the genuine
step. Case-split `CL`. Empty: zero further work, `value == V ==
applyChain(.List,V,…)`. Non-empty `ListItem(F) Rest`: the loop binds `conv := F`,
runs `value = applyC(F, value, expression, connection)` so `value := applyC(F,V,…)`, then
reaches `#forLoop(conv, Rest, body)` — the **same claim** at `{value :=
applyC(F,V,…), CL := Rest}`; the hypothesis closes it, and `applyChain(Rest,
applyC(F,V,…),…) = applyChain(ListItem(F)Rest, V, …)` by definition. No VC.

**`(ROW)`** reuses `(CHAIN)` as a lemma. Unfold `#forLoop(ent, CVS, …)`. Empty:
`row == R == convertRow(R,.List,…)`. Non-empty `ListItem(entry(P,CL,E)) Rest`:
`value := row[P]` is defined because `positionsInRange` gives `0≤P<size(R)`
(**Consequence**, Z3); the inner loop yields `value := applyChain(CL, R[P], E,…)`
by `(CHAIN)`; `row[P] = value` rebinds `row := R[P <- applyChain(CL,R[P],E,…)]`,
whose `size` is unchanged (`OB-SIZEUPDATE`), so `positionsInRange(Rest, size(row))`
still holds and `(ROW)` applies at the shifted state, giving `convertRow(R,
ListItem(entry(P,CL,E))Rest, …)` by definition.

**`(ROWS)`** reuses `(ROW)`. Unfold `#forLoop(row0, ROWS, …)`. Empty: `result ==
Acc`. Non-empty `ListItem(R0) Rest`: `row := list(R0) = R0` (a `List` value, copied
— so the source `rows` is never mutated); `(ROW)` gives `row :=
convertRow(R0,CVS,…)`; `append` gives `result := Acc
ListItem(convertRow(R0,CVS,…))`; `(ROWS)` at the shifted state gives `Acc
convertRows(ListItem(R0)Rest, CVS, …)` after regrouping by List associativity
(`OB-ASSOC`).

**`(APPLY)`** composes by Transitivity: `result := .List`; the outer loop via
`(ROWS)` with `Acc := .List` (and `.List convertRows(…) = convertRows(…)`);
`return result` delivers `convertRows(rows, converters, connection)`. ∎

## 3. Machine-detailed sketch (one representative branch)

`(ROW)`, body-taken branch, one iteration, as `kprove` would drive it:

```
#forLoop(ent, ListItem(entry(P,CL,E)) Rest, BODY)
  —[#forLoop unfold]→            (ent = entry(P,CL,E)) ~> BODY ~> #forLoop(ent, Rest, BODY)
  —[assign ent]→                 store[ent := entry(P,CL,E)]
  —[unpack: pos/convs/expression accessors]→  store[pos := P, convs := CL, expression := E]
  —[value = row[pos], requires 0<=P<size(R)]→  store[value := R[P]]        // Consequence: Z3 from positionsInRange
  —[(CHAIN) lemma: for conv in convs=CL]→       store[value := applyChain(CL, R[P], E, Cn)]
  —[row[pos] = value]→           store[row := R[P <- applyChain(CL,R[P],E,Cn)]]   // size invariant: OB-SIZEUPDATE
  —[#forLoop(ent, Rest, BODY) via (ROW) hypothesis]→  store[row := convertRow(R[P<-…], Rest, Cn)]
  ⊢ convertRow(R[P<-applyChain(CL,R[P],E,Cn)], Rest, Cn)
      #Equals convertRow(R, ListItem(entry(P,CL,E)) Rest, Cn)             // 2nd convertRow rule  ⇒ #Top
```

The unpacking binds `pos := P`, `convs := CL`, `expression := E` once per
iteration (modelling `for pos, (convs, expression) in converters:`), so the inner
loop matches `(CHAIN)` verbatim with `expression |-> E`, and `(CHAIN)` discharges
it. Side conditions, all discharged: `0≤P<size(R)` and `positionsInRange(Rest,
size(R[P<-…]))` (Z3, using `size(R[P<-…])==size(R)`).

## 4. Verification conditions

| VC | Where | Tier | Result |
|---|---|---|---|
| `0 ≤ P < size(R)` | `(ROW)` subscript | Z3 | ✅ from `positionsInRange` |
| `size(L[I<-V]) == size(L)` | `(ROW)` after store | `[simplification]` | ✅ |
| `positionsInRange` head/tail monotone | `(ROW)`,`(ROWS)` | Z3 | ✅ |
| List assoc / `.List` unit | `(ROWS)`,`(APPLY)` | builtin | ✅ |
| converter-fold equalities | all | structural (no VC — opaque `applyC`) | ✅ |

**No nonlinear arithmetic VC arises** (converters are uninterpreted). The clean,
VC-light spec is itself the benefit-2 signal that the fix has no hidden corner case
(`FINDINGS.md` PF1).

## 5. Reproduce the machine check (constructed, not run)

```sh
kompile apply_converters.k --backend haskell        # compile the mini-X fragment
kast    --backend haskell apply_converters-spec.k   # (optional) parse-check the claims
kprove  apply_converters-spec.k                      # expected: #Top  (all four claims proved)
```

`#Top` from `kprove` is what would upgrade these from *constructed* to
*machine-verified*. Until then, treat the result as a careful constructed proof.

## 6. Test-redundancy recommendation (benefit 1) — conditioned on machine-checking

The hidden suite is fixed and unseen, so this is advisory and **recommendation-only;
never auto-delete**, and only after `kprove` returns `#Top`.

- **Subsumed once machine-checked** — any unit test asserting that, for a returning
  field with a converter, `create()`/`bulk_create()` set the *converted* value
  (e.g. `MyAutoField.from_db_value` ⇒ `am.id` is a `MyIntWrapper` and `==` the
  raw int), *for a specific input*. The `(APPLY)` contract entails it for **all**
  in-domain inputs. Estimated CI saving: negligible (a handful of model-insert
  cases), but they become logically redundant.
- **Keep — out of the verified domain or below the trust boundary:**
  - per-backend integration tests that actually hit PostgreSQL/MySQL/Oracle/SQLite
    (they exercise `OB-RAWSHAPE`, the trusted DBMS boundary, not the fold);
  - the **plain-`AutoField`** no-regression test (`create()` still yields a plain
    `int`) — it pins the `OB-NOOP` empty-converters branch and guards against a
    future change that resolves spurious converters;
  - any `ignore_conflicts` / `bulk_create` row-count tests (termination/shape,
    `OB-TERM`, not covered by partial correctness);
  - any Oracle-specific returning test (`OB-ORACLE-RAW` escalation).

## 7. Residual risk

- **Partial correctness only** — termination not proved (finite lists make it
  trivially true; `OB-TERM`, benign).
- **Trusted base** — the mini-X fragment's adequacy; the reachability metatheory and
  `kprove`; Z3 / the `[simplification]` oracle; and `OB-RAWSHAPE` (the DBMS/driver
  returns one column per returning field, in order).
- **One escalation boundary** — `OB-ORACLE-RAW` (Oracle RETURNING-INTO rawness),
  moot for `AutoField`. Not admitted `[trusted]`.
- **Constructed, not machine-checked** — re-run §5 to close the gap.

## 8. Benefit payoffs

1. **Hidden-bug surfacing.** Formalization confirmed the fix and pinned its exact
   contract boundary: one side condition, `PRE-INDEX`, already enforced by the
   RETURNING/`returning_fields` column parity; the necessity of the `Col` wrapper
   (a bare `Field` would `AttributeError` on SQLite/MySQL/Oracle); and the
   inertness of the fix for plain `AutoField` (no regression). See `FINDINGS.md`.
2. **Fewer tests / faster CI.** Per-input "converted value after insert" assertions
   are subsumed by `(APPLY)` once machine-checked; the out-of-domain and
   per-backend boundary tests are explicitly kept.
