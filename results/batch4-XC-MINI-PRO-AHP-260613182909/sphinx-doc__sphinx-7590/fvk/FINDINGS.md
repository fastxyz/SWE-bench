# FINDINGS.md — sphinx-doc__sphinx-7590 (audit of the V1 UDL fix)

Plain-language findings from writing the spec (`SPEC.md`) for the V1 fix. Format:
`input → observed (V1) vs expected`. Each is tagged **[OK]** (V1 behaves per spec),
**[OK / out-of-domain]** (behavior only differs on ill-formed C++, handled
leniently), or **[LIMITATION]** (pre-existing gap, not introduced or worsened by
this fix). No **[BUG]** was found.

The headline result for a reader who never reads the proof: **the precise spec was
*easy* to write**, and that ease is the positive signal (the dual of the kit's
"spec-difficulty = bug signal"). The only judgement calls all concern *ill-formed*
C++ input, where any deterministic non-crashing answer is acceptable.

---

## FINDING 1 — booleans / pointers are correctly excluded from UDLs  [OK]

- input: `true_label` → observed: **not** a UDL; `skip_word('true')` uses `\btrue\b`,
  and since `_` is a word character there is no boundary between `true` and `_label`,
  so the word match fails and the token falls through to ordinary name parsing
  (`ASTUserDefinedLiteral` is never built). expected: per grammar fact **F1** there
  is no user-defined boolean literal; `true_label` is an identifier. ✔
- input: `nullptr_t` / `falsey` → same reasoning, treated as names. ✔
- Why it matters: a naïve implementation that ran `_udl` after the boolean branch
  would wrongly manufacture `true`+`_label`. V1 places the boolean/pointer
  `skip_word` checks **before** the numeric/string/char branches and never threads
  them through `_udl`, so PC-NOBOOLUDL holds by construction.

## FINDING 2 — ud-suffix must abut the literal (no whitespace)  [OK]

- input: `1 q_s` (space) → observed: `ASTNumberLiteral("1")`, cursor left before the
  space; `q_s` is parsed by the caller as a separate token. expected: per **F2** a
  ud-suffix has no intervening whitespace, so `1 q_s` is *not* a UDL. ✔
- input: `1q_s` (no space) → observed: `ASTUserDefinedLiteral(1, "q_s")`. ✔
- Mechanism: `_udl` calls `self.match(udl_identifier_re)` **without** a preceding
  `skip_ws`, so the identifier must start exactly at the cursor. (PC-NOWS.)

## FINDING 3 — standard suffix vs ud-suffix is disambiguated by `\b`  [OK]

This is the subtle one, and the reason the two new suffix regexes exist.

- input: `1ull` → observed: `ASTNumberLiteral("1ull")` (a plain unsigned-long-long),
  because `integers_literal_suffix_re` matches the *complete* token `ull` (trailing
  `\b` satisfied at end-of-token). expected: a standard integer literal. ✔
- input: `1q_s`, `1_km`, `1s` → observed: UDLs, because `q`,`_`,`s`… are not a
  complete standard suffix at that position. ✔
- input: `1u_s` → observed: `ASTUserDefinedLiteral(1, "u_s")` (the whole `u_s` is the
  ud-suffix), **not** `1u`+`_s`. Mechanism: candidate suffix `u` is followed by `_`
  (a word char), so the `\b` after the suffix group fails and the standard-suffix
  match is rejected; `_udl` then takes the entire `u_s`. expected: per **F3**, since
  `1u` cannot legally be followed by a stray `_s`, the entire `u_s` is the ud-suffix. ✔
- input: `1.0f` → `ASTNumberLiteral("1.0f")` (float suffix, complete token). ✔
- input: `1.0_f`, `1.0fq` → UDLs with suffix `_f` / `fq`, because the candidate
  float suffix `f` is followed by another identifier char so `(?![A-Za-z0-9_])`
  fails. ✔
- **LEM-\b** (SPEC Appendix A): every standard-suffix char is a word char, so the
  trailing `\b`/look-ahead fails exactly when more identifier chars follow ⇒
  "standard suffix" ⟺ "complete trailing token". This is what makes PC-STDSUFFIX
  hold for *all* inputs, not just the issue's example.

## FINDING 4 — behavior change is confined to *ill-formed* C++  [OK / out-of-domain]

V1 replaced the old greedy `while self.current_char in 'uUlLfF'` suffix-eater with
two precise regexes. The only inputs whose classification changed are **ill-formed**
C++ numeric literals:

- input: `123f` → V1: `ASTUserDefinedLiteral(123, "f")`; old code: `ASTNumberLiteral("123f")`.
  In C++ `123f` is ill-formed (`f` is a *floating* suffix, illegal on an integer),
  so neither answer is "the" correct number; V1's is the more grammar-faithful of
  the two (`f` is not a valid integer suffix, so it must be a ud-suffix). Documents
  without error either way. expected: undefined (ill-formed input) → any
  deterministic, non-crashing result. ✔
- input: `1e`, `0789`, `1.0LL` → similarly ill-formed; V1 yields a deterministic UDL
  or truncated number, never a crash. ✔
- **No well-formed literal changes classification:** floats are tried first and own
  every token containing `.`/`e`/`p`; the integer family only sees tokens with no
  `.`/`e`, and for those `f`/`F` is never a legal suffix. So no valid program that
  parsed before stops parsing, and no valid number becomes a UDL (FINDING 3 shows
  `1ull` etc. stay numbers). This bounds the blast radius of the change.

