# FVK Iteration Guidance

Status: constructed, not machine-checked. No tests, Python code, or K tooling
were run.

## Source Decision

Keep V1 unchanged.

Rationale: Findings F-01 through F-03 and proof obligations PO-01 through PO-06
show that the V1 source change exactly targets the public `Y` obligation:

```python
return '%04d' % self.data.year
```

No proof obligation requires moving padding into `Formatter.format()`, changing
other format specifiers, or adding validation guards.

## Recommended Future Tests

Do not edit tests in this benchmark task. In a normal development pass, add or
keep tests equivalent to:

- `dateformat.format(date(1, 1, 1), "Y") == "0001"`
- `dateformat.format(date(42, 1, 1), "Y") == "0042"`
- `dateformat.format(date(999, 1, 1), "Y") == "0999"`
- `dateformat.format(date(1000, 1, 1), "Y") == "1000"`
- A direct `DateFormat(date(...)).Y()` assertion if Django treats formatter
  methods as public enough to test directly.

These tests are not redundant until the K artifacts are machine-checked.

## Follow-Up Questions

1. Should the ISO week-numbering year specifier `o` also be audited for
   zero-padding below 1000? This pass records it as Finding F-04 but does not
   change source because the public issue identifies `Y`.
2. Does Django intend direct calls to individual `DateFormat` specifier methods
   to have stable return types? V1 necessarily returns a string for `Y()` to
   satisfy the four-digit method-level contract.

## Commands For Future Verification

Do not run these commands in this benchmark session. In an environment with K:

```sh
cd fvk
kompile mini-dateformat.k --backend haskell
kast --backend haskell dateformat-y-spec.k
kprove dateformat-y-spec.k
```

Only after `kprove` returns `#Top` should any test-redundancy recommendation be
acted on.
