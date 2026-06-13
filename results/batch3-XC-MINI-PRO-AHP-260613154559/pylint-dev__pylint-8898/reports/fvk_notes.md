# FVK audit notes — pylint-dev__pylint-8898

This records the second-pass (FVK) audit of the V1 fix and every decision that
followed, traced to specific entries in `fvk/FINDINGS.md` (F-) and
`fvk/PROOF_OBLIGATIONS.md` (PO-). The FVK artifacts are `fvk/SPEC.md`,
`fvk/FINDINGS.md`, `fvk/PROOF_OBLIGATIONS.md`, `fvk/PROOF.md`,
`fvk/ITERATION_GUIDANCE.md`, plus the constructed (not machine-checked) K files
`fvk/mini_python.k` and `fvk/mini_python_spec.k`.

## What the audit did

`/formalize`: wrote the contract for `_check_regexp_csv` as "generalize
`_splitstrip` — split on commas **except inside an unclosed `{}`**, strip each
field, **discard empty fields**" (`SPEC.md` §2, abstraction `SPLIT`), plus the
scan-loop circularity and the list/tuple pass-through claim. `/verify`:
constructed the proof by symbolic execution + guarded coinduction, decomposed it
into obligations PO1–PO9, and found that **V1 satisfied every obligation except
PO6**.

## The one code change in V2 — and why

**Change:** in `pylint/utils/utils.py::_check_regexp_csv`, the result loop now
skips a field that is empty after stripping (`if stripped: yield stripped`)
instead of unconditionally `yield`-ing `"".join(regexp).strip()`.

**Why, traced:**
- **Finding F2** (🔴 regression). Writing the spec exposed that V1 kept the
  *strip* but dropped the *discard-empty* half of the `_splitstrip` contract it
  replaced. So `bad-names-rgxs = "a, ,b"` produced `["a", "", "b"]` under V1; the
  `""` is compiled by `_regex_transformer` into `re.compile("")` — a pattern
  that **matches every name**, silently. The original `_splitstrip`-based code
  produced `["a", "b"]`. This is the reporter's feared "silently create
  [something] instead of erroring out" scenario.
- **PO6** is the obligation "result loop = `split`". `PROOF.md` §4 shows the V1
  result loop computes `emitᵥ₁` (drop `None`, strip, **keep** empties) while the
  spec needs `emit` (also drop empties); the equality VC `emitᵥ₁ = emit` is
  false on any whitespace-only field. PO6 was the **sole** failing obligation,
  and the proof getting stuck there *is* the F2 bug signal (Benefit 2).
- The repair is minimal and provably sufficient: with `if stripped:` the result
  loop is exactly `emit`, so the VC becomes trivial and **PO6 → ✅**, which lifts
  PO1 (the function contract) from ❌ to ✅ (`PROOF_OBLIGATIONS.md` summary
  table). It touches only the result loop, so PO3–PO5 (the splitting invariant)
  are unaffected — confirmed by the proof being byte-identical for the scan loop.

This is also a pure restoration of long-standing behavior (`_splitstrip` always
discarded empty-after-strip fields), so it cannot regress any input that worked
before V1; it only removes the match-all pattern V1 newly introduced.

## What V1 got right and is deliberately kept unchanged

- **Overall architecture** — `_check_regexp_csv` in `utils.py`, re-exported from
  `pylint/utils/__init__.py`, called by `_regexp_csv_transfomer`, with each piece
  validated/compiled by the reused `_regex_transformer`. Justified by **F1**
  (this is what actually fixes the reported crash/mangling), **PO1/PO9** (the
  function + transformer contracts hold for the split once PO6 is fixed), and
  **PO2** (the list/tuple branch is the trivial pass-through, matching the
  sibling `_check_csv`). No reason to restructure.
- **The `open_curly` boolean splitting heuristic** (don't split on a comma while
  inside an unclosed `{`). Justified by **F1** (correctly protects `{m,n}`
  quantifiers) and **PO3–PO5** (the scan-loop invariant initializes, is preserved
  by the exhaustive four-way case split, and exits correctly). The unclosed-`{`
  edge (**F3**) is the *explicitly agreed* maintainer heuristic, not a bug, and
  both resulting strings are valid regexes — kept as-is.
- **`str.strip()` of each field** (**F8**) — matches `_splitstrip`; internal
  whitespace preserved, which is correct for name regexes.
- **Reliance on Python list aliasing** in `current = regexps[-1];
  current.append(char)` (**F7**) — correct CPython behavior and the intended
  mechanism; documented as a conscious part of the trusted base, no change.
- **Generator return type** `Iterable[str]` (**F6**) — the sole caller
  materializes it into a list, so single-use is safe; values are identical to a
  list. Left unchanged to avoid churn; noted for any future caller.
- **No total-correctness measure was added.** Per `SPEC.md` §4 / `PROOF.md` §5,
  both loops are `for` over fixed-length values and terminate structurally, so
  correctness is already **total** here — there is no `while`-style termination
  gap to defer, and nothing to add.

## What was found but intentionally NOT changed (scope)

- **`_regexp_paths_csv_transfomer` has the same comma-in-quantifier bug**
  (**F4**, `ITERATION_GUIDANCE.md` G3). It still uses the naïve
  `_csv_transformer`. Left unchanged because the issue, the maintainer thread,
  and the option surface all concern `regexp_csv` (`bad-names-rgxs`); path
  regexes with `{m,n}` are rare; and that transformer has extra path-rewriting
  that needs its own spec. Recorded as a deferred follow-up to honor the
  "minimal, targeted" constraint.
- **Deprecating CSV-of-regexes** long-term (**G4**) — a product decision; the V2
  patch is the agreed short-term repair and is forward-compatible with it.

## Honesty gate

The proof is **constructed, not machine-checked** (no `kompile`/`kprove` run;
commands in `PROOF.md` §6). The fully-general induction over symbolic
strings/lists (**PO8**) is an open **[ESCALATION BOUNDARY]** routed to the
μ-logic sources — not faked as `[trusted]`. Therefore **no test removal is
recommended** (Benefit 1 is gated on both machine-checking and closing PO8);
`ITERATION_GUIDANCE.md` recommends *adding* regression tests — notably
`"a, ,b" → ["a", "b"]`, the case that distinguishes V2 from V1 — and *keeping*
all existing and out-of-domain tests. The Findings (Benefit 2), including the F2
fix, stand independently of machine-checking.

## Net diff vs V1

One function body edit (`_check_regexp_csv` result loop: add the empty-field
guard) plus its docstring/comment. `pylint/config/argument.py`,
`pylint/utils/__init__.py`, and the `doc/whatsnew/fragments/8898.bugfix`
changelog are unchanged from V1. The user-facing fix for #8898 (commas in
quantifiers no longer mangle the regex) is delivered by V1 and preserved; V2
removes the empty-field match-all regression that the formal spec surfaced.
