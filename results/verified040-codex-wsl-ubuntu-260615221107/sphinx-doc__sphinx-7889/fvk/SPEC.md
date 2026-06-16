# FVK Spec

Status: constructed, not machine-checked.

## Scope

This FVK pass audits the V1 fix in `repo/sphinx/ext/autodoc/mock.py`, focused on
the issue-reported path:

`_MockObject.__getitem__(key)` -> `_make_subclass(key, display, cls)` -> display
name construction and `type(name, bases, attrs)`.

The observable property under verification is whether generic subscription on a
mock object can pass a non-string key, especially a `typing.TypeVar`, without
raising the issue-reported `TypeError` from `str + TypeVar`, while preserving
existing string-name mock display behavior.

## Intent Summary

The intent-only spec is recorded in `INTENT_SPEC.md`; the standalone evidence
ledger is recorded in `PUBLIC_EVIDENCE_LEDGER.md`.

Key obligations:

- Generic-typed classes are in domain for autodoc mock imports.
- `_make_subclass()` must normalize non-string generic parameters before string
  concatenation and class construction.
- Existing string attribute behavior remains dotted and backward compatible.
- The fix does not need to implement a full runtime generic alias model; the
  public issue requires that autodoc continue rather than crashing.

## Human-Readable Contract

For every in-domain `name`, `module`, and `superclass`:

1. `_make_subclass_name(name)` returns a Python `str`.
2. If `name` is already a string, `_make_subclass_name(name) == name`.
3. If `name` has a string `__name__`, `_make_subclass_name(name) == name.__name__`.
4. Otherwise, `_make_subclass_name(name) == repr(name)`, assuming ordinary
   Python `repr()` behavior.
5. `_make_subclass(name, module, superclass, attributes)` uses the normalized
   string name for `module + "." + name` and for the first argument to `type()`.
6. `_MockObject.__getitem__(key)` accepts arbitrary generic key objects in the
   in-domain set and delegates through the safe `_make_subclass()` path.

## Formal Core

The constructed semantics and claims are:

- `mini-python-mock.k`: a mini semantics that preserves the property axis under
  audit, namely whether subclass names are strings before concatenation.
- `autodoc-mock-spec.k`: K claims for TypeVar-like names, existing string names,
  generic normalized names, and `_MockObject.__getitem__`.

Exact commands to machine-check later are listed in `PROOF.md`; they were not
run in this session.

## Adequacy Gate

The formal-English paraphrase is in `FORMAL_SPEC_ENGLISH.md`; the claim-by-claim
audit is in `SPEC_AUDIT.md`.

Result: PASS. The formal claims cover the issue intent and do not over-preserve
the pre-fix `str + TypeVar` behavior. The claims intentionally avoid stronger
requirements not present in public evidence, such as bracketed generic display
syntax or full Python generic alias semantics.

## Public Compatibility

The compatibility audit is in `PUBLIC_COMPATIBILITY_AUDIT.md`.

Result: PASS. V1 preserves arity and return shape for the affected private and
semi-private mock helpers. The changed annotations widen accepted runtime values
to match Python subscription behavior and the public issue.
