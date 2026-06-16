# Constructed Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, or
`kprove` were run.

## Claims Proved in the Model

The K model in `mini-python-autoreload.k` defines argv construction from:

- an executable path;
- warning options;
- a Boolean representing whether `sys._xoptions` exists;
- an ordered xoption ledger;
- a launch branch; and
- user arguments.

`autoreload-get-child-arguments-spec.k` states claims C1-C7 for script, module,
script-entrypoint, no-ledger, xoption-formatting, and direct `.exe` fallback
behavior.

## Proof Sketch

There are no loops or recursion in the modeled fragment, so no circularity or
termination argument is required. The proof is straight symbolic rewriting.

1. For script, module, and script-entrypoint claims, apply the matching
   `childArgs(...)` rewrite rule. The resulting argv is:

   `arg(EXE, append(warnArgs(WARNS), append(xArgs(true, XOPTS), TARGET)))`.

2. Apply `warnArgs` recursively to preserve each warning option as `-W<option>`.
   This discharges PO-003.

3. Apply `xArgs(true, ...)` recursively. For each xoption:

   - `flag` rewrites through `formatX(KEY, flag)` to `-X<key>`;
   - `val(V)` rewrites through `formatX(KEY, val(V))` to `-X<key>=<value>`.

   This discharges PO-001 and PO-002.

4. The append rules preserve order: warning args precede xoption args, and both
   precede the launch target and user args. This discharges PO-004 through
   PO-006.

5. When the `HASX` Boolean is false, `xArgs(false, XOPTS)` rewrites to empty
   args for all ledgers. This discharges PO-009.

6. For the direct `.exe` fallback claim, the `asExeEntrypoint` rewrite ignores
   interpreter options and returns `arg(ENTRY, USER)`, matching the existing
   non-`sys.executable` branch. This discharges PO-007.

7. Public compatibility is a frame condition over the source edit: the modeled
   return remains an argv list and the Python function signature is unchanged.
   This discharges PO-008.

## Expected Machine Check

The commands to run outside this constrained benchmark are:

```sh
kompile fvk/mini-python-autoreload.k --backend haskell
kast --backend haskell fvk/autoreload-get-child-arguments-spec.k
kprove fvk/autoreload-get-child-arguments-spec.k
```

Expected result: `#Top`.

## Residual Risk

- The proof is constructed, not machine-checked.
- The mini semantics proves argv construction, not CPython's actual option
  parser or subprocess behavior.
- Test removal is not recommended in this benchmark. Existing tests should be
  kept, and new tests should cover `sys._xoptions` once test editing is allowed.
