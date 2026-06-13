# PROOF.md — constructed correctness proof for `get_child_arguments()`

**Claim proved (plain language).** For every launch in the verified domain
([`SPEC.md`](SPEC.md) §2), `get_child_arguments()` returns exactly the argv prescribed by
the §1 branch table — in particular, for a `python -m PKG …` launch of a **package**
`PKG` it returns `[sys.executable, *(-W flags), '-m', PKG, *sys.argv[1:]]` (the ticket's
fix), for a normal script / directory / zipfile it returns `[sys.executable, *(-W flags),
*sys.argv]`, and the Windows `.exe` / `-script.py` workarounds are preserved unchanged.

> **Constructed, not machine-checked.** No `kompile`/`kprove` was run (no execution
> environment). The argument below is a paper proof against the mini-Python fragment of
> [`SPEC.md`](SPEC.md) §4–§5; §6 gives the exact commands that would upgrade it to
> machine-verified.

---

## 1. Shape of the proof

No loop, no recursion ⇒ **no circularity**. The proof is **Case Analysis** over the
guard variables `{g, e0, e1, e2}` (defined in PO-EXH) followed by straight-line symbolic
execution in each cell, composed by **Transitivity**. Five reachable leaves: M, X, R, S,
! — exactly the five claims in `autoreload-spec.k`.

```
                 g = (spec≠None ∧ parent≠"") ?
                 ├── true  ─────────────► (M)  base ++ ["-m",P] ++ tl(A)
                 └── false ─► e0 = exists(hd A) ?
                              ├── true  ─────► (S)  base ++ A
                              └── false ─► e1 = exists(withExe) ?
                                           ├── true  ─► (X)  [str(withExe)] ++ tl(A)
                                           └── false ─► e2 = exists(withScr) ?
                                                        ├── true  ─► (R) base ++ [str(withScr)] ++ tl(A)
                                                        └── false ─► (!)  raise RuntimeError
```

## 2. Proof of branch (M) — the fix

Goal `A ⊢ φ_pre^M ⇒ φ_post^M`, with `φ_pre^M`: `<store> exe|->E warn|->W argv|->A
spec|->spec(P) </store> ∧ requires P =/=String ""`.

1. `args = base(exe,warn)` — Axiom (assign), `base` oracle ⇒ store `args |-> base(E,W)`.
2. Evaluate guard `(spec isNot None) and (spec.parent)`:
   - `spec |-> spec(P)`; `spec(P) isNot None ⇒ true` (Axiom).
   - `true and (spec.parent) ⇒ spec.parent` (short-circuit Axiom).
   - `spec(P).parent ⇒ P` (attr Axiom); in boolean context `P ⇒ (P =/=String "")`.
   - By `requires P =/=String ""` (Consequence, Z3-trivial) the guard is `true`.
3. `if true : … else : …` ⇒ take then-branch (Axiom).
4. `args += ["-m"] ++ [P] ++ tl(argv)` ⇒ store
   `args |-> base(E,W) ++ ListItem("-m") ++ ListItem(P) ++ tl(A)` (assoc of `++`).
5. `return args` ⇒ `<out>` gets that list; `<k> ⇒ .K`.
6. The reached `<out>` is syntactically the claim's RHS. **(M) discharged** — `#Top`.

Discharges **PO-M**. This is the line that makes `python -m PKG runserver` reload as
`python -m PKG …` for *every* package, fixing the ticket (cf. F4 backward-compat:
`P = "django"` reproduces the legacy result).

## 3. Proof of branches (S), (X), (R), (!)

All four start by **falsifying g** under `requires (SP ==K None orBool
specParentEmpty(SP))`:
- if `SP = None`: `None isNot None ⇒ false`, `false and _ ⇒ false`;
- if `SP = spec(P) ∧ P = ""`: `true and (spec.parent)` ⇒ `P` ⇒ `("" =/=String "") ⇒
  false`.
Either way the guard is `false` (Consequence, Z3-trivial) ⇒ take the outer `else`. Then:

- **(S)** `requires exists(hd A) = true`: `not exists(hd A) ⇒ false` ⇒ inner `else` ⇒
  `args += argv; return args` ⇒ `<out> = base(E,W) ++ A`. **PO-S discharged.**
- **(X)** `requires ¬exists(hd A) ∧ exists(withExe(hd A))`: `not exists ⇒ true` ⇒ inner
  `if`; `exists(withExe …) ⇒ true` ⇒ `return [str(withExe(hd A))] ++ tl(A)` (no `base`).
  **PO-X discharged.**
- **(R)** `requires ¬exists(hd A) ∧ ¬exists(withExe) ∧ exists(withScr)`: as (X) to the
  next `else`; `exists(withScr …) ⇒ true` ⇒ `return base(E,W) ++ [str(withScr(hd A))] ++
  tl(A)`. **PO-R discharged.**
- **(!)** all three FS predicates false ⇒ innermost `else: raise` ⇒
  `<out> = #raise("Script does not exist.")`. **PO-! discharged** as the documented error
  outcome (no return claimed).

## 4. Global obligations

- **PO-EXH** — the `{g,e0,e1,e2}` decision tree (§1) is complete and disjoint:
  propositional tautology, Z3-trivial. ⇒ the five claims cover all of D1–D2 with no
  overlap, so the postcondition is single-valued.
