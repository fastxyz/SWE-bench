# PROOF.md — sphinx-doc__sphinx-7590 (constructed, NOT machine-checked)

This proof discharges the obligations in `PROOF_OBLIGATIONS.md` against the
`MINI-PARSER` fragment of `SPEC.md`. Because the SUV is a **finite decision tree**
(no data-dependent loop, no arithmetic), the proof technique is the **Case
Analysis** + **Consequence** rules of `reachability-and-circularities.md` §2 — *not*
a loop circularity. Each `<k>` step below is an `Axiom` application of a
`MINI-PARSER` rule; cursor/`<def>` framing is automatic.

> **Honesty gate.** This proof is *constructed*, not run through `kprove`. The
> regex-match and string-slice primitives (`matches`, `matchAt`, `substr`) are the
> **trusted base**, standing in for Python's `re` engine — exactly as the `sum`
> example trusts K's `+Int`. Run-commands and residual risk are in §R.

---

## §1 Claim restated

```k
// mini-parser-spec.k  (constructed, not machine-checked)
claim <k> _parse_literal() => RESULT </k>
      <def> D </def> <pos> P0 => P1 </pos>
  // RESULT, P1 determined by the disjoint CASE split of SPEC §3
  [all-path]
```

There is exactly one claim and it has **no circularity** (the `for` loop is a fixed
4-way unrolling, discharged by Transitivity over 4 `Axiom` steps, not coinduction —
so guardedness is not even invoked). This is the *easy* shape, and that ease is
itself FINDING 0: a clean total contract exists.

---

## §2 Proof by case analysis

Write `s = D[P0:]`. `skip_ws` has run, so `s[0]` is non-space (or `s` empty).

### CASE N — empty / non-literal (PO-12)
If `s` matches none of the keyword words, `float_literal_re`, the integer-family
regexes, `_parse_string`, or `char_literal_re`, every `match`/`skip_*` returns
`false` **without advancing** `<pos>` (MINI-PARSER `match`-false rule keeps `P`).
The function reaches `return None` with `P1 = P0`. ∎ PO-12 (None branch).

### CASE B — boolean / pointer (PO-5)
`skip_word('nullptr'|'true'|'false')` uses `\bWORD\b`. Sub-cases:
- `s = "true"` then end/non-word ⇒ matches, returns `ASTBooleanLiteral(True)`,
  `P1=P0+4`. The function **returns before** any `_udl`, so no ud-suffix is
  attachable. ✔ PC-NOBOOLUDL.
- `s = "true_x"`: the boundary `\b` between `e` and `_` is absent (`_` is a word
  char), so `\btrue\b` **fails**; `skip_word` leaves `<pos>` unmoved; control falls
  through CASE F/I/S/C (all fail — `t` starts no number/string/char) to CASE N,
  returns `None`, and the caller parses `true_x` as a name. ✔ FINDING 1.
∎ PO-5.

### CASE F — floating literal (PO-2, PO-3, PO-6, PO-7)
`pos := P0` is recorded (SC-POS). `match(float_literal_re)` succeeds with maximal
match `NUMlit` (advances cursor to `P0+|NUMlit|`). Then `match(float_literal_suffix_re)`:
- **F1** matches ⟺ `s[|NUMlit|]∈{f,F,l,L}` **and** `s[|NUMlit|+1]` is not in
  `[A-Za-z0-9_]` (the `(?!…)`); cursor advances one more; `floatLit =
  ASTNumberLiteral(D[pos:self.pos]) = NUMlit·c`; return it. e.g. `1.0f→"1.0f"`. ✔
