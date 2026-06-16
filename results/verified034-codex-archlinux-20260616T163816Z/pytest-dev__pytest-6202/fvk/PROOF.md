# FVK Proof

Status: constructed, not machine-checked. No tests, Python code, or K tooling were executed.

## Adequacy Gate

The intent spec requires literal preservation of parametrized ids in report headlines. The formal obligations in `PROOF_OBLIGATIONS.md` state exactly that `getmodpath()` returns the joined projection of node-name parts, with no global `".["` normalization, and that the report headline propagates the resulting string.

Adequacy result: pass.

No formal obligation is derived solely from V1. The expected reproducer value `test_boo[..[]` comes from the public issue, and the rejected value `test_boo[.[]` is the reported bug.

## Proof of O-01: Exact modpath assembly

The patched method traverses the node chain and fills `parts`. The loop body and all branch conditions are unchanged from the pre-existing implementation; V1 changes only the final expression after `s = ".".join(parts)`.

After the loop:

1. `parts` is in display order because the implementation calls `parts.reverse()`.
2. `s` is exactly `".".join(parts)`.
3. V1 returns `s`.

Therefore the returned value is `join(project(chain, stopatmodule, includemodule))`.

For the issue reproducer, the selected display part is the single function name `test_boo[..[]`. Joining a one-element list returns that same string, so the result is `test_boo[..[]`.

The pre-V1 implementation instead evaluated:

```text
"test_boo[..[]".replace(".[", "[") = "test_boo[.[]"
```

This constructs the reported failure and shows that V1 removes the mechanism that produced it.

## Proof of O-02: Frame Conditions

V1 leaves every statement before the final return unchanged. The following behavior is therefore framed from the original implementation:

- `Instance` filtering.
- `Module` stem extraction.
- `stopatmodule` and `includemodule`.
- traversal direction and final display-order reversal.
- `"."` as the path-part separator.

The proof does not rely on hidden tests or legacy output. It relies on source equality outside the one edited expression.

## Proof of O-03: Headline Propagation

Let `M` be the value returned by `getmodpath()`.

`reportinfo()` assigns `modpath = self.getmodpath()` and returns `(fspath, lineno, modpath)`, so tuple element 3 is `M`.

`Node.location` reads `location = self.reportinfo()` and then stores `(fspath, location[1], str(location[2]))`. Since `M` is already a string, `str(M) = M`.

`TestReport.head_line` reads `fspath, lineno, domain = self.location` and returns `domain`, so it returns `M`.

The terminal reporter uses `rep.head_line` for the failure headline when present. Thus the long failure headline receives the exact string returned by `getmodpath()`.

Combined with O-01, the issue reproducer headline domain is `test_boo[..[]`.

## Proof of O-04: Compatibility

The old replacement can only be justified by the historical generated-yield child display case named in the public hint. Current source handles generator functions by warning that yield tests were removed in pytest 4.0 and marking the generated `Function` xfail/run=False, rather than collecting yielded child cases with names like `[0]`.

Therefore no active in-domain requirement forces `test_gen.[0]` to be displayed as `test_gen[0]`. Retaining that rewrite would preserve obsolete behavior while violating I-01 for current parametrized ids.

## Residual Risk

This is a partial-correctness proof over a source-level abstraction of the relevant string transformation and report propagation. It does not machine-check the full Python implementation and does not prove unrelated pytest reporting behavior.

The main trusted base is that the abstract `project()` definition in `SPEC.md` faithfully describes the unchanged loop in `getmodpath()`, and that the inspected propagation path is the one used for the reported long failure headline.

## Test Recommendation

No tests should be removed. The proof is constructed, not machine-checked, and the task forbids modifying tests.

Recommended future coverage is listed in Finding F-05.
