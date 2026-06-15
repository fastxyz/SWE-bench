# Constructed Proof

Status: constructed, not machine-checked. No test, Python, `kompile`, `kast`,
or `kprove` command was run.

## Claims Proved in the Constructed Model

The proof targets `trim_docstring()` in
`repo/django/contrib/admindocs/utils.py`.

Claims:

- C1 / PO-1: `None` and blank input return `""`.
- C2 / PO-2 / PO-3: non-blank input returns `cleanDoc(S)`, not a locally
  computed `min()` margin.
- C3 / PO-2 / PO-3 / PO-5: `cleanDoc(S)` satisfies the PEP 257 cleanup
  property, including skip-first-line margin calculation and empty-tail safety.
- C4 / PO-4: cleaned first-line-summary docstrings are safe for admindocs'
  `parse_rst()` directive wrapper.
- C5 / PO-5: leading-empty-line docstrings remain compatible with the public
  utility test's PEP 257 output.
- C6 / PO-6: helper signature and return shape are unchanged.

There are no loops or recursion, so there are no circularity claims.

## Symbolic Proof Sketch

Initial state:

`<k> trimDocstring(DOC) </k>`

Case split on `DOC`.

1. `DOC = noneDoc`

   The semantic rule in `mini-python-string.k` rewrites:

   `<k> trimDocstring(noneDoc) </k> => <k> "" </k>`

   This discharges PO-1 for missing docstrings.

2. `DOC = doc(S)` and `isBlankString(S)`

   The blank-string semantic rule rewrites:

   `<k> trimDocstring(doc(S)) </k> => <k> "" </k>`

   This discharges PO-1 for empty and all-whitespace strings.

3. `DOC = doc(S)` and `notBool isBlankString(S)`

   The non-empty semantic rule rewrites:

   `<k> trimDocstring(doc(S)) </k> => <k> cleanDocString(S) </k>`

   This matches the V1 source:

   ```python
   if not docstring or not docstring.strip():
       return ''
   return cleandoc(docstring)
   ```

   By the trusted standard-library contract from E6 and E7,
   `cleanDocString(S)` satisfies the PEP 257 claims:

   - the first line is left-trimmed;
   - the common margin is computed from non-empty lines after the first line;
   - no non-empty following line means margin `0`, not `ValueError`;
   - leading-empty-line docstrings remain in the same PEP 257 cleanup family.

   Consequence gives PO-2, PO-3, and PO-5.

4. Directive-safety consequence

   From PO-2, a first-line-summary docstring with indented continuation/body
   lines is dedented before `parse_docstring()` and `parse_rst()` consume it.
   Since the retained indentation was the modeled mechanism for docutils
   treating the text as `default-role` directive content, the cleaned output
   satisfies PO-4.

5. API frame

   The diff changes only the implementation and import. The function name,
   parameter count, and string return protocol remain unchanged. The public
   compatibility audit discharges PO-6.

## Adequacy Gate

`fvk/FORMAL_SPEC_ENGLISH.md` paraphrases every nontrivial claim. 
`fvk/SPEC_AUDIT.md` compares those claims against
`fvk/INTENT_SPEC.md` and marks every required behavior as pass. No proof claim
uses current candidate behavior as its only evidence.

## Findings Integrated

- F-001 is the pre-V1 code bug and is resolved by PO-2 and PO-4.
- F-002 is the rejected naive-patch crash and is resolved by PO-3.
- F-003 and F-004 are compatibility conditions and are satisfied by PO-5 and
  PO-6.
- F-005 is the trusted-base boundary for `inspect.cleandoc()` and remains an
  explicit proof caveat.

## Test-Redundancy Recommendation

No tests were modified. Because this proof was constructed but not
machine-checked, no test should be removed on its basis.

Tests to keep:

- Existing admindocs parsing/rendering tests, because they cover integration
  with docutils and templates beyond this unit proof.
- Existing leading-empty-line utility tests until the K claims are actually
  machine-checked.

Tests that would be useful public coverage, if tests were allowed to change:

- first-line-summary docstring with indented continuation/body text;
- one-line docstring to guard against the rejected empty-tail `min()` crash;
- `None` or blank docstring behavior, if not already covered elsewhere.

## Machine-Check Commands

These are the commands to run in an environment with K installed. They were not
run in this task.

```sh
kompile fvk/mini-python-string.k --backend haskell
kast --backend haskell fvk/trim-docstring-spec.k
kprove fvk/trim-docstring-spec.k
```

Expected machine-check result after a complete K setup: `#Top` for all claims.
