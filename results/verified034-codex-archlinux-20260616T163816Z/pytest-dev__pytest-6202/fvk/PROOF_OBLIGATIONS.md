# FVK Proof Obligations

Status: constructed, not machine-checked. No K tooling was run.

The proof models the property at the abstraction level that matters for the bug: a list of display path parts is joined, and characters inside each part are preserved. This abstraction distinguishes the failing value `test_boo[.[]` from the passing value `test_boo[..[]`.

## O-01: Exact modpath assembly

Claim: for every collected Python node chain in scope,

`getmodpath(chain, stopatmodule, includemodule) = join(project(chain, stopatmodule, includemodule))`

where `project` is defined in `SPEC.md`.

Proven by V1 source shape:

```python
parts.reverse()
s = ".".join(parts)
return s
```

No later string rewrite is present.

FVK claim sketch:

```k
// SPEC-PROVENANCE:
// - from_prompt: reported headline must preserve "test_boo[..[]" => exact string preservation
// - from_code: getmodpath loop projects node names and joins with "."
// - conflicts: legacy replace(".[", "[") corrupts parametrized ids; see F-01
claim
  <k> getmodpath(CHAIN, STOPATMODULE, INCLUDEMODULE)
      => join(project(CHAIN, STOPATMODULE, INCLUDEMODULE)) </k>
  [all-path]
```

## O-02: Frame conditions for existing path structure

Claim: V1 preserves the existing structural rules for `getmodpath()`:

- `Instance` nodes are skipped.
- `Module` nodes use the file stem.
- `stopatmodule` stops traversal at the module.
- `includemodule` controls whether that module stem is included before stopping.
- selected parts are reversed into display order before joining.

Reasoning: V1 changes only the final return expression. The projection loop is byte-for-byte unchanged.

## O-03: Report headline propagation

Claim: if `getmodpath()` returns `M`, then the long failure headline receives `M` unchanged as its domain string.

Source path:

- `reportinfo()` stores `modpath = self.getmodpath()` and returns it as tuple element 3.
- `Node.location` stores `str(location[2])`.
- `TestReport.head_line` returns `domain` from `self.location`.
- Terminal failure headline uses `rep.head_line`.

FVK claim sketch:

```k
// SPEC-PROVENANCE:
// - from_prompt: issue traces headline through reportinfo/location/head_line
// - from_code: each consumer passes the third reportinfo tuple element through
claim
  <k> failureHeadline(reportFromModpath(M)) => M </k>
  requires isString(M)
  [all-path]
```

## O-04: Obsolete generated-yield formatting is outside the current intent domain

Claim: preserving `test_gen[0]` for historical generated-yield children is not a proof obligation for this checkout.

Justification:

- The public hint identifies that behavior as the old reason for the replacement.
- The same hint states yield tests were removed in pytest 4.0.
- Current source warns that yield tests were removed and marks generator functions xfail/run=False instead of collecting yielded child items.

This is a compatibility discharge, not a code-path proof. It blocks reintroducing a string-level special case.

## O-05: Negative obligation: no global `".["` normalization

Claim: for all strings `P` selected as node-name parts, `P` is not content-normalized before or after joining.

Concrete discriminator:

```text
P_pass = "test_boo[..[]"
legacy_normalize(P_pass) = "test_boo[.[]"
identity(P_pass) = "test_boo[..[]"
```

The expected output is independently anchored by the issue text, so this is not self-derived from V1.

## O-06: Constructed proof commands

The FVK method would normally emit and run K files. This task forbids K execution, so these commands are recorded only as the intended machine-check steps:

```sh
kompile fvk/mini-pytest-modpath.k --backend haskell
kast --backend haskell fvk/pytest-modpath-spec.k
kprove fvk/pytest-modpath-spec.k
```

Expected outcome after a real machine check: `#Top` for O-01 and O-03 style claims. In this session the outcome remains constructed, not machine-checked.
