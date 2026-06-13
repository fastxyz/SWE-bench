# PROOF OBLIGATIONS — `_check_regexp_csv` / `_regexp_csv_transfomer`

The verification conditions (VCs) the claims in `mini_python_spec.k` decompose
into. Status: ✅ discharged (bundled tier: symbolic execution + Z3 + finite case
analysis) · 🟦 [ESCALATION BOUNDARY] (needs string/list structural induction,
beyond the bundled tier; specified and routed, never faked `[trusted]`). Each PO
notes whether **V1** and **V2** satisfy it.

Notation: `VALUE` = symbolic input string (a char-list); `P` = scanned prefix;
`REST` = unscanned suffix; `R` = partial `regexps`; `B` = `open_curly`.
`inBrace`, `segs`, `emit`, `split`, `scanFrom`, `brace` are the abstractions in
`mini_python_spec.k`.

---

## PO1 — (C-STR) function contract, string branch
`∀ string VALUE.  ⟨_check_regexp_csv body, regexps=[None], open_curly=False⟩
 ⇒ ⟨out = split(VALUE)⟩`.
Composed by Transitivity from PO3–PO7. **V1: fails** (via PO6). **V2: holds.**

## PO2 — (C-LIST) function contract, list/tuple branch
`∀ list/tuple VALUE.  _check_regexp_csv(VALUE)` yields exactly the elements of
`VALUE` in order (`out = VALUE`).
✅ One-rule `yield from value`; trivial bounded-`for` circularity over `VALUE`.
No stripping/filtering (matches `_check_csv`). **V1 & V2: hold** (unchanged).

## PO3 — scan-loop invariant, initialization
At loop entry `R = [None]` and `B = false`, and `B = inBrace("")` (= `false`),
`R = segs("")` (the seed `[None]`).
✅ Immediate from the literal initial state. **V1 & V2: hold.**

## PO4 — scan-loop invariant, preservation (VC-STEP)
For one char `c`: `scanFrom(R, B, c·REST) = scanFrom(step(R,B,c), brace(B,c),
REST)` and `brace(B, c·REST) = brace(brace(B,c), REST)`, where `step` is the
body's case logic:

| char `c` | `brace` update | `regexps` update (`step`) |
|---|---|---|
| `"{"` | `B := true` | append `c` to last seg (or open new seg if last is `None`) |
| `"}"` & `B` | `B := false` | append `c` to last seg |
| `","` & `¬B` | `B` unchanged | append a new `None` sentinel |
| else (incl. `","` & `B`, `}` & `¬B`) | `B` unchanged | append `c` to last seg |

For **one symbolic char with the four guards split** (`#Or` case analysis), each
branch reduces by the semantic rules to the matching `step`/`brace` clause:
✅ at the per-step / bounded level (the guard algebra is Boolean — Z3 — and the
list append is one `ListItem` cons). The branch table is exhaustive and the
guards are mutually exclusive, so no case is missed.
The closure over an **arbitrary symbolic suffix** `REST` is PO8. **V1 & V2:
hold** (the splitting logic is byte-for-byte identical between V1 and V2; the
audit changed only the result loop).

## PO5 — scan-loop exit
When `REST = .List` (string consumed): `scanFrom(R,B,.List)=R`,
`brace(B,.List)=B`; the bounded `for` exits (`for _ in .List` rule). Hence after
the scan, `regexps = segs(VALUE)` and `open_curly = inBrace(VALUE)`.
✅ Base rule + PO3/PO4. Termination is structural (finite list). **V1 & V2: hold.**

## PO6 — result loop = `split` (THE discriminating obligation)
The result loop maps `regexps = segs(VALUE)` to `out`, and the claim requires
`out = split(VALUE) = emit(segs(VALUE))`.

`emit` (spec) = drop `None` sentinels, **strip**, **drop empty-after-strip**.

