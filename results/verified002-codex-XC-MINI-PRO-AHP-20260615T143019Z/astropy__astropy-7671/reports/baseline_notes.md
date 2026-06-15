# Baseline Notes

## Root cause

`astropy.utils.introspection.minversion` compared version strings directly with
`distutils.version.LooseVersion`. For versions like installed `1.14.3` against a
minimum requirement of `1.14dev`, `LooseVersion` tokenizes one side as a numeric
component and the other as a string component at the same position. On Python 3,
that internal list comparison raises `TypeError` instead of returning a boolean.

## Changed files

`repo/astropy/utils/introspection.py`

- Added a small regular-expression based normalization helper that extracts the
  leading numeric release segment from a version string before passing it to
  `LooseVersion`.
- Updated `minversion` to convert both the installed version and required
  version through that helper before applying the existing inclusive or
  exclusive comparison.

## Assumptions

- The intended minimum-version behavior for strings such as `1.14dev` is to use
  the numeric release floor `1.14`, so an installed patch release like `1.14.3`
  satisfies the requirement.
- The issue should be fixed without restoring `pkg_resources.parse_version`,
  matching the public hint that the earlier regular-expression guard around
  `LooseVersion` was the desired approach.
- Version strings without a leading numeric release segment are left to
  `LooseVersion`, since the reported failure and existing uses are numeric
  package versions.

## Alternatives considered

- Reintroducing `pkg_resources.parse_version` was rejected because the issue
  explicitly notes that it had been removed and the public hint says not to go
  back to it.
- Replacing `LooseVersion` with a new custom version comparator was rejected as
  a broader behavioral change than needed for this issue.
- Catching `TypeError` only around the comparison was rejected because it would
  leave closely related development-suffix cases dependent on `LooseVersion`
  behavior instead of consistently applying the intended numeric normalization.
