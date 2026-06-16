# Iteration Guidance

## Decision

V1 stands unchanged. The FVK audit found the original defect, proved the intended
separator-domain widening over the modeled path, and did not surface a failing
proof obligation that justifies further source edits.

## Why No V2 Source Edit

- F-01 is addressed by PO-02: custom strings no longer go through a failing
  legacy-table lookup.
- F-02 is addressed by PO-01 and PO-03: legacy aliases and default numeric
  behavior are preserved.
- F-03 is addressed by PO-02 and PO-04: custom strings are complete separators,
  matching the public hint.
- F-04 is addressed by PO-03 and PO-05: `mul_symbol=None` still uses `\cdot` for
  numeric scientific notation.
- F-05 is addressed by PO-07: no public signature or callsite protocol changed.

## Recommended Follow-Up Tests

Do not edit tests in this benchmark session. In a normal development run, add or
keep point tests for:

- custom thin-space separator: `mul_symbol=r"\,"`;
- caller-padded custom separator: `mul_symbol=r" \, "`;
- legacy aliases and `None`;
- scientific notation using both default and custom separators;
- polynomial element printing with a custom separator.

## Open Questions

No blocking intent ambiguity remains. The only noted choice is spacing around a
custom LaTeX separator. Public hint E-03 resolves it: the custom value is used
literally, so padding is caller-controlled.

## Commands For A Future Verification Environment

```sh
kompile fvk/mini-latex-mul-symbol.k --backend haskell
kast --backend haskell fvk/latex-mul-symbol-spec.k
kprove fvk/latex-mul-symbol-spec.k
```

These commands were not run here.
