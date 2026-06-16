# FVK Findings

Status: constructed, not machine-checked. Findings are derived from public
intent, source inspection, and proof-obligation construction; no tests or code
were run.

## F1: V1 fixes the reported class-level return-type leak

Input: an `autoclass` target such as `sample_package.Square` whose constructor
has annotated parameters and `__init__(...) -> None`, with
`autodoc_typehints = "description"`.

Observed before V1: `record_typehints()` could store a `"return"` annotation
for the class name; `merge_typehints()` then injected `:rtype: None`, producing
a class-level "Return type" field.

Expected from public intent: no return type listed for the class.

V1 status: fixed. The guard in `record_typehints()` prevents a `"return"`
annotation from being recorded when `objtype` is `class`, so the later merge has
no class return annotation to render.

Linked obligations: PO1, PO4.

## F2: Legacy class-return public tests are suspect, not authoritative

Input: existing public tests around `_ClassWithDocumentedInit` expect the class
body to include `Return type: None` under `autodoc_typehints = "description"`.

Observed evidence conflict: those expectations match the behavior reported as
the bug: a class description gets a return type from its constructor.

Expected from public intent: no class-level return type.

V1 status: the fix intentionally does not preserve that legacy expectation.
Under the FVK intent-evidence rules, the tests are SUSPECT because they encode
the reported bug.

Linked obligations: PO1 and the SUSPECT entry E5 in `SPEC.md`.

## F3: Function and method return-type behavior remains preserved

Input: an autodocumented function or method with a return annotation, with
`autodoc_typehints` set to `description` or `both`.

Observed in V1: the new guard excludes only `class` and `exception`; function
and method object types still record `"return"` when a return annotation exists.

Expected from public docs: description mode still documents type hints as
content for functions and methods.

V1 status: preserved. No further source change is needed.

Linked obligation: PO3.

## F4: Exception descriptions should follow the class-like rule

Input: an `autoexception` target whose constructor has a return annotation.

Observed risk before V1: `ExceptionDocumenter` inherits class signature
behavior, so the same return-type leak could appear for an exception class.

Expected from public docs and implementation shape: an exception is documented
as an exception class; constructor return annotations should not be presented as
the exception's return value.

V1 status: fixed by the same guard. This is a small class-like generalization,
not an unrelated behavior change.

Linked obligation: PO2.

## Residual Risk

The proof assumes the normal autodoc event path owns
`env.temp_data['annotations'][name]` for the object currently being documented.
If an external extension manually pre-populates a `"return"` entry for the same
class fullname before `merge_typehints()`, V1 does not erase that external
state. That is outside the public issue path and outside the internal frame
condition audited here.
