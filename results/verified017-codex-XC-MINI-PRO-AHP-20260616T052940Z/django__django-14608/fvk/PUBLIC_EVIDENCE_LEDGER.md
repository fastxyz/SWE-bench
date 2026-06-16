# Public Evidence Ledger

## E1

Source: prompt / issue.

Quoted evidence: "Add `nonform` CSS class for non form errors in FormSets".

Semantic obligation: every formset-level non-form `ErrorList` must carry the
additional `nonform` CSS class.

Status: encoded in SPEC.md, PROOF_OBLIGATIONS.md PO-1 and PO-2, and
`formset-nonform-spec.k`.

## E2

Source: prompt / issue.

Quoted evidence: "Forms add the nonfield CSS class for non field errors in
ErrorList instances."

Semantic obligation: formset behavior should use the same `ErrorList`
constructor channel as form non-field errors, substituting `nonform` for
`nonfield`.

Status: encoded in PO-1 and PO-2. The implementation uses
`self.error_class(..., error_class='nonform')`, matching the existing form
call sites that pass `error_class='nonfield'`.

## E3

Source: prompt / issue.

Quoted evidence: "This would allow a custom ErrorList to make a distinction in
form field errors, non field errors (forms) and non form errors (FormSets)".

Semantic obligation: the class signal must be available at `ErrorList`
construction time, not only hard-coded in default rendering after construction.

Status: encoded in PO-1, PO-2, and the K model's `extraClass` field.

## E4

Source: prompt / issue.

Quoted evidence: "document it for developers to use."

Semantic obligation: user-facing formset documentation must mention the
`nonform` CSS class.

Status: encoded in PO-5.

## E5

Source: source code / existing documented convention.

Quoted evidence: `Form.non_field_errors()` returns
`self.error_class(error_class='nonfield')` when there are no non-field errors,
and `Form.add_error()` initializes `NON_FIELD_ERRORS` with the same argument.

Semantic obligation: use the existing `ErrorList` extension point rather than
adding a formset-only rendering special case.

Status: supporting evidence for PO-1 and PO-2.

## E6

Source: public tests, suspect legacy evidence.

Quoted evidence: `repo/tests/admin_views/tests.py` compares
`str(non_form_errors)` to `str(ErrorList(["Grace is not a Zombie"]))`, which
renders without `nonform`.

Semantic obligation: none. This encodes the missing-class behavior reported by
the issue.

Status: recorded as FINDINGS.md F2, suspect legacy evidence that must not veto
the public issue intent.
