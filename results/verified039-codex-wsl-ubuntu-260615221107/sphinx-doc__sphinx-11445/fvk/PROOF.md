# PROOF

Status: constructed, not machine-checked. No K tooling, Python, tests, or
project code were run.

## What Is Proved

For the modeled behavior of `prepend_prolog()`, if a non-empty prolog is inserted
into a source whose first field-looking line is actually a section title because
the next line is a valid underline, the prolog is inserted before the whole title
block. The title line remains immediately adjacent to its underline. Genuine
leading docinfo remains before the prolog, and falsey prolog leaves content
unchanged.

## Formal Core

The K-style artifacts are:

- `mini-rst-prolog.k`: a minimal line-list semantics for prolog insertion.
- `prepend-prolog-spec.k`: reachability claims for role-title preservation,
  docinfo-prefix preservation, no-docinfo insertion, and empty-prolog no-op.

Exact commands to machine-check later, from the `fvk/` directory:

```sh
kompile mini-rst-prolog.k --backend haskell
kast --backend haskell prepend-prolog-spec.k
kprove prepend-prolog-spec.k
```

Expected result after a successful future machine check: `#Top`.

## Proof Sketch

### 1. Helper predicate

`_is_section_title(content, pos)` has only one true path. It first requires that
`pos + 1` is in bounds. It then strips only trailing whitespace from the title
line and surrounding whitespace from the underline line. It rejects empty title
or underline text and rejects underlines shorter than the title. Finally it
requires the underline to be repetitions of one non-alphanumeric,
non-whitespace character.

By the local Sphinx documentation, section headers are title text underlined by a
punctuation character at least as long as the text. Therefore the reported role
heading satisfies the helper predicate.

### 2. Scan loop invariant

Let `pos` be the scan counter in `prepend_prolog()`.

Invariant after each completed iteration:

- every index `< pos` matched `docinfo_re`;
- every index `< pos` failed `_is_section_title(content, index)`;
- all original lines remain in their original relative order because no mutation
  occurs during the scan.

The invariant is established at `pos == 0`. One iteration preserves it because
the loop increments `pos` only when both loop-condition conjuncts are true. The
loop exits at the first index that is out of range, not docinfo, or a section
title.

### 3. Reported role-title branch

For the issue input, line 0 matches `docinfo_re` but also satisfies
`_is_section_title(content, 0)` because line 1 is `=================`, one
repeated punctuation underline at least as long as the title text. The scan
therefore exits immediately with `pos == 0`.

With `pos == 0`, the `if pos > 0` docinfo separator branch is skipped. Prolog
lines are inserted at index 0 and a generated blank line is inserted after the
prolog block. The original line 0 shifts after that blank line, and the original
line 1 shifts with it. Their adjacency is preserved.

This discharges PO-002, PO-003, and PO-004, resolving F-001.

### 4. Genuine docinfo branch

For genuine leading metadata such as `:title: ...` and `:author: ...`, each
metadata line matches `docinfo_re`, and `_is_section_title()` is false unless it
is followed by a valid underline. In the documented metadata shape, the scan
advances beyond the metadata prefix, then inserts a generated blank line, the
prolog block, and another generated blank line. The suffix remains in original
order.

This discharges PO-005 and resolves F-002.

### 5. Empty-prolog branch

The only mutating statements are inside `if prolog:`. If `prolog` is falsey,
control skips the block and `content` is unchanged. This discharges PO-006.

## Test Guidance

No test is recommended for deletion. The proof is not machine-checked in this
session, and it covers the utility's line-order contract rather than full
docutils parsing, rendering, or toctree integration. Existing unit and
integration tests should remain. A future public test should cover a
field-looking role title followed by an underline with `rst_prolog` set.

## Residual Risk

The constructed proof uses a mini line-list semantics, not full Python or full
docutils parsing. It is adequate for the defect's observable line-order property,
but full rendering behavior remains an integration concern. Termination is not a
separate obligation here because the scan is over a finite `StringList`, but that
termination argument was not machine-checked.

