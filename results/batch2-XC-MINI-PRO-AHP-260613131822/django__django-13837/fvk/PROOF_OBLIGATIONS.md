# PROOF_OBLIGATIONS.md — `get_child_arguments()`

The verification conditions that, together, establish the §3 postcondition of
[`SPEC.md`](SPEC.md) on the §2 domain. Because the function has **no loop and no
recursion**, the obligations are *branch* VCs (Case Analysis + symbolic execution),
**one structural-map** VC, **one exhaustiveness** VC, and **one intent-boundary**
obligation. Each entry: statement · discharge method · status.

> All "discharged" results are **constructed, not machine-checked** — they would be
> confirmed by `kprove autoreload-spec.k` returning `#Top` (see [`PROOF.md`](PROOF.md) §6).

---

### PO-M — branch **M** (the `-m` fix, the core of the ticket)
**Statement.** If `spec = spec(P) ∧ P ≠ ""`, then symbolic execution of `body(spec(P))`
reaches `<out> = base(E,W) ++ ["-m"] ++ [P] ++ tl(A)`.
**Discharge.** Guard `(spec(P) isNot None) and (spec(P).parent)` ⇒ `true and (P =/= "")`
⇒ `P =/= ""` ⇒ `true` by hypothesis; take the then-branch; execute
`args = base(E,W)`, `args += ["-m"] ++ [P] ++ tl(A)`, `return args`. List-concat
associativity (K `List`) folds to the claimed `<out>`. No arithmetic VC.
**Status. Discharged** (Case Analysis + Axiom steps).

### PO-X — branch **X** (Windows `.exe` console-script)
**Statement.** If `(spec = None ∨ P = "") ∧ ¬exists(hd A) ∧ exists(withExe(hd A))`, then
`<out> = [str(withExe(hd A))] ++ tl(A)` (note: **no** `base` prefix — the exe is run
directly, ignoring `sys.executable`).
**Discharge.** Guard M is false (`specParentEmpty` ⇒ short-circuit `and` false / `isNot
None` false); enter `else`; `not exists(hd A)` ⇒ `true`; inner `if exists(withExe …)` ⇒
`true`; early `return [str(withExe(hd A))] ++ tl(A)`. Matches claim.
**Status. Discharged.**

### PO-R — branch **R** (`-script.py` entry point)
**Statement.** If `(spec = None ∨ P = "") ∧ ¬exists(hd A) ∧ ¬exists(withExe(hd A)) ∧
exists(withScr(hd A))`, then `<out> = base(E,W) ++ [str(withScr(hd A))] ++ tl(A)`.
**Discharge.** As PO-X to the inner `else`; `if exists(withScr …)` ⇒ `true`; `return args
++ [str(withScr(hd A))] ++ tl(A)` with `args = base(E,W)`. Matches claim.
**Status. Discharged.**

### PO-S — branch **S** (normal script / directory / zipfile)
**Statement.** If `(spec = None ∨ P = "") ∧ exists(hd A)`, then `<out> = base(E,W) ++ A`.
**Discharge.** Guard M false; `not exists(hd A)` ⇒ `false`; take outer `else`;
`args += A`; `return args` ⇒ `base(E,W) ++ A`. Matches claim. **This is the branch that
preserves the pre-fix behavior for `manage.py`, directories, and zipfiles (F3, F5, F6).**
**Status. Discharged.**

### PO-! — branch **!** (error path)
**Statement.** If `(spec = None ∨ P = "") ∧ ¬exists(hd A) ∧ ¬exists(withExe) ∧
¬exists(withScr)`, the function raises `RuntimeError`.
**Discharge.** All three FS guards false ⇒ innermost `else: raise` ⇒ `<out> =
#raise("Script does not exist.")`. Per kit guidance, `raise` is modelled at the fragment
edge (we do not model Python exception objects). **Status. Discharged as the documented
error outcome** (no claim that it *returns*).

