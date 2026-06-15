# Findings

Status: constructed, not machine-checked.

## F-001: V1 addresses the reported aliasing bug

Classification: code bug found in baseline, resolved by V1.

Input sequence:

```text
qs = A.union(B).order_by('order')
repr(qs)
qs.order_by().values_list('pk', flat=True)
repr(qs)
```

Observed before V1:

```text
ProgrammingError: ORDER BY position 4 is not in select list
```

Expected:

```text
The original ordered union remains evaluable because its component select lists
still contain the ordered position.
```

Evidence: public issue E-1 through E-4; proof obligation PO-1 through PO-3.

V1 status: `Query.clone()` now clones `combined_queries`, so derived querysets
receive independent child `Query` objects.

## F-002: No additional production edit is justified by the FVK audit

Classification: confirmation of V1.

The audit considered changing `QuerySet._combinator_query()` to clone operands
at set-operation construction. The formal intent is about a derived queryset
mutating the already-created source union. Public evidence points to
copy-before-mutation during derivation, and source evidence shows derivation
flows through `Query.clone()`.

Expected:

```text
Changing Query.clone() is sufficient for qs.order_by().values_list(...) not to
share component query objects with qs.
```

Evidence: E-5, E-7, PO-1, PO-4, PO-5.

Decision: keep V1 unchanged.

## F-003: Proof is constructed, not machine-checked

Classification: proof status / test gap.

The FVK task forbids running K tooling. The `.k` artifacts and expected commands
are emitted, but `kompile` and `kprove` were not run.

Expected future check:

```sh
kompile fvk/mini-query-clone.k --backend haskell
kast --backend haskell fvk/query-clone-spec.k
kprove fvk/query-clone-spec.k
```

Expected result if the constructed proof matches the K toolchain: `#Top`.

No tests were removed or modified.

## Proof-derived findings from verify

No new code bug was found. The proof obligations that matter for the issue are
frame obligations over object identity and child select width, and V1 discharges
them by construction. Residual risk is limited to the fact that this is a
minimal aliasing model, not a full Python or SQL semantics.