- **PO-WF** — `base(E,W) = [E] ++ Wf(W)` with `Wf` the structural `-W` map: base/cons
  induction, no side condition.
- **PO-TERM** — straight-line + finite `Wf` map ⇒ terminates ⇒ the `[all-path]` claims
  are total here.

All in-domain obligations close. The only non-closed item is **PO-D3**, the
out-of-domain intent boundary (§5).

## 5. Proof-derived findings (feedback for the next iteration)

- **F1 / PO-D3 — [ESCALATION BOUNDARY], not a code bug.** The proof needed precondition
  **D3** ("the `-m` target is a *package*") for branch (M) to be *faithful to the original
  launch*. That precondition is an intent/OS fact the bundled tier cannot decide; its
  complement (`python -m PKG.MOD`, MOD a non-package module) is where V1 reconstructs the
  wrong `-m` target. **Evidence:** branch-M step 4 reconstructs `-m P` from `spec.parent`
  with no consultation of `spec.name`. **Classification:** underspecified-intent /
  escalation. **UltimatePowers question:** *"Should `python -m pkg.module runserver`
  (module, not package) be auto-reloadable? If yes, reconstruct from `spec.name` when it
  does not end in `.__main__`."* **Recommended next change:** see
  [`ITERATION_GUIDANCE.md`](ITERATION_GUIDANCE.md) — *optional, rejected for this ticket*.
  **Tests:** keep any test that pins a non-package `-m` launch.
- **F2 / F3 — positive, keep the guards.** The proof's guard-falsification step relies on
  both `getattr(__main__,'__spec__',None)` (F2) and the `and __main__.__spec__.parent`
  truthiness test (F3, the `specParentEmpty` fold). Removing either re-opens a branch:
  dropping the `getattr` default ⇒ `AttributeError` in Conda/embedded; dropping the `and
  parent` ⇒ branch M wrongly captures directory/zipfile launches. **These two details are
  load-bearing and must stay.**

## 6. Artifacts and the (unrun) machine-check

Files modelled: `autoreload.k` (fragment semantics) and `autoreload-spec.k` (the five
claims), both inlined in [`SPEC.md`](SPEC.md) §4–§5. Commands that would discharge them:

```sh
kompile autoreload.k --backend haskell        # compile the mini-Python fragment
kast    --backend haskell autoreload-spec.k    # (optional) confirm the claims parse
kprove  autoreload-spec.k                      # expected: #Top  (all five claims proved)
```

**Expected outcome:** `#Top`. The claims contain no nonlinear arithmetic and no
circularity, so no `[simplification]` lemmas beyond list-concat associativity and the
`specParentEmpty` fold are needed; the residual VCs (guard truthiness, PO-EXH partition)
are linear/propositional and fall to Z3.

## 7. Residual risk

- **Partial vs total:** total correctness holds here (no loops; PO-TERM), modulo the
  totality of the `exists`/path/`base` **oracles** — the trusted base.
- **Fragment adequacy:** the mini-Python model (§4 of SPEC) abstracts `Path.exists`,
  `with_suffix`, `with_name`, `str`, and the `-W` comprehension as oracles; their
  faithfulness to CPython/`pathlib` is assumed, not proved.
- **PO-D3 / F1:** the verified domain excludes non-package `-m` sub-module launches by
  design; behavior there is the documented Finding F1.
- **"Constructed, not machine-checked":** the `#Top` above is *expected*, not observed.

## 8. Test-redundancy report (recommendation-only; conditioned on machine-checking)

Mapping the *kinds* of unit tests this contract would have onto the proof (test files are
hidden and must not be modified — this is advice only):

| test kind (illustrative) | subsumed by | recommendation |
|---|---|---|
| `-m django` ⇒ `['-m','django',…]` | PO-M with `P="django"` | redundant *iff* `kprove`=`#Top` — **but KEEP** (see below) |
| `-m <other pkg>` ⇒ `['-m',<pkg>,…]` | PO-M | redundant *iff* `#Top` — **but KEEP** |
| script `manage.py` ⇒ `[…, argv]` | PO-S | redundant *iff* `#Top` — **but KEEP** |
| Windows `.exe` / `-script.py` paths | PO-X / PO-R | **KEEP** (oracle-dependent FS behavior) |
| `__spec__` absent / `parent==""` dir/zip | PO-EXH + branch S | **KEEP** (pins F2/F3 guard details) |
| non-package `-m pkg.module` (if any) | *not covered* (PO-D3 open) | **KEEP** (out-of-domain, F1) |

**Net recommendation: KEEP ALL TESTS.** Three reasons override the nominal redundancy:
(1) the proof is *constructed, not machine-checked* — the honesty gate forbids removal
until `kprove` returns `#Top`; (2) the contract is proved against a *modeled* fragment
with filesystem/interpreter **oracles**, so the unit tests pin exactly the
oracle-and-launch behavior the model abstracts; (3) several tests (F2/F3/F1) sit on or
outside the domain boundary and guard against regressions the proof does not cover.
Estimated CI time saved by removals: **0 s (none recommended).**

---

### Bottom line
Every in-domain proof obligation discharges (constructed); the guards partition the input
space; the two load-bearing guard details (F2, F3) are confirmed necessary; the lone open
item (PO-D3 / F1) is an out-of-domain intent boundary the ticket explicitly does not
target. **The proof supports leaving V1 unchanged.**