### PO-EXH — guards are exhaustive **and** mutually exclusive
**Statement.** The preconditions of {M, X, R, S, !} partition all inputs satisfying D1–D2.
**Discharge.** Let `g = (spec ≠ None ∧ P ≠ "")`. M ⟺ `g`. The remaining four are
`¬g ∧ …`, split first on `e0 = exists(hd A)`: S ⟺ `¬g ∧ e0`; and on `¬e0` split on
`e1 = exists(withExe)` then `e2 = exists(withScr)`: X ⟺ `¬g∧¬e0∧e1`, R ⟺ `¬g∧¬e0∧¬e1∧e2`,
! ⟺ `¬g∧¬e0∧¬e1∧¬e2`. This is a complete, disjoint Boolean decision tree over
`{g, e0, e1, e2}`. Pure propositional tautology. **Status. Discharged (Z3-trivial).**

### PO-WF — the `-W` comprehension (`base`/`Wf` structural map)
**Statement.** `Wf([]) = []` and `Wf([h]++t) = ['-W'+h] ++ Wf(t)`, and
`base(E,W) = [E] ++ Wf(W)`; `base` is total and order-preserving.
**Discharge.** Structural induction on the list `W` (a finite list map); base + cons
cases, **no side condition**. Independent of branch selection. **Status. Discharged
(structural; trivial).**

### PO-TERM — termination / total correctness
**Statement.** `get_child_arguments` terminates on every input in D1–D2.
**Discharge.** No `while`/`for` over program state, no recursion; the only iteration is
the finite `Wf` map (PO-WF). Straight-line + bounded ⇒ terminates. So the partial-
correctness claims are in fact **total** modulo the total oracles. **Status. Discharged
(no decreasing-measure obligation needed).**

---

### PO-D3 — *[ESCALATION BOUNDARY]* the package-vs-module intent assumption (Finding F1)
**Statement.** On branch M, re-launching `-m P` reproduces the original program **iff**
the `-m` target was a *package* (`spec.name == P + ".__main__"`), i.e. precondition D3.
**Why it cannot be discharged in the bundled tier.** Deciding whether `P` (or `spec.name`)
names a runnable program equivalent to the original launch requires modelling the OS
process launch and CPython's import system (package vs module resolution, `sys.path[0]`
injection, `__main__.py` lookup) — outside the mini-Python fragment and outside the
arithmetic/Z3 + `[simplification]` tier. Per the kit, this is an **[ESCALATION
BOUNDARY]**, *not* a `[trusted]` admission and *not* a code bug.
**Resolution adopted.** Restrict the verified domain to D3 (the ticket's stated scope);
record the complement as **Finding F1** (kept-test + intent-elicitation), and **do not
change the code** — the ticket fixes the contract at `__main__.__spec__.parent`. The
optional code refinement that would *additionally* satisfy F1 (`use spec.name unless it
ends in '.__main__'`) is specified in [`ITERATION_GUIDANCE.md`](ITERATION_GUIDANCE.md) and
**rejected for this ticket** (diverges from the mandated algorithm; raises test risk).
**Status. Open by design (out-of-domain), routed to Findings/Iteration; not blocking.**

---

## Summary

| Obligation | Method | Status |
|---|---|---|
| PO-M (the `-m` fix) | Case Analysis + Axiom | discharged* |
| PO-X / PO-R / PO-S / PO-! | Case Analysis + Axiom | discharged* |
| PO-EXH (partition) | propositional / Z3 | discharged* |
| PO-WF (`-W` map) | structural induction | discharged* |
| PO-TERM | no-loop ⇒ total | discharged* |
| PO-D3 (F1 intent boundary) | — | **[ESCALATION BOUNDARY]**, out-of-domain |

`*` constructed, not machine-checked (would be `#Top` from `kprove`). **Every in-domain
obligation discharges; the sole open item is the out-of-domain intent boundary PO-D3.**
⇒ V1 is correct on its specified domain.
