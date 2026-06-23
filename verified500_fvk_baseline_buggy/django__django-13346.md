# django__django-13346

## Summary

**Severity:** Medium — baseline's JSON `__in` lookup compiles incorrectly on Oracle for
two realistic shapes (large literal lists, single-quote strings), but both arms passed the
official evaluation and the worst-case silent-wrong claim is unproven, so it rates Medium.

Baseline and FVK both passed the official SWE-bench evaluation for django__django-13346 with
**different** patches. Baseline added a backend-aware RHS converter for `JSONField`
key-transform `__in`; FVK kept that converter but, by formalizing the fix as a contract over
the *whole* compiled `IN` clause, found two Oracle-specific gaps the baseline left open — a
list-splitter that counts the wrong thing and an unescaped SQL string literal. The defect was
located by reasoning over the compilation shape, not by a new failing test.

| Arm | JSON `__in` on Oracle (compilation shape) | Resolved |
|---|---|---|
| baseline | official eval **passed**; Oracle `__in` splitting + string quoting left incorrect | partial |
| gold (human oracle) | not available in this run (non-curated) | — |
| **fvk** | official eval **passed**; Oracle splitter + quote-safe literal added | yes |

## 1. The issue and the real defect

The task (problem statement reproduced in
[`prompts/fvk.md`](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13346/prompts/fvk.md#L2))
is Django issue *"`__in` lookup doesn't work on key transforms"*: on MySQL, Oracle, and
SQLite, a `JSONField` key-transform filter such as `our_field__key__in=[0]` returns no rows
while the equivalent exact filter `our_field__key=0` returns the expected rows
([`PUBLIC_EVIDENCE_LEDGER.md` E1](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13346/fvk/PUBLIC_EVIDENCE_LEDGER.md#L9)).

The root cause is in `django/db/models/fields/json.py`: key transforms extract a typed JSON
value on the LHS, but the inherited generic `__in` lookup prepares the RHS list as plain
JSON-encoded parameters, so the two sides are never in the same comparison domain. The
existing `KeyTransformExact` lookup already wraps the RHS per backend (`JSON_EXTRACT` on
MySQL/SQLite, `JSON_VALUE`/`JSON_QUERY` on Oracle), but `__in` had no such wrapper
([`PUBLIC_EVIDENCE_LEDGER.md` E5](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13346/fvk/PUBLIC_EVIDENCE_LEDGER.md#L47)).
The public hints pin two boundaries that matter below: the failure occurs *specifically with
single-element lists*, and *Oracle additionally fails when the list contains strings*
([`PUBLIC_EVIDENCE_LEDGER.md` E4](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13346/fvk/PUBLIC_EVIDENCE_LEDGER.md#L39)).

## 2. Baseline's fix — and where it stopped

[Baseline](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13346/solutions/solution_baseline.patch#L9)
added a `KeyTransformIn(lookups.In)` lookup and registered it on `KeyTransform`. It overrides
`resolve_expression_parameter()` to adapt each direct literal RHS element per backend, mirroring
the exact-lookup wrappers. For Oracle it parses the value, picks `JSON_QUERY`/`JSON_VALUE`,
inlines the literal directly into the SQL fragment, and sets
[`params = []`](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13346/solutions/solution_baseline.patch#L25).

This was a reasonable, well-scoped choice — and the baseline explicitly believed it had kept the
generic list machinery intact:

> *"I also considered duplicating `KeyTransformExact.process_rhs()` at the whole-RHS level, but
> adapting each iterable parameter via `resolve_expression_parameter()` is more targeted and
> **preserves existing `IN` list handling such as parameter splitting**."*
> — [`reports/baseline_notes.md`](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13346/reports/baseline_notes.md#L27)

That belief is exactly where it stopped one step short. On Oracle the per-element adaptation
*inlines* the literal and emits **zero bind params**, so the inherited splitter — which it
claimed to preserve — no longer has anything to count. The unmet obligation is the splitter's
contract for the Oracle zero-param shape (PO6) plus quote-safety of the inlined string literal
(PO5), neither of which the per-element hook addresses.

## 3. How FVK formally captured the gap

FVK did not re-derive the bug from a symptom; it lifted the issue into a contract over the
compiled `IN` clause and then audited each obligation against the source. The intent spec puts
both gap-bearing cases explicitly in scope:

> **I5.** *Oracle string RHS values are in scope. The public issue explicitly says Oracle fails
> when the list contains strings.* … **I7.** *SQL generated for literal string values must
> remain a valid SQL literal … required for "strings" as a family, not only strings without
> quotes.*
> — [`INTENT_SPEC.md` I5/I7](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13346/fvk/INTENT_SPEC.md#L15)

The evidence ledger pins those intents to a concrete code fact found by source audit of the
generic lookup — **not** to the reported test:

> **E6 — Generic `In` list mechanics.** *generic `In.process_rhs()` removes `None`, calls
> `batch_process_rhs()`, and `split_parameter_list_as_sql()` chunks by backend max list size.*
> — [`PUBLIC_EVIDENCE_LEDGER.md` E6](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13346/fvk/PUBLIC_EVIDENCE_LEDGER.md#L59)

Reading the baseline's Oracle branch against E6 is what exposes the mismatch: the inherited
splitter chunks by *parameter count*, but the Oracle adaptation produces *fragments and zero
parameters*. That contradiction is discharged into two obligations:

> **PO6 — Oracle max-list split with inline RHS fragments.** *If Oracle RHS adaptation returns
> `N` inline SQL fragments and zero RHS bind params, and `N > max_in_list_size()`, splitting
> must iterate over `N` fragments, not zero params.*
> — [`PROOF_OBLIGATIONS.md` PO6](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13346/fvk/PROOF_OBLIGATIONS.md#L45)

> **PO5 — Oracle quote-safe string literals.** *For every Oracle scalar/string value `V`, the
> SQL literal passed to `JSON_VALUE`/`JSON_QUERY` must double SQL single quotes after JSON
> serialization.*
> — [`PROOF_OBLIGATIONS.md` PO5](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13346/fvk/PROOF_OBLIGATIONS.md#L37)

This is the crux: **both gaps were located by reasoning about the compiled-SQL shape**
(fragment count vs. param count; single-quote safety of an inlined literal), not by observing a
failing run. The reported test never exercises a list longer than `max_in_list_size()` or a
string with an apostrophe.

## 4. From formal output to the fix

The audit of the baseline (V1) against the obligations produced two findings, each tracing
forward to a concrete V2 edit:

- **F1 — splitter counts the wrong thing.**

  > *`KeyTransformIn.resolve_expression_parameter()` inlined every Oracle RHS literal … and
  > returned no RHS params. Generic `split_parameter_list_as_sql()` then iterated
  > `range(0, len(rhs_params), max_in_list_size)`, so `len(rhs_params) == 0` produced no `IN`
  > chunks.*
  > — [`FINDINGS.md` F1](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13346/fvk/FINDINGS.md#L5)

- **F2 — string literal not quote-safe.**

  > *the Oracle RHS helper constructed a SQL string literal directly from
  > `json.dumps({'value': value})`. A single quote inside the JSON string was not escaped for
  > the surrounding SQL literal.*
  > — [`FINDINGS.md` F2](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13346/fvk/FINDINGS.md#L19)

The iteration guidance turned each finding-plus-obligation into a specific V2 change:

> *1. Fix Oracle large-list splitting … Trace: F1, PO6, PO7. … 2. Make Oracle inline JSON
> literals quote-safe. Trace: F2, PO5.*
> — [`ITERATION_GUIDANCE.md`](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13346/fvk/ITERATION_GUIDANCE.md#L7)

The decision log records the resulting code and its provenance:

> *2. Added an Oracle-specific `KeyTransformIn.split_parameter_list_as_sql()` branch. … The
> inherited splitter chunks by `len(rhs_params)`, which becomes zero and cannot cover large RHS
> lists. The V2 branch chunks by RHS SQL fragment count only for Oracle's zero-param inline
> case.*
> — [`reports/fvk_notes.md`](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13346/reports/fvk_notes.md#L11)

The two edits land in the FVK patch as: a new
[`split_parameter_list_as_sql()`](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13346/solutions/solution_fvk.patch#L30)
Oracle branch that loops
[`for offset in range(0, len(rhs), max_in_list_size)`](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13346/solutions/solution_fvk.patch#L40)
(fragment count, not param count), and a centralized
[`_json_value_literal()`](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13346/solutions/solution_fvk.patch#L9)
helper (`json.dumps(...).replace("'", "''")`) now shared by both `KeyTransformExact` and
`KeyTransformIn`.

The causal chain is on the record:

```
E1/E2 (issue: __in must match exact)
  -> E6 (code audit: generic splitter chunks by param count)
  -> I5/I7 (intent: Oracle strings + quote-safety in scope)
  -> F1  -> PO6/PO7  -> split_parameter_list_as_sql() Oracle branch
  -> F2  -> PO5      -> _json_value_literal() shared helper
```

The V1 → V2 transition was driven by the **formal completeness audit**, not by a new failing
test: the prompt explicitly forbids tests, test results, and execution
([`prompts/fvk.md`](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13346/prompts/fvk.md#L2)),
so the obligations are the only thing that could have surfaced these two cases.

## 5. Verification

**Tier 3 — source-and-artifact reviewed; not executed.** This run is non-curated: there is no
`_materials/` directory, no gold patch, and no harness RED/GREEN proof reports. What was
inspected here:

- both patches as text
  ([baseline](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13346/solutions/solution_baseline.patch),
  [fvk](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13346/solutions/solution_fvk.patch)),
  confirming the FVK patch is the baseline plus exactly the two Oracle edits;
- the obligation-to-finding-to-edit trace across the FVK artifacts (§3, §4 links);
- the constructed proof's PO6 splitter argument
  ([`PROOF.md` PO6](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13346/fvk/PROOF.md#L36)).

The official SWE-bench evaluation marked **both** arms resolved
([result tree](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13346/)),
which is consistent with the FVK reading: the two residual gaps are Oracle-only and outside the
hidden test's coverage, so they do not change the official verdict.

The previous evidence doc stated the demonstrated defect "fails at database execution time."
That is a **reasoned, source-level** observation about the compiled SQL (a zero-param `IN`
chunking that drops RHS values; an unescaped `'` breaking the Oracle string literal), **not an
executed harness run** — no Oracle database was run in this environment, and the FVK artifacts
say so explicitly ([no-exec constraint, PROOF.md](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13346/fvk/PROOF.md#L58)).
The stronger silent-wrong-semantics claim (a query that runs but returns wrong rows) is **not
proven**; for the large-list case the most defensible reading is a malformed/empty `IN` clause.

## 6. Boundaries & honesty

- **Severity: Medium.** On a real supported backend (Oracle), `__in` compilation is incorrect
  for two non-exotic shapes — lists exceeding `max_in_list_size()` and strings containing a
  single quote. The rating rests on this **visible incorrect-compilation** behavior, not on
  silent result corruption: the worst-case silent-wrong-semantics claim is unproven, which is
  what keeps it out of High. It is above Low because the trigger shapes (long `__in` lists,
  apostrophe strings) are realistic in production ORM use, not edge curiosities.
- **Proof status: constructed, not machine-checked.** The K core
  ([`mini-django-json-lookup.k`](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13346/fvk/mini-django-json-lookup.k),
  [`json-key-transform-in-spec.k`](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13346/fvk/json-key-transform-in-spec.k))
  and the `kompile`/`kprove` commands were **written but never run** — the artifacts label
  themselves "constructed, not machine-checked" and record the unexecuted commands
  ([`PROOF.md`](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13346/fvk/PROOF.md#L3)).
  The claim is therefore **proof-structured reasoning** (a contract with obligations discharged
  by construction), not a verified proof.
- **Attribution.** The artifacts use a hybrid schema: `fvk/SPEC.md` restates the intent ledger,
  the contract, and the obligations that the split files
  ([`INTENT_SPEC.md`](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13346/fvk/INTENT_SPEC.md),
  [`PUBLIC_EVIDENCE_LEDGER.md`](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13346/fvk/PUBLIC_EVIDENCE_LEDGER.md),
  [`PROOF_OBLIGATIONS.md`](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13346/fvk/PROOF_OBLIGATIONS.md))
  carry independently, so some material is duplicated; quotes above are taken from whichever
  file is canonical for that item. There is no gold patch in this run, so the gold-comparison is
  prose-only: the upstream Django fix is known to add an Oracle splitter override of the same
  kind, but it is not linked here.

## Artifact map

| Claim | Source |
|---|---|
| Issue text / repro | [`PUBLIC_EVIDENCE_LEDGER.md` E1](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13346/fvk/PUBLIC_EVIDENCE_LEDGER.md#L9) |
| Problem statement (prompt) | [`prompts/fvk.md`](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13346/prompts/fvk.md#L2) |
| Exact-lookup parity pattern (E5) | [`PUBLIC_EVIDENCE_LEDGER.md` E5](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13346/fvk/PUBLIC_EVIDENCE_LEDGER.md#L47) |
| Oracle strings boundary (E4) | [`PUBLIC_EVIDENCE_LEDGER.md` E4](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13346/fvk/PUBLIC_EVIDENCE_LEDGER.md#L39) |
| Generic `In` list mechanics (E6) | [`PUBLIC_EVIDENCE_LEDGER.md` E6](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13346/fvk/PUBLIC_EVIDENCE_LEDGER.md#L59) |
| Intent I5/I7 (Oracle strings, quote-safety) | [`INTENT_SPEC.md`](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13346/fvk/INTENT_SPEC.md#L15) |
| Baseline patch | [`solutions/solution_baseline.patch`](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13346/solutions/solution_baseline.patch#L9) |
| Baseline "preserves splitting" reasoning | [`reports/baseline_notes.md`](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13346/reports/baseline_notes.md#L27) |
| Obligation PO5 (quote-safe literal) | [`PROOF_OBLIGATIONS.md` PO5](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13346/fvk/PROOF_OBLIGATIONS.md#L37) |
| Obligation PO6 (Oracle split) | [`PROOF_OBLIGATIONS.md` PO6](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13346/fvk/PROOF_OBLIGATIONS.md#L45) |
| Finding F1 (splitter) | [`FINDINGS.md` F1](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13346/fvk/FINDINGS.md#L5) |
| Finding F2 (string literal) | [`FINDINGS.md` F2](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13346/fvk/FINDINGS.md#L19) |
| Iteration guidance (V1→V2) | [`ITERATION_GUIDANCE.md`](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13346/fvk/ITERATION_GUIDANCE.md#L7) |
| Decision trace | [`reports/fvk_notes.md`](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13346/reports/fvk_notes.md#L11) |
| FVK patch (splitter + helper) | [`solutions/solution_fvk.patch`](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13346/solutions/solution_fvk.patch#L30) |
| Constructed proof (PO6 invariant) | [`PROOF.md` PO6](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13346/fvk/PROOF.md#L36) |
| Proof status + unrun commands | [`PROOF.md`](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13346/fvk/PROOF.md#L58) |
| Constructed K core | [`mini-django-json-lookup.k`](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13346/fvk/mini-django-json-lookup.k), [`json-key-transform-in-spec.k`](../results/verified011-codex-XC-MINI-PRO-AHP-20260615T225846Z/django__django-13346/fvk/json-key-transform-in-spec.k) |
</content>
</invoke>