## FINDING 5 — UDL `get_id` is only reached at id-version ≥ 3  [OK]

- Observation: in `cpp.py`, an expression's `get_id` is invoked **only** from
  `ASTTemplateArgConstant.get_id` (line 1643) and `ASTArray.get_id` (line 2133), and
  *both* emit `str(self)` for versions 1 and 2 and call `self.value.get_id(v)` only
  for `v ≥ 3`.
- Consequence: `ASTUserDefinedLiteral.get_id` runs only with `v ≥ 3`. For v1/v2 the
  id of a UDL inside a template arg / array bound is its **string form** `1q_s`,
  which round-trips and is unique (STR). So the question "should UDL.get_id raise
  `NoOldIdError` for v1 (like `ASTOperatorLiteral` does)?" is **moot**: that branch
  is unreachable in practice.
- Decision: **do not** add a `version == 1` guard. Rationale, traced to obligations:
  (a) every sibling literal class (`ASTNumberLiteral`, `ASTStringLiteral`,
  `ASTCharLiteral`, `ASTBooleanLiteral`, `ASTPointerLiteral`) likewise emits an id
  for all versions and never raises; (b) the guard would be dead code (ID-DOMAIN);
  (c) even if some future caller did reach it at v1, the current formula yields a
  deterministic, non-crashing, unique string (`clL_Zliq_sEL1EE`). Adding dead code
  that could only ever *remove* a working id is a net negative. See PO-9.

## FINDING 6 — `get_id` is unique and collision-free  [OK]

- input pair: `1q_s` vs `1q_t` → ids `clL_Zli3q_sEL1EE` vs `clL_Zli3q_tEL1EE` — differ
  in the suffix. `1q_s` vs `2q_s` → differ in the literal (`L1E` vs `L2E`). The id is
  injective because `I.get_id` is the prefix-free `<len><name>` form and `L.get_id`
  is self-delimiting `L…E` (ID-INJ).
- Cross-kind collision: the id begins `clL_Zli…`; the `li` infix is *only* produced
  by a literal operator, and a `cl`-call to a literal operator **is** semantically a
  UDL, so the only thing that can share the id is the very same construct
  (ID-NOCLASH). No spurious cross-reference merging.

## FINDING 7 — `describe_signature` renders text, emits no broken xref  [OK]

- input: `1q_s` in a rendered signature → observed: the literal renders normally and
  the suffix `q_s` renders as plain text via the new `'udl'` description mode
  (`ASTIdentifier.describe_signature` → `nodes.Text`), **not** as a
  `pending_xref`. expected: the ud-suffix denotes `operator"" q_s`, which is not a
  referenceable bare identifier, so emitting an xref would create an unresolvable
  reference warning. V1 avoids it. ✔
- The `'udl'` mode was added to `verify_description_mode`'s allow-list, so the
  `verify_description_mode('udl')` call at the top of
  `ASTIdentifier.describe_signature` does not raise. ✔

## FINDING 8 — issue example now parses end-to-end  [OK]

- input: `constexpr auto units::si::planck_constant = 6.62607015e-34q_J * 1q_s`
  → observed: parses as a variable with initializer `(6.62607015e-34q_J) * (1q_s)`,
  a multiplication of two UDLs; **no** "Expected end of definition" warning.
  expected: per the issue, the directive should render. ✔ (Trace in PROOF.md PO-1.)

## FINDING 9 — redundant-but-harmless look-aheads in the integer-suffix regex  [OK]

- The `(?![uUlL])` look-aheads inside `integers_literal_suffix_re` are **logically
  redundant** with the trailing `\b`: every char in `uUlL` is a word char, so the
  `\b` already fails whenever a suffix char follows (LEM-\b). They neither add nor
  remove any match. Not a bug; left in place as defensive documentation of intent
  and to avoid touching a verified regex (minimal-change principle). Noted for the
  next iteration as an *optional* simplification (ITERATION_GUIDANCE).

## FINDING 10 — pre-existing limitations, untouched by this fix  [LIMITATION]

These are gaps that existed **before** V1 and are *not* introduced or worsened by
it; they are out of scope for this issue but recorded for honesty:

- input: `R"(raw)"` (raw string) → not recognized as a string literal
  (`_parse_string` only handles a leading `"`), so it (and therefore any
  `R"(...)"_udl`) is not parsed as a string/UDL. Pre-existing.
- input: `L"wide"`, `u8"utf8"` (encoding-prefixed strings) → `_parse_string`
  requires the cursor to be on `"`, so a prefixed string is not recognized.
  Pre-existing. (Prefixed *character* literals **are** handled by `char_literal_re`,
  so prefixed-char UDLs like `u8'a'_c` do work.)
- These do not regress: V1 only *adds* the `_udl(...)` wrapper around the existing
  string/char results, so anything that parsed before still parses identically.

## FINDING 11 — C domain (`c.py`) intentionally NOT given UDLs  [OK]

- UDLs are a C++-only feature. `sphinx/domains/c.py` has its own `_parse_literal`
  and was deliberately left unchanged. Adding UDL parsing there would be incorrect
  for the C language. expected: scope = C++ only. ✔
