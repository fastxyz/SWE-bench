# PROOF — `_check_regexp_csv` / `_regexp_csv_transfomer`

Constructed correctness proof (symbolic execution against `fvk/mini_python.k`
of the claims in `fvk/mini_python_spec.k`). **Constructed, not machine-checked:**
the MVP does not run `kompile`/`kprove`; the run-commands are in §6.

---

## 1. What is proved (plain language)

> For **every string** `value`, `_check_regexp_csv(value)` returns exactly
> `SPLIT(value)` — `value` partitioned at commas that are **not** inside an
> unclosed `{…}`, each field stripped, empty fields dropped — and it always
> terminates and never raises. Consequently `_regexp_csv_transfomer(value)`
> returns `[re.compile(p) for p in SPLIT(value)]`, raising
> `argparse.ArgumentTypeError` for any non-compilable `p` and **never** emitting
> an empty match-everything pattern.

This holds for the **V2** code. For **V1** the same proof goes through for the
split itself but **fails at the result loop (PO6)** for inputs with a
whitespace-only field — which is precisely Finding F2.

## 2. Function contract (C-STR) and the two loops

The body is a straight-line init (`regexps=[None]`, `open_curly=False`) followed
by two bounded `for` loops: the **scan loop** (builds `regexps`) and the
**result loop** (emits strings). Compose by Transitivity:

```
init  ⟹  ⟨regexps=[None], open_curly=False⟩
scan loop  ⟹  ⟨regexps = segs(VALUE), open_curly = inBrace(VALUE)⟩      (via LOOP circularity)
result loop  ⟹  ⟨out = emit(segs(VALUE))⟩                               (via result circularity)
                = ⟨out = split(VALUE)⟩                                  (def. of split)
```

## 3. Scan-loop circularity (the heart)

Claim `(LOOP)` is generalized over `R` (partial `regexps`), `B` (`open_curly`),
and `REST` (unscanned suffix). Proof by **guarded coinduction**:

* **Guardedness.** Take one genuine `=>⁺` step: the `for char in (ListItem(C)
  Rest) : BODY` rule fires, binding `char = C` and exposing `BODY ~> for char in
  Rest`. That real step "pays for" reusing the hypothesis.
* **Case-split on the body guards** (`#Or`), exhaustive and mutually exclusive —
  the four rows of PO4's table. In each branch the semantic rules rewrite the
  state to `⟨R' = step(R,B,C), B' = brace(B,C)⟩`:
  * `C = "{"`: `open_curly := true`; `C` appended to the last segment.
  * `C = "}"` with `B`: `open_curly := false`; `C` appended.
  * `C = ","` with `¬B`: a new `None` sentinel appended (a **split**).
  * otherwise (a non-special char, **or a `,` while `B`**, or a stray `}`): `C`
    appended to the last segment (comma **protected** inside the brace — this is
    the bug-fix behavior of F1).
  The `regexps[-1] is None` sub-case opens a fresh segment `[C]`; otherwise the
  alias `current = regexps[-1]` is extended in place (Finding F7), modelled as
  updating `regexps`' last segment.
* **Invoke the circularity** on the shifted state `(R', B', Rest)` — legal
  because the `for`-step already provided guardedness — giving `regexps =
  scanFrom(R', B', Rest) = scanFrom(R, B, C·Rest)` and `open_curly = brace(...)`.
* **Exit branch** `REST = .List`: the `for _ in .List` rule ends the loop;
  `scanFrom(R,B,.List)=R`, `brace(B,.List)=B`. Both branches land on the claimed
  post-state. ∎ (modulo PO8)

Instantiating `(LOOP)` at the entry state `R=[None]`, `B=false` gives the scan
result `segs(VALUE)` with `open_curly = inBrace(VALUE)`, since `inBrace("")=false`
and `segs` seeds with `[None]` (PO3).

## 4. Result-loop circularity — where V1 and V2 diverge

The result loop folds `regexps` into `<out>` via `emit`:

