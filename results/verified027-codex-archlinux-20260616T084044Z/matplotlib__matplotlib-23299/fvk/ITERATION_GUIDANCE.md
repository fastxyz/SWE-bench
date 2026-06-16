# Iteration Guidance

Constructed, not machine-checked.

## Code Decision

V1 stands unchanged after FVK audit.

Reason:

- F-1 discharges the reported bug against PO-1.
- F-2 shows the new branch does not suppress initial lazy resolution required by
  PO-2.
- F-3 shows real backend switching remains destructive as required by PO-5.
- F-4 shows standalone `RcParams` behavior remains outside the global repair
  path as required by PO-4.

No additional source edits are justified by the public intent ledger.

## Suggested Tests For A Future Test Pass

Do not edit tests in this benchmark task. For a normal development pass, add or
keep tests for:

1. The issue reproduction: create the first figure inside `rc_context()`, call
   `matplotlib.get_backend()`, assert `Gcf.figs` is unchanged, and assert
   `plt.close(fig)` can find the manager.
2. Direct global `matplotlib.rcParams["backend"]` access in the same
   stale-sentinel loaded-backend state.
3. A standalone `RcParams({"backend": sentinel})["backend"]` access that returns
   the sentinel and does not resolve.
4. Initial lazy resolution when no backend is loaded.
5. Explicit `plt.switch_backend(...)` still closing figures on a real switch.

## Residual Risk

- The proof is constructed but not machine-checked because the task forbids
  running K tooling.
- The mini semantics abstracts backend import details, GUI framework selection,
  and concrete `OrderedDict` manager identity. It preserves the property axis
  under audit: whether `Gcf.figs` is framed or cleared.
- Thread interleavings during backend switching are outside the public issue
  and outside this proof.
