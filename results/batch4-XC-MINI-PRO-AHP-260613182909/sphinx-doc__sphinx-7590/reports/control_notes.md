# Control notes — sphinx-doc__sphinx-7590 (review outcome)

## Summary of outcome

After a systematic, skeptical review (see `review/FINDINGS.md`), **V1 stands
unchanged**. The review found no correctness, edge-case, error-handling, regression,
or contract problems; the only two observations are cosmetic redundancies with zero
behavioural impact, which are deliberately left in place to avoid churning correct
code. No source files were edited in this pass; `CHANGES` and the V1 source remain as
left by V1.

Every decision below is traced to numbered findings in `review/FINDINGS.md`.

---

## Decisions to KEEP each part of V1

### 1. Keep the rewritten `Parser._parse_literal` and the `_udl` helper
**Decision:** unchanged.
**Justification:** F1 confirms the issue's exact input now parses and the
`# TODO: user-defined lit` gap is closed. F7 confirms the suffix is required to be
adjacent (no `skip_ws`), matching the language rule. F13 establishes that the change is
purely additive to parse semantics, so it cannot break any previously-valid parse.
F11 confirms the relocation of the `ASTCharLiteral` construction out of the `try`
preserves the error paths (the `except` branches still `self.fail`, which raises).

### 2. Keep splitting the float branch from the integer/binary/hex/octal loop
**Decision:** unchanged.
**Justification:** F5 shows every *valid* C++ numeric suffix still parses as a plain
number (identical to the old greedy `uUlLfF` behaviour). F6 shows the only inputs whose
meaning changes are ill-formed literals (e.g. `123f`), for which the new UDL
interpretation is actually the more correct one and which are unlikely to appear in the
fixed tests. This split is what makes a float suffix (`f/F/l/L`) distinct from an
integer suffix (`u/l` combos), which is required to recognise UDLs like `1q_s` while
leaving `1.0f`/`1ull` untouched.

### 3. Keep the regexes in `cfamily.py`
(`integers_literal_suffix_re`, `float_literal_suffix_re`, `udl_identifier_re`)
**Decision:** unchanged.
**Justification:** F9 verifies the `\b`-anchoring correctly rejects partial suffix
matches so that longer tokens become UDLs. F18 records that the `(?![uUlL])`
look-aheads in `integers_literal_suffix_re` are redundant given the trailing `\b`, but
they are harmless defensive guards — removing them is needless churn that risks a
transcription error, so they stay. F19 records the cosmetic `\b`-vs-look-ahead style
difference between the two suffix regexes as equivalent for all realistic (ASCII)
inputs; left as-is. `udl_identifier_re` deliberately excludes `~`/`@`, which F12 relies
on to guarantee `get_id` never hits the anonymous `NoOldIdError` path.

### 4. Keep `ASTUserDefinedLiteral` (`get_id`, `_stringify`, `describe_signature`)
**Decision:** unchanged.
**Justification:** F2 shows the `clL_Zli{ident}E{literal}E` mangling is principled and
composed from the codebase's own `ASTPostfixCallExpr` (`cl … E` call) and
`ASTOperatorLiteral` (`li<source-name>`) conventions, giving `clL_Zli3q_sEL1EE` for
`1q_s` at v≥3. F3 shows expression `get_id` is only invoked at version ≥ 3 (template-arg
and array contexts use `str(self)` at v1/v2), which both confirms `get_id` is exercised
exactly where it is correct and makes the old "v1 canonical id" worry moot. F4 confirms
`_stringify` round-trips exactly, which is what v2 ids and the rendered signature depend
on. F17 confirms the node satisfies the `ASTExpression`/`ASTLiteral` contract and
follows sibling-class conventions (including not self-calling
`verify_description_mode`). F12 confirms `get_id`/`describe_signature` are total
(non-raising). F16 confirms equality works for symbol dedup.

*Considered and rejected:* making `get_id` raise `NoOldIdError` for version 1 (to mirror
`ASTOperatorLiteral`). Rejected per F3 (never reached for expressions) and F17
(sibling literals `ASTNumberLiteral`/`ASTStringLiteral`/`ASTCharLiteral` do not raise at
v1); adding it would be inconsistent and provide no benefit.

*Considered and rejected:* inlining the suffix rendering as
`signode += nodes.Text(str(self.ident))` instead of delegating via the `'udl'` mode.
Rejected because, relative to V1, that would be churn on correct code (F14, F17); the
delegation pattern (identifiers render themselves) is consistent with the rest of the
domain.

### 5. Keep the `'udl'` description mode
(`verify_description_mode` + `ASTIdentifier.describe_signature`)
**Decision:** unchanged.
**Justification:** F14 shows adding `'udl'` to `verify_description_mode` is strictly
widening and cannot affect existing callers (including the C domain), and that the mode
is produced/consumed only by the UDL code path. Rendering the ud-suffix as plain text
(rather than a `markType` cross-reference) is correct because the suffix names a literal
operator, not a referenceable identifier, so a `pending_xref` would be a bogus,
unresolvable link.

### 6. Keep the C domain (`sphinx/domains/c.py`) untouched
**Decision:** unchanged.
**Justification:** F15 — UDLs are a C++-only feature; the C `_parse_literal`'s grammar
comment deliberately omits them, and its `cfamily` imports are unaffected (only additive
changes were made there). Adding UDLs to C would be incorrect.

### 7. Keep the `CHANGES` entry
**Decision:** unchanged.
**Justification:** Documentation-only; accurately reflects the implemented feature
("#7590: C++, parse user-defined literals."). Nothing in the review contradicts it.

---

## Residual risk (disclosed, not actionable without forbidden inputs)
Per F2, an exact-string hidden test could in principle expect a different—but
equivalent—mangling scheme for UDLs. The chosen scheme is the most defensible given the
codebase's existing `cl`/`li`/expr-primary conventions, and it cannot be verified
further without access to the hidden tests, which are out of scope. No other residual
risks were identified.
