# FVK Findings

Status: constructed from public intent and source inspection; not machine-checked.

## F1: Tuple Default Parentheses Were Lost Before V1

Evidence:

- Intent ledger E1 and E2 in `fvk/SPEC.md`.
- Source path E4 and E6 in `fvk/SPEC.md`.

Input:

```python
add_lines(lines, color=(1, 1, 1), width=5)
```

Observed before V1 by source reasoning:

```text
add_lines(lines, color=1, 1, 1, width=5)
```

Expected:

```text
add_lines(lines, color=(1, 1, 1), width=5)
```

Root cause:

`signature_from_ast()` used the normal AST unparser for defaults. The normal
tuple visitor emits non-empty tuples as a comma list without parentheses, which
is acceptable for some contexts but wrong for a default-value expression.

Disposition:

Closed by V1. `signature_from_ast()` now uses `unparse_default()` for defaults,
and `visit_Tuple()` parenthesizes tuples when that context flag is active.

Proof obligations:

- O1
- O5

## F2: A Global Tuple-Unparse Change Would Break Annotation Syntax

Evidence:

- Intent ledger E5 in `fvk/SPEC.md`.
- Existing annotation parsing/rendering relies on subscript slices such as
  `Tuple[int, int]`.

Input:

```python
def f(x: Tuple[int, int]): ...
```

Observed risk if tuple unparsing were changed globally:

```text
Tuple[(int, int)]
```

Expected:

```text
Tuple[int, int]
```

Disposition:

Closed by V1. The original `unparse()` path remains unchanged, and
`signature_from_ast()` still uses it for annotations and return annotations.
The subscript-slice helper also keeps the top-level slice tuple unparenthesized
when default-value rendering sees generic aliases or similar expressions.

Proof obligations:

- O3
- O4
- O5

## F3: Integration Must Cover All Signature Default Positions

Evidence:

- Intent ledger E6 in `fvk/SPEC.md`.

Input classes:

- positional-only defaults
- positional-or-keyword defaults
- keyword-only defaults

Observed risk:

Changing only one default branch would leave some valid Python signature
defaults still using the normal tuple-unparse behavior.

Disposition:

Closed by V1. All three default-bearing branches in `signature_from_ast()` call
`ast_unparse_default()`.

Proof obligations:

- O5

## F4: Formal Result Is Constructed, Not Machine-Checked

Evidence:

- FVK documentation requires commands to be recorded when tooling is unavailable.
- User instructions explicitly forbid running K tooling.

Disposition:

Open as an honesty caveat, not a code defect. The proof and K artifacts are
constructed but were not compiled or proved. Test deletion is not recommended.

Proof obligations:

- O7 in `fvk/PROOF_OBLIGATIONS.md`

## Overall Verdict

No FVK finding requires changing V1 source code. V1 satisfies the intent-derived
obligations for the reported tuple-default rendering bug and preserves the
annotation behavior that a broader tuple-unparse change would have risked.
