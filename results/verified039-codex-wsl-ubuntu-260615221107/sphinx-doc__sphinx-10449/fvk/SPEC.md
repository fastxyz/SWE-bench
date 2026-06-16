# FVK Spec

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Scope

The audited unit is the autodoc type-hint handoff implemented by
`repo/sphinx/ext/autodoc/typehints.py`:

- `record_typehints(app, objtype, name, obj, options, args, retann)` records
  type annotations in `app.env.temp_data['annotations'][name]`.
- `merge_typehints(app, domain, objtype, contentnode)` later injects field-list
  entries such as parameter types and `rtype` from the recorded annotations.

The observable under audit is whether an `autoclass` description rendered with
`autodoc_typehints = "description"` receives a class-level `Return type` field
from a constructor annotation like `__init__(...) -> None`.

## Intent Specification

1. **No class-level return type from constructor return annotations.**
   Public issue evidence: "`autodoc_typehints = "description"` causes
   autoclass to put a return type" and "I expected there to be no return type
   listed for the class." Semantic obligation: for object descriptions whose
   documented object type is `class`, constructor return annotations must not
   produce a class-body `rtype` field.

2. **Constructor parameter type information may still be recorded.**
   Public issue evidence: the complaint is specifically about the class's
   "return type"; it does not ask to remove constructor parameter types.
   Semantic obligation: the fix must not discard parameter annotations for
   `autoclass`.

3. **Function and method return-type behavior is preserved.**
   Public docs evidence: `autodoc_typehints = "description"` says type hints
   are shown as content of "the function or method"; public tests also cover
   function and method `Return type` output. Semantic obligation: the class fix
   must not suppress `rtype` insertion for functions and methods.

4. **Exception descriptions are class-like.**
   Public docs evidence: `py:exception` "Describes an exception class";
   implementation evidence: `ExceptionDocumenter` inherits `ClassDocumenter`.
   Semantic obligation: `autoexception` should not acquire a constructor
   return type as a documented return value either.

5. **Legacy class-return tests are suspect evidence.**
   Public tests in `repo/tests/test_ext_autodoc_configs.py` expect a
   class-level `Return type: None` for `_ClassWithDocumentedInit`, but that is
   the same behavior the issue reports as wrong. Under FVK intent-evidence
   rules, those tests are SUSPECT and cannot veto the public issue intent.

## Public Evidence Ledger

| ID | Source | Evidence | Obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "autoclass to include the class's 'return type'" | Class descriptions must not list constructor return type. | Encoded by PO1 |
| E2 | prompt | "no return type listed for the class" | No `rtype` field for `objtype == 'class'`. | Encoded by PO1 |
| E3 | docs | description mode shows typehints as content of "the function or method" | Preserve function/method return fields. | Encoded by PO3 |
| E4 | docs/code | exception directive describes an exception class; `ExceptionDocumenter` subclasses `ClassDocumenter` | Treat exceptions as class-like for constructor return fields. | Encoded by PO2 |
| E5 | public-test | class-level `Return type: None` expected for `_ClassWithDocumentedInit` | SUSPECT legacy behavior conflicting with E1/E2. | Recorded in F1 |

## Formal Specification English

The constructed formal core is in `fvk/mini-autodoc-typehints.k` and
`fvk/autodoc-typehints-spec.k`.

PO1, paraphrased: starting from an empty annotation table, recording type hints
for a `class` object with annotated constructor parameters and a return
annotation records the parameter annotations but does not record a `"return"`
annotation. Therefore a later merge has no recorded return annotation from
which to create an `rtype` field.

PO2, paraphrased: the same no-recorded-return property holds for `exception`
object descriptions.

PO3, paraphrased: recording type hints for a `function` with a return
annotation still records `"return"`, preserving function/method description
mode behavior.

## Spec Audit

PO1 passes against E1/E2 and is not candidate-derived: it states the public
expected behavior directly.

PO2 passes against E4. It slightly generalizes the issue from classes to
exception classes, but public docs and implementation hierarchy support that
generalization.

PO3 passes against E3 and is a required frame condition. It prevents an
overbroad fix that would suppress return types everywhere.

E5 is marked SUSPECT because it encodes the reported bug. It is useful evidence
of the old behavior but not a correctness obligation.

## Public Compatibility Audit

No public function signatures, event signatures, directive options, or return
types were changed. The edited code only changes which key is recorded in the
internal `env.temp_data['annotations']` map for `class` and `exception` events.

Public callsites of `record_typehints` are event-driven; the function remains
registered on `autodoc-process-signature` with the same parameters. User event
handlers are not called differently. `merge_typehints` continues to consume the
same annotation dictionary shape and remains unchanged.

## Machine-Check Commands

These commands are emitted for later checking only; they were not run.

```sh
kompile fvk/mini-autodoc-typehints.k --backend haskell
kast --backend haskell fvk/autodoc-typehints-spec.k
kprove fvk/autodoc-typehints-spec.k
```
