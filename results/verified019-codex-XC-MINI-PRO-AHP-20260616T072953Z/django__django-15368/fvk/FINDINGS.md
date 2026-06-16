# FVK Findings

Status: constructed, not machine-checked. Findings are based on public intent, source inspection, and proof-obligation construction only.

## F-001: V1 Fixes the Reported Expression Literalization Bug

Classification: code bug in the pre-fix implementation; confirmed fixed by V1.

Input: a model object `o` whose updated field value is `F("name")`, passed to `bulk_update([o], ["c8"])`.

Observed pre-fix behavior from the issue: generated SQL used a literal parameter equivalent to `'F(name)'`, and the refreshed field value became the string `"F(name)"`.

Expected behavior: `F("name")` remains expression-like, reaches update resolution, and becomes a column reference to `name`.

Evidence: E1, E2, E3, E4. Proof obligations: PO-1, PO-2, PO-3.

Resolution: V1 changes `if not isinstance(attr, Expression)` to `if not hasattr(attr, "resolve_expression")`, so plain `F()` is no longer wrapped in `Value()`.

## F-002: No Additional Source Change Is Justified by the FVK Audit

Classification: confirmation of V1 against the scoped spec.

Input family: field values with `resolve_expression` and field values without `resolve_expression`.

Observed V1 behavior from source inspection: expression-like values pass through; non-expression values are wrapped in `Value()`.

Expected behavior: same as the formal contract.

Evidence: E4, E5, E6, E7. Proof obligations: PO-2, PO-3, PO-4, PO-5.

Resolution: V1 stands unchanged. A special-case `isinstance(attr, (Expression, F))` would satisfy the concrete witness but fail the broader public hint to use Django's expression protocol.

## F-003: Test Coverage Remains Necessary Until Machine Checking and Project Tests Are Run Elsewhere

Classification: test gap / honesty gate.

Input: any regression test for `bulk_update()` with a plain `F()` value.

Observed in this workspace: tests cannot be run and test files must not be modified.

Expected next validation: a public/project test should assert that `bulk_update()` with `F("name")` copies the referenced column value rather than storing `"F(name)"`.

Evidence: FVK verify honesty gate and the task's no-execution/no-test-edit constraints. Proof obligations: PO-7.

Resolution: no test files were changed. Keep tests; any test-removal recommendation is explicitly out of scope because the proof is constructed, not machine-checked.

## Proof-Derived Findings

No proof-derived code bug was found after the adequacy gate. The only residual proof caveat is the trusted-base boundary: the mini-semantics models the expression-classification and update-resolution property, not the full Django ORM or database backend.