- **F2** else `_udl`: `match(udl_identifier_re)` at `P0+|NUMlit|`. If it matches an
  identifier `J`, return `ASTUserDefinedLiteral(ASTNumberLiteral(NUMlit), J)`,
  cursor past `J`. e.g. `6.62607015e-34q_J → UDL(6.62607015e-34, q_J)`,
  `1.0_f→UDL(1.0,_f)`, `1.0fq→UDL(1.0,fq)` (because in `fq` the `f` is followed by
  `q`, so F1's `(?!…)` failed). ✔ FINDING 3.
- **F3** else (neither suffix nor identifier follows): return `ASTNumberLiteral(NUMlit)`.
  e.g. `1.0`, `1e10`, `0x1p0`. ✔

By LEM-\b, F1 fires ⟺ the float suffix is a *complete* trailing token, so a valid
`1.0f` is a number while `1.0fq`/`1.0_f` are UDLs (PO-6). In every sub-branch the
consumed text equals `str(RESULT)` (PO-7): F1 `NUMlit·c`, F2 `NUMlit·str(J)`, F3
`NUMlit`. ∎ PO-3/6/7 (float), and PO-2 for floats (F1∪F3 cover all well-formed
floats, none of which has an identifier abutting after a complete suffix).

### CASE I — integer family (PO-2, PO-3, PO-6, PO-7) + SC-POS
Reached only if `float_literal_re` failed, i.e. it did **not** advance the cursor
(SC-POS: `match`-false keeps `P`), so `pos` still points at `s[0]`. The loop tries
`binary, hex, integer, octal` in order (SC-ORDER) — modeled as Transitivity over 4
`Axiom` steps, first success wins:
- `0b…`→binary, `0x…`→hex, `[1-9]…`→integer, `0…`→octal. (`0` alone: binary/hex/
  integer all fail, octal `0[0-7]*` matches `"0"`.) ✔
Then `match(integers_literal_suffix_re)`:
- **I1** complete standard suffix (`\b` holds) ⇒ `intLit = D[pos:self.pos]`
  includes it; return number. `5u→"5u"`, `5ull→"5ull"`, `5LL→"5LL"`, `5llu→"5llu"`.
  Verified against the suffix grammar in FINDINGS §3 / SPEC Appendix A. ✔
- **I2** else `_udl`: `1q_s→UDL(1,q_s)`; `1u_s→UDL(1,u_s)` because candidate `u` is
  followed by `_` so `\b` fails and the *whole* `u_s` is taken by `udl_identifier_re`
  (LEM-\b). ✔ FINDING 3.
- **I3** else plain number.
∎ PO-2/3/6/7 (integers). The slice starting at `pos` (not at the post-float
position) is correct precisely because the failed float match did not move the
cursor — this is the off-by-one SC-POS guards, and it holds.

### CASE S — string (PO-3, PO-7, PO-2)
`_parse_string()` (unchanged by V1) returns the quoted `str` or `None`. On a string,
`_udl(ASTStringLiteral(str))`: `"a"→ASTStringLiteral`, `"a"s→UDL(string,s)`,
`"a" s→ASTStringLiteral` then caller handles ` s`. Plain strings are byte-identical
to pre-V1 behavior (V1 only wraps the result in `_udl`, which is the identity when
no identifier abuts). ✔

### CASE C — character (PO-3, PO-7, PO-11)
`match(char_literal_re)` → `prefix=group(1)∈{None,u8,u,U,L}`, `data=group(2)`.
`ASTCharLiteral(prefix,data)`:
- the `assert prefix in _id_char_from_prefix` holds for all 5 possible prefixes;
- on `UnicodeDecodeError`/`UnsupportedMultiCharacterCharLiteral`, `self.fail(...)`
  **raises** (SC-FAIL-RAISES), so control never reaches `return _udl(charLit)` with
  an unbound `charLit`; on success `charLit` is bound and `_udl(charLit)` runs
  (`'a'_c→UDL(char,_c)`). ✔ PO-11.

---

## §3 `ASTUserDefinedLiteral` method proofs

### `_stringify` ⇒ STR / PO-7
`_stringify(t) = t(L) ++ t(I)`. With `t=str`: `str(L)+str(I)`. For
`UDL(ASTNumberLiteral("1"), ASTIdentifier("q_s"))` → `"1"+"q_s"="1q_s"`. Matches the
consumed slice in CASE I2. ∎

### `get_id` ⇒ ID / PO-8
`get_id(v) = "clL_Zli" + I.get_id(v) + "E" + L.get_id(v) + "E"`. Structural check
against the two reference manglings already in cpp.py:
- `ASTPostfixCallExpr.get_id` (cpp.py:1084) = `"cl" + idPrefix + Σ args + "E"`.
  Here `idPrefix = "L_Zli"+I.get_id(v)+"E"` and the single arg = `L.get_id(v)`.
- `ASTOperatorLiteral.get_id` (cpp.py:1589) = `"li" + I.get_id(v)` — exactly the
  inner `li…` we wrap in the `expr-primary` external-name form `L_Z…E`.

Worked instance `1q_s`, v≥3: `I.get_id = "3q_s"` (prefix-free `<len><name>`),
`L.get_id = "L1E"` ⇒ `clL_Zli3q_sEL1EE`. Re-parse: `cl[ L_Zli3q_sE ][ L1E ]E` —
a call to `operator"" q_s` on `1`. ✔
- **ID-DET**: pure function of `L,I,v`. ✔
- **ID-INJ**: `I.get_id` self-delimits via its length prefix and `L.get_id` via
  `L…E`, so `clL_Zli‹I›E‹L›E` is uniquely decomposable ⇒ injective up to
  literal-equality. ✔ (FINDING 6.)
- **ID-NOCLASH**: `li` is produced only by a literal operator; a `cl`-call to one is
  itself a UDL ⇒ no foreign collision. ✔
- **ID-DOMAIN / PO-9**: `v≥3` always (template-arg/array emit `str` for v1–v2). The
  v1 branch is unreachable, so the absence of a `NoOldIdError` guard is sound and
  the guard would be dead code. ∎

### `describe_signature` ⇒ DESC / PO-10
Appends `L.describe_signature(signode, mode,…)` (the literal classes ignore `mode`
and emit `nodes.Text`) then `I.describe_signature(signode,"udl",…)`. The `'udl'`
branch added to `ASTIdentifier.describe_signature` emits `nodes.Text(self.identifier)`
— plain text, no `pending_xref`. `verify_description_mode('udl')` passes because
`'udl'` was added to the allow-list. Visible output = `str(L)+str(I)`; no broken
xref. ∎ PO-10.

---

## §4 End-to-end trace — PO-1 (the issue)

Input initializer `6.62607015e-34q_J * 1q_s`:
1. `_parse_literal` @ `6.62607015e-34q_J`: CASE F → float `NUMlit=6.62607015e-34`;
   F1? next char `q`∉{f,F,l,L} ⇒ no; F2 `udl_identifier_re` matches `q_J` ⇒
   `UDL(6.62607015e-34, q_J)`; cursor at ` * 1q_s`.
2. multiplicative-expression parser consumes ` * `.
3. `_parse_literal` @ `1q_s`: float fails (no `.`/`e`), integer matches `1`,
   `integers_literal_suffix_re` fails at `q` (not a suffix char), F/I2 `_udl`
   matches `q_s` ⇒ `UDL(1, q_s)`; cursor at end.
4. expression closes; `assert_end` sees EOF ⇒ **no** "Expected end of definition".
∎ PO-1. The previously-failing definition now parses to
`(6.62607015e-34q_J) * (1q_s)`.

---

## §5 Proof-derived findings (for the next iteration)

Constructing the proof surfaced **no correctness gap** — the contract is total and
the case split is exhaustive. Two non-defect observations were promoted to
`FINDINGS.md` and `ITERATION_GUIDANCE.md`:
- the `(?![uUlL])` look-aheads are redundant with the trailing `\b` (FINDING 9) —
  optional cleanup, not a fix;
- behavior on *ill-formed* numeric literals (`123f`, `1e`) changed but stays
  deterministic and non-crashing (FINDING 4) — an UltimatePowers clarification, not
  a bug.

Difficulty signal: **none**. A clean, total, exhaustive spec was writable, which is
the positive dual of the kit's "hard spec ⇒ likely bug" heuristic.

---

## §R Run-commands & residual risk (constructed, not machine-checked)

```sh
# Constructed artifacts would be emitted as:
kompile mini-parser.k --backend haskell        # compile the fragment semantics
kast    --backend haskell mini-parser-spec.k   # (optional) parse-check the claim
kprove  mini-parser-spec.k                      # expected: #Top (the single claim, no circularity)
```

Expected `kprove` outcome (reasoned, not executed): `#Top`. The claim is a finite
disjunction of `Axiom`+`Consequence` steps with no coinduction and no nonlinear
arithmetic VC, so nothing in the bundled tier is missing; the only obligations that
leave the tier are the **regex-semantics primitives**, which are axiomatized
(trusted base), not proved.

**Residual risk / trusted base:**
- **Regex + string primitives** (`matches`/`matchAt`/`substr`, i.e. Python `re` and
  slicing) are trusted, exactly as `+Int` is trusted in the arithmetic examples.
  The proof reasons about *which* regex wins using the Appendix-A axioms; it does
  not re-derive `re`'s matching algorithm.
- **Partial vs total:** here total correctness is established (PO-14: no
  data-dependent loop, no recursion) — stronger than the kit's usual partial
  default.
- **Adequacy of the fragment:** `MINI-PARSER` models only `match`, `skip_*`, and
  slicing, which is all `_parse_literal` uses; it does **not** model the enclosing
  expression grammar (that is the caller's contract, covered only at the level of
  "cursor handed back unmoved/advanced", PO-12).
- **Constructed, not machine-checked:** upgrading to machine-verified requires
  running the commands above (and a faithful `re`-in-K, the roadmap item).
