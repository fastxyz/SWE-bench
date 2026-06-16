# FVK Specification

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Target

The target is the `Axes.bar` failure path through
`repo/lib/matplotlib/axes/_axes.py::_convert_dx`.

Relevant source:

- `Axes.bar` converts x units and calls `_convert_dx` for `width` and `xerr`.
- `_convert_dx` chooses one representative from original coordinates `x0` and
  one representative from converted coordinates `xconv`.
- `_safe_first_finite` raises `StopIteration` when an iterable contains no
  finite/non-None value.
- V1 catches that `StopIteration` and falls back to `cbook.safe_first_element`
  for both `x0` and `xconv`.

## Public Intent Ledger

The standalone ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`. Critical entries:

- E-001/E-002/E-003: all-NaN bar input must not raise and must preserve
  nonfinite rectangle geometry.
- E-004: the x-position conversion path is the failing path.
- E-005: mixed leading-NaN inputs with later finite values must keep the
  first-finite representative behavior.
- E-006: the direct culprit is unhandled `StopIteration` from searching for the
  next finite value.
- E-008/E-009: empty converted x data follows the existing `convert(dx)` branch.
- E-010: conversion-error fallback remains unchanged.

## Contract

For `_convert_dx(dx, x0, xconv, convert)` on the audited domain:

1. If `xconv` is empty, return `convert(dx)` exactly as before.

2. If `xconv` is non-empty and `x0`/`xconv` each contain at least one finite
   representative, use the first finite representative of each sequence.

3. If `xconv` is non-empty and either representative search has no finite
   element, use the first unfiltered element of that same sequence instead of
   letting `StopIteration` escape.

4. Convert each `dx` by applying the existing add/convert/subtract calculation
   to the selected representatives. Scalar `dx` returns a scalar; iterable `dx`
   returns an iterable-shaped result.

5. If that add/convert/subtract calculation raises `ValueError`, `TypeError`, or
   `AttributeError`, keep the existing `convert(dx)` fallback.

6. The function signature, caller protocol, and behavior of
   `cbook._safe_first_finite` outside this helper are unchanged.

## Formal Artifacts

- `fvk/mini-convert-dx.k`: a minimal K-style semantics for representative
  selection and width conversion shape.
- `fvk/convert-dx-spec.k`: claims for all-nonfinite fallback, the concrete
  reproduction, mixed leading-NaN preservation, and empty-`xconv` behavior.

The mini semantics abstracts real NumPy/Python values into `finite(I)` and
`nan`, and abstracts unit conversion into `delta(x0, x, dx)`. This abstraction
is property-complete for the audited defect because it distinguishes the two
observable behaviors that matter here: "representative selection raises
`StopIteration`" versus "representative selection returns a first element or
first finite element and conversion proceeds."

## Preconditions

- `xconv` is an ndarray-like converted coordinate sequence.
- For non-empty conversion, `x0` is non-empty whenever `xconv` is non-empty.
- The selected first element is not from a generator input; generator rejection
  remains the responsibility of `cbook.safe_first_element` /
  `_safe_first_finite`.

These are implementation and default-domain assumptions, not hidden-test
assumptions.