* **V1 result loop** = `yield "".join(seg).strip() for seg in segs if seg is not
  None` = drop `None`, strip, **but KEEP empty-after-strip**. So V1 computes
  `emitᵥ₁(segs) ≠ emit(segs)` exactly on inputs with a **whitespace-only
  segment** (`join(seg).strip() == ""` while `seg ≠ None`): e.g.
  `VALUE = "a, ,b"` → V1 `["a","","b"]`, spec `["a","b"]`. **PO6 FAILS for V1.**
  This is Finding F2, and it is the lone place the V1 proof gets stuck — the
  forced choice "admit an empty output field or add a guard" is the bug signal.
* **V2 result loop** adds `if stripped:` before `yield`, i.e. drop
  empty-after-strip. Now `emitᵥ₂ = emit`. ✅ **PO6 holds for V2.**

Discharge level: ✅ for the per-segment classification (`None` vs char-list;
`trimWS(joinChars(seg)) == ""` is a definedness/Z3 check per segment) and for
every concrete/bounded `segs`; the unbounded-list closure is PO8.

## PO7 — no exceptions on the in-domain (`str`) path
* `regexps` starts `[None]` and only ever **grows** (append), so it is never
  empty ⇒ `regexps[-1]` never raises `IndexError`. ✅
* `current.append(char)` is called only in the `current is not None` branch, so
  it is always a list. ✅ (relies on the alias of F7).
* `"".join(seg)`/`.strip()` are total on lists of 1-char strings / strings. ✅
* No `re` compilation happens **inside** `_check_regexp_csv`; compilation and its
  `ArgumentTypeError` live in `_regex_transformer` (PO9). **V1 & V2: hold.**

## PO8 🟦 [ESCALATION BOUNDARY] — induction over symbolic strings/lists
Closing PO4 and PO6 for a **fully symbolic, unbounded** `VALUE`/`segs` requires
structural induction over K `List`/`String` (an inductive `μ`-predicate
argument), which the bundled `[simplification]` tier does not discharge — the
same boundary as the insertion-sort example's list/multiset VCs. **Specified,
discharged for every bounded instance, routed to the μ-logic / reachability
sources (FM 2012, LICS 2013/2019).** NOT admitted as `[trusted]`. This is a
proof-capability gap, **not** a code bug — V2's code is correct on the domain;
only the fully-general machine proof is deferred.

## PO9 — `_regexp_csv_transfomer` composition (caller)
`_regexp_csv_transfomer(value) = [ _regex_transformer(p) for p in
_check_regexp_csv(value) ]`.
* Each `p ∈ SPLIT(value)`; `_regex_transformer(p)` returns `re.compile(p)` or
  raises `argparse.ArgumentTypeError` on `re.error`. ✅ (reused unchanged).
* With V2, no `p` is the empty string from a whitespace field, so the only
  empty `p` possible would be… none — `SPLIT` never emits `""`. Hence no
  accidental match-all pattern. ✅ (this is the externally observable payoff of
  PO6.)
* A genuinely invalid regex (e.g. `"(foo"`) still yields a clean
  `ArgumentTypeError`, never a traceback. ✅ **V1 & V2: hold** (V2 additionally
  removes the empty-pattern path).

---

## Summary table

| PO | What | V1 | V2 |
|----|------|----|----|
| PO1 | function contract (str) | ❌ (via PO6) | ✅ |
| PO2 | function contract (list) | ✅ | ✅ |
| PO3 | invariant init | ✅ | ✅ |
| PO4 | invariant step (VC-STEP) | ✅ | ✅ |
| PO5 | loop exit + termination | ✅ | ✅ |
| PO6 | result loop = `split` | ❌ (keeps empty field) | ✅ |
| PO7 | no exceptions on str path | ✅ | ✅ |
| PO8 | 🟦 unbounded induction | escalated | escalated |
| PO9 | transformer composition | ✅* | ✅ |

\*PO9 "held" for V1 only in the sense of not crashing; it still passed an empty
match-all pattern downstream (F2). V2 closes that.

**Bottom line:** V1 satisfies every obligation **except PO6**, and PO6 fails on
exactly the whitespace-empty-field inputs of Finding F2. The V2 edit (filter
empty-after-strip in the result loop) discharges PO6 with no effect on PO3–PO5
(the splitting logic is untouched), upgrading PO1 from ❌ to ✅.
