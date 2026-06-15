# FVK Findings

Status: constructed, not machine-checked. Findings use only public issue text,
source code, public in-repo tests/calls, and the V1 code.

## F1 - Original TypeError Path Is Removed

- Classification: code bug fixed by V1.
- Input: installed version `1.14.3`, required version `1.14dev`,
  `inclusive=True`.
- V0 observed behavior: direct `LooseVersion("1.14.3") >=
  LooseVersion("1.14dev")` can compare integer component `3` against string
  component `dev`, raising `TypeError`.
- Expected behavior from public intent: return `True`; the public issue shows
  `pkg_resources.parse_version("1.14.3") >= parse_version("1.14dev")` as
  working and the hint asks to restore regex normalization around
  `LooseVersion`.
- V1 audit result: `_version_to_looseversion("1.14dev")` strips the suffix to
  `1.14`, so the comparison is numeric-list-only and the modeled result is
  `True`.
- Linked obligations: PO1, PO2, PO3.

## F2 - Public API Compatibility Is Preserved

- Classification: compatibility confirmation.
- Input/callsites: public calls to `minversion(module_or_name, version,
  inclusive=True, version_path="__version__")`.
- V1 observed behavior: the function signature is unchanged; the helper is
  private; missing import and invalid module branches are unchanged.
- Expected behavior: public callsites should not need updates for the fix.
- V1 audit result: no production source change is required beyond V1.
- Linked obligations: PO4, PO5.

## F3 - Residual Scope: Full PEP 440 Semantics Are Not Proven

- Classification: underspecified intent / proof scope.
- Input: version strings outside the numeric-prefix domain, or cases requiring
  complete PEP 440 equivalence rather than regex-normalized `LooseVersion`.
- Observed V1 behavior: nonnumeric-leading strings are passed through to
  `LooseVersion`; numeric-leading strings are compared by their leading numeric
  prefix only.
- Expected behavior from public intent: the issue asks specifically for the
  `LooseVersion` regex guard and rejects returning to `pkg_resources`, so full
  PEP 440 behavior is not an obligation for this task.
- V1 audit result: record the boundary but do not change the source.
- Linked obligations: PO1, PO6.

## Proof-Derived Findings

No proof obligation failed inside the stated domain. The constructed proof
requires the domain precondition "both versions have a leading numeric release
prefix"; this is justified by the public issue, docstring example, and in-repo
callsites. It remains an explicit residual boundary rather than a hidden
assumption.

