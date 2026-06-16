# PROOF

Status: constructed, not machine-checked. No tests, Python code, or K tooling
were run.

## Claim

For every imported migrations module in the issue-relevant domain, V1 classifies
the module according to the decision table in `fvk/SPEC.md`:

- regular package without `__file__` and with list `__path__` -> `scan`;
- namespace package without `__file__` and with non-list `__path__` ->
  `unmigrated`;
- non-package module without a usable `__path__` -> `unmigrated`;
- normal package with `__file__` and list `__path__` -> `scan`.

## Symbolic Execution

Let:

- `F` be the truth of `getattr(module, '__file__', None) is None`;
- `L` be the truth of `isinstance(getattr(module, '__path__', None), list)`;
- `H` be the truth of `hasattr(module, '__path__')`.

V1 executes the first guard when `F and not L`. If that guard is skipped, V1
executes the second guard when `not H`. If both guards are skipped, V1 scans.

### PO-001

State: `F = true`, `L = true`, `H = true`.

The first guard is `true and false`, so it is skipped. The second guard is
`false`, so it is skipped. The scan path is reached. This proves F-001.

### PO-002

State: `F = true`, `L = false`, `H = true`.

The first guard is `true and true`, so the app is marked unmigrated and the
loader continues. This proves F-002.

### PO-003

State: `F = true`, `L = false`, `H = false`.

The first guard is `true and true`, because absent `__path__` is not a list.
The app is marked unmigrated before the second guard. This proves the
missing-file-and-missing-path half of F-003.

### PO-004

State: `F = false`, `H = false`.

The first guard is false. The second guard is true, so the app is marked
unmigrated. This proves the module-file half of F-003.

### PO-005

State: `F = false`, `L = true`, `H = true`.

The first guard is false. The second guard is false. The scan path is reached.
This proves F-004.

## K Artifacts

`fvk/mini-migration-loader.k` gives a finite rewrite semantics for this branch
classification. `fvk/migration-loader-spec.k` states PO-001 through PO-005 as
K reachability claims. Because there are no loops or recursion in the audited
predicate, no circularity or loop invariant is needed; each claim reduces by one
semantic rule.

Exact commands to machine-check later, not executed here:

```sh
# From fvk/
kompile mini-migration-loader.k --backend haskell
kprove migration-loader-spec.k
```

Expected machine-check result, if the constructed semantics and claims parse as
written: `#Top`.

## Adequacy

The formal claims paraphrase the public intent:

- PO-001 is exactly the new behavior requested by the issue.
- PO-002 is exactly the "do not allow namespace packages" constraint.
- PO-003 and PO-004 preserve non-package behavior supported by comments and
  public tests.
- PO-005 preserves ordinary package scanning in normal Python environments.

No proof step relies on hidden tests, upstream patches, benchmark results, or
the current implementation as the sole source of an expected behavior.

## Test Guidance

Do not remove tests. The proof is constructed but not machine-checked, and the
benchmark forbids test edits. Existing public tests for module-file and
namespace-directory behavior should be kept. A conventional test suite could add
a focused regression test for PO-001: imported migrations package with
`__file__` absent and list-valued `__path__` is scanned.
