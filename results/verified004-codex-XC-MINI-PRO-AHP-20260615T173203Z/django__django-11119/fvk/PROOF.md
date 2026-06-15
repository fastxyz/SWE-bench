# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, or `kprove` command was executed.

## What Is Proved

Under the mini template-engine semantics in `fvk/mini-template-engine.k`, the V1 implementation satisfies the intended autoescape contract for `Engine.render_to_string()`:

- for non-`Context` inputs, the render-observed autoescape flag equals `Engine.autoescape`;
- for existing `Context` inputs, the render-observed autoescape flag equals the caller-supplied `Context.autoescape`;
- the single-name and list/tuple template-name branches do not affect this contract.

## Proof Sketch

The mini semantics has two rewrite rules.

1. Plain context path:
   - Start: `<k> renderToString(EA, TN, plain) </k>`.
   - Rule: the non-`Context` path constructs a context with `autoescape=EA`.
   - Result: `<k> rendered(EA) </k>`.
   - This discharges PO-001 and the concrete `EA=False` discriminator.

2. Existing context path:
   - Start: `<k> renderToString(EA, TN, existing(CA)) </k>`.
   - Rule: the existing `Context` path passes the context through unchanged.
   - Result: `<k> rendered(CA) </k>`.
   - This discharges PO-002.

`TN` is symbolic over `single` and `many`, so both template selection branches are covered by the same claims, discharging PO-003. There are no loops or recursive calls, so no circularity claim is needed.

## Adequacy

The model retains the observable needed for the defect: whether rendering sees `autoescape=True` or `autoescape=False`. It distinguishes the legacy failing case from V1:

- legacy abstract behavior for `Engine(autoescape=False)` with a plain context: `rendered(true)`;
- intended and V1 behavior: `rendered(false)`.

This supports PO-004 and PO-006.

## Machine-Check Commands

These commands are recorded for a later environment with K installed. They were not run in this session.

```sh
kompile fvk/mini-template-engine.k --backend haskell
kast --backend haskell fvk/engine-render-to-string-spec.k
kprove fvk/engine-render-to-string-spec.k
```

Expected machine-check result after successful setup: `kprove` returns `#Top` for all claims.

## Residual Risk

The proof is partial and constructed, not machine-checked. It abstracts away template lookup failures and the detailed escaping algorithm because those are unchanged and outside the issue. Test removal is not recommended from this un-machine-checked proof.

## Test Guidance

Keep integration and template-loader tests. A focused regression test for the public issue would assert that an `Engine(autoescape=False)` using `render_to_string()` with a plain dictionary context renders unescaped output. No tests were added or modified because the benchmark forbids test-file changes.