```
emit(.List)              = .List
emit(None  :: R)         = emit(R)                          # drop sentinel
emit(seg   :: R)         = let s = strip(join(seg)) in
                             (s :: emit(R)) if s != ""       # V2: drop empties
                             else emit(R)
```

* **V2 code** is exactly this `emit`: `if regexp is None: continue` (drop
  sentinel), `stripped = "".join(regexp).strip()`, `if stripped: yield stripped`
  (drop empties). The result-loop circularity discharges by the same bounded
  coinduction as §3 — one `for` step per segment, case-split on `None` /
  empty / non-empty. ✅ → PO6 holds → PO1 holds.

* **V1 code** omits the `if stripped:` guard: `yield "".join(regexp).strip()`
  for every non-`None` segment. That is `emitᵥ₁`, which **keeps** empty-after-
  strip fields. The Consequence step then needs `emitᵥ₁(segs(VALUE)) =
  split(VALUE)`, i.e. `emitᵥ₁ = emit`. This VC is **false**: pick a `segs`
  containing a segment `seg` with `strip(join(seg)) = ""` but `seg ≠ None` — it
  exists whenever `VALUE` has a whitespace-only field, e.g. `"a, ,b"`:

  ```
  segs("a, ,b") = [None, ['a'], None, [' '], None, ['b']]
  emit   (...)  = ["a", "b"]            # spec  (V2)
  emitᵥ₁ (...)  = ["a", "", "b"]        # V1   →  re.compile("") matches everything
  ```

  The proof **gets stuck here**, and per the methodology a stuck VC is a strong
  bug signal, not a dead end: it localizes Finding F2. The repair is the minimal
  `if stripped:` guard, which makes the VC `emit = emit` (trivially true). ✅

## 5. No-exception + termination + composition

* **Termination (total correctness).** Both loops are `for` over fixed-length
  values; each step consumes one element; length strictly decreases to `0`. No
  decreasing-measure obligation is deferred — stronger than the `while` examples.
* **No exceptions (PO7).** `regexps` is non-empty by construction so `[-1]`
  never raises; `current.append` runs only on a list; `join`/`strip` are total.
* **Composition (PO9).** `_regexp_csv_transfomer` maps each `p ∈ SPLIT(value)`
  through `_regex_transformer`. Valid `p` → `re.compile(p)`; invalid `p` →
  `argparse.ArgumentTypeError` (clean exit, the issue thread's "exit cleanly").
  Because `SPLIT` (V2) never emits `""`, no field compiles to a match-all
  pattern — the externally visible payoff of the F2 fix.

## 6. Escalation, residual risk, run-commands

* **[ESCALATION BOUNDARY] (PO8).** The §3/§4 circularities are proved per-step
  and for every bounded instance; closing them for an **unbounded symbolic**
  string/list needs structural `List`/`String` induction (μ-logic), outside the
  bundled tier. Specified and routed to the sources; **not** faked `[trusted]`.
  This is a proof-capability gap, not a correctness gap.
* **Trusted base.** Adequacy of the mini-Python fragment; the Python aliasing
  encoding (F7); reachability metatheory + `kprove`; the SMT oracle.
* **Constructed, not machine-checked.** To upgrade:

  ```sh
  kompile fvk/mini_python.k --backend haskell
  kast    --backend haskell fvk/mini_python_spec.k   # one AST, optional
  kprove  fvk/mini_python_spec.k                      # expected: #Top
  ```

## 7. The two FVK benefit payoffs

* **Benefit 2 (hidden bug).** The proof attempt on **V1** stalls at exactly one
  VC (§4), and that stall *is* Finding F2: V1 silently turns a whitespace-only
  CSV field into a regex that matches every name. Found without running any
  test, purely from the inability to write a clean postcondition.
* **Benefit 1 (test redundancy).** Once machine-checked, (C-STR)+(C-LIST) hold
  for *all* in-domain inputs, so per-input unit tests of the splitter are
  subsumed. See ITERATION_GUIDANCE §"Tests". **Recommendation only, conditioned
  on running `kprove`** — and gated further by PO8 still being open, so the
  honest advice is: **keep the tests for now.**
