# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO1 - Intent-Derived Domain

For the version-comparison claims, both `have_version` and `version` are strings
with a leading numeric release prefix: one or more decimal integer components
separated by dots, followed optionally by a suffix such as `dev` or `rc1`.

Evidence: `fvk/SPEC.md` ledger entries I1, I4, I5, I7.

## PO2 - Regex Normalization

For every in-domain version string `v`, `_version_to_looseversion(v)` must pass
only the leading numeric release prefix of `v` to `LooseVersion`.

Evidence: public hint to restore the regex around `LooseVersion`; V1 code:
`_NUMERIC_VERSION_RE = re.compile(r'^\s*([0-9]+(?:\.[0-9]+)*)')`.

## PO3 - No Mixed-Type LooseVersion Comparison In Domain

After PO2, every component compared by `LooseVersion` for in-domain inputs is an
integer release component. Therefore the reported int-vs-string `TypeError`
path is unreachable in the modeled domain.

Evidence: issue traceback identifies the mixed `int`/`str` comparison as the
failure mechanism.

## PO4 - Inclusive and Exclusive Results Match Normalized Ordering

Inclusive mode returns normalized `>=`; exclusive mode returns normalized `>`.
The final boolean is exactly the result of comparing the installed numeric
release prefix with the required numeric release prefix under `LooseVersion`
numeric-list ordering.

Evidence: `minversion` docstring and existing control flow.

## PO5 - Non-Comparison Branches Are Framed

The V1 helper must not change public behavior for:

- module strings that cannot be imported: return `False`;
- invalid `module` argument types: raise `ValueError`;
- `version_path` lookup before comparison.

Evidence: docstring and unchanged source branches in `minversion`.

## PO6 - Compatibility Boundary Is Explicit

The proof must not claim complete PEP 440 behavior or arbitrary nonnumeric
version parsing. If such behavior is desired, it is a future spec expansion, not
part of this issue-derived proof.

Evidence: the issue asks for a `LooseVersion` regex guard and explicitly avoids
returning to `pkg_resources.parse_version`.

