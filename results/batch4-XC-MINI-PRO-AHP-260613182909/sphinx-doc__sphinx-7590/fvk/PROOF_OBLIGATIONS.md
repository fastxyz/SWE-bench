# PROOF_OBLIGATIONS.md — sphinx-doc__sphinx-7590

The discrete obligations that together establish the SPEC. Each is discharged in
`PROOF.md` by symbolic case analysis over the parser fragment (`MINI-PARSER`).
Status legend: **[D]** discharged (constructed, not machine-checked),
**[D/trusted-base]** discharged modulo the regex/string primitives in the trusted
base, **[N/A-by-domain]** vacuous because the case is unreachable.

| ID | Obligation | Spec ref | Status |
|----|------------|----------|--------|
| **PO-1** | The issue example `… = 6.62607015e-34q_J * 1q_s` parses without error (both operands become UDLs; the multiplicative expression closes). | Intent, FINDING 8 | **[D]** |
| **PO-2** | **No regression on well-formed literals.** Every input that parsed to `ASTNumberLiteral/String/Char/Boolean/Pointer` before V1 still parses to the *same* node: integers `42`, suffixed ints `5u/5ul/5ull/5LL/5llu`, floats `1.0/1e10/0x1p0`, suffixed floats `1.0f/1.5L`, strings `"a"`, chars `'a'`, `true/false/nullptr`. | PC-ROUNDTRIP, PC-STDSUFFIX, CASE B/F/I/S/C | **[D/trusted-base]** |
| **PO-3** | **UDL recognition.** A literal immediately followed by an `udl_identifier_re` match (and, for numerics, no complete standard suffix) yields `ASTUserDefinedLiteral(literal, ident)` consuming exactly the literal+suffix. | CASE F2/I2/S/C, PC-ROUNDTRIP | **[D/trusted-base]** |
| **PO-4** | **Whitespace boundary.** No UDL is formed when whitespace separates the literal and a following identifier. | PC-NOWS, FINDING 2 | **[D]** |
| **PO-5** | **Boolean/pointer exclusion.** `true/false/nullptr` never acquire a ud-suffix; `true_x` etc. are not UDLs. | PC-NOBOOLUDL, FINDING 1 | **[D]** |
| **PO-6** | **Standard-suffix completeness.** For numeric literals, a standard suffix is consumed iff it is the complete trailing token; otherwise the trailing identifier is the ud-suffix (`1ull`→number, `1u_s`→UDL, `1q_s`→UDL). | PC-STDSUFFIX, LEM-\b, FINDING 3 | **[D/trusted-base]** |
| **PO-7** | **Round-trip.** `RESULT ≠ None ⇒ str(RESULT) == D[P0:P1]` on well-formed input; in particular `str(UDL)=str(literal)+str(ident)`. | STR, PC-ROUNDTRIP | **[D]** |
| **PO-8** | **`get_id` well-formed, deterministic, injective, collision-free**, and a faithful Itanium mangling of `operator"" suffix(literal)`. | ID, ID-DET, ID-INJ, ID-NOCLASH, FINDING 6 | **[D]** |
| **PO-9** | **`get_id` domain.** UDL `get_id` is only invoked with version ≥ 3 (template-arg / array contexts emit `str` for v1–v2); the v1/v2 path uses the string form. Hence no `NoOldIdError` guard is required, and omitting it is correct. | ID-DOMAIN, FINDING 5 | **[N/A-by-domain]** |
| **PO-10** | **`describe_signature` total + xref-clean.** Renders `str(literal)+str(ident)` as text, never a `pending_xref` for the suffix; `'udl'` is a legal description mode. | DESC, FINDING 7 | **[D]** |
| **PO-11** | **Totality / no new exceptions.** `_parse_literal` raises only via the pre-existing `self.fail(...)` on an undecodable character literal; the UDL path (`_udl`, `ASTUserDefinedLiteral.__init__`) cannot raise (`ASTIdentifier` asserts non-empty, and `udl_identifier_re` guarantees ≥ 1 char). | PC-TOTAL | **[D]** |
| **PO-12** | **Progress/quiescence.** `RESULT ≠ None ⇒ P1 > P0`; `RESULT = None ⇒ P1 = P0` (no cursor movement when the text is not a literal, so the caller's fall-through to `this`/paren/name parsing sees an unmoved cursor). | PC-PROGRESS | **[D]** |
| **PO-13** | **Scope.** The C domain `c.py` is unchanged; UDLs are a C++-only addition. | FINDING 11 | **[D]** |
| **PO-14** | **Termination.** `_parse_literal` terminates: the `for` loop is over a fixed 4-element list, `_udl` calls one non-looping `match`, and there is no recursion. (Total, not merely partial, correctness — trivially, since there is no data-dependent loop.) | §3 framing | **[D]** |

## Soundness side conditions (the parser analogue of the loop side condition)

- **SC-ORDER.** Float is tried *before* the integer family, and within the family
  the order is `binary, hex, integer, octal`. The proof of PO-2/PO-6 depends on this
  order (e.g. `0x1` must reach `hex` not `integer`; `0` must reach `octal`). V1
  preserves the original ordering (float-first; binary/hex before the decimal and
  octal fallbacks). ✔
- **SC-POS.** `pos` is captured once after `skip_ws`/keyword checks and before the
  float match, and `match` advances the cursor *only on success*. Therefore in CASE
  I the slice `D[pos:self.pos]` still starts at the literal's first char even though
  the float match was attempted first (it failed ⇒ left `pos` untouched). This is
  the one place an off-by-one could hide; PROOF.md PO-2 checks it explicitly.
- **SC-FAIL-RAISES.** `BaseParser.fail` raises unconditionally; this is what makes
  the `charLit` variable bound at `return _udl(charLit)` in CASE C (PO-11).
