# FVK Specification

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## Scope

This FVK pass audits the V1 fix for `sphinx-doc__sphinx-8035`: support explicit arguments for autodoc `:private-members:`. The proof model covers the code paths changed by V1 and the observable behavior they control:

- `members_option()`
- `merge_members_option()`
- `merge_special_members_option()`
- `merge_private_members_option()`
- the private-member branches of `Documenter.filter_members()`
- `ModuleDocumenter.option_spec`
- `ClassDocumenter.option_spec`
- public documentation for `private-members`

The model intentionally does not re-specify unrelated autodoc behavior such as import resolution, signature rendering, final documenter selection, or user event callback internals. Those are frame conditions: the fix must not change them.

## Public Intent Ledger

| ID | Evidence | Obligation |
| --- | --- | --- |
| I1 | Issue title: "Support defining specific `:private-members:` for autodoc" | `private-members` must accept specific member names. |
| I2 | Issue body: "does not allow specification of which private members to document" | The option argument must not be discarded by a boolean converter. |
| I3 | Issue body: "document all private members ... only like to document 1 or 2" | A finite list must include selected private names and exclude unselected private names in all-members mode. |
| I4 | Issue solution: "take arguments, similarly to how `:members:` currently works" | Use the `members` comma-list parsing shape and explicit-name semantics. |
| I5 | Existing docs: bare `private-members` includes private members | Preserve bare-option all-private behavior. |
| I6 | Existing docs: default-option `None` or `True` equals the bare option | Preserve default-options compatibility for `None` and `True`. |
| I7 | Existing docs/code: `special-members` can take arguments and is merged into `members` | Use this as an analogy for explicit private-name merge behavior. |
| I8 | Existing filter code: exclude/mock checks precede private filtering | Preserve skip precedence. |
| I9 | Existing filter code/docs: explicit members can include private names | Preserve explicit `members` behavior independent of `private-members`. |
| I10 | Public docs are user-facing evidence | Update docs so they no longer describe `private-members` as only a flag. |

The detailed ledger is mirrored in `fvk/PUBLIC_EVIDENCE_LEDGER.md`.

## Formal Domain

Options:

- absent option
- bare option / `None`
- `True`
- comma-separated string list represented in the K model as an already-trimmed `List`

Members:

- name
- private/public classification
- runtime docstring status
- source attribute documentation status
- excluded status
- mocked status

The proof is partial-correctness only: it specifies the result of option conversion, merge, and filter decisions when these functions return.

## Intended Postconditions

1. `private-members` uses list-capable parsing: `None` and `True` produce `ALL`; comma-list strings produce selected names.
2. Module and class documenters both use that parser for `private-members`.
3. A finite private selector is merged into `members` when `members` is absent or already finite, preserving order and avoiding duplicates.
4. A finite private selector does not replace `members is ALL`; it acts as a filter while all member candidates are gathered.
5. In all-members mode, private members are kept iff `private-members` is `ALL` or contains their name, subject to the existing documentation requirement.
6. Source-documented private attributes remain keepable when selected because source attribute docs already count as documentation.
7. `exclude-members` and mocked-object skipping still override private selection.
8. In explicit-members mode, explicit private names remain keepable under existing documentation rules.
9. Public docs describe the new explicit-list support.

## K Artifacts

- `fvk/mini-autodoc.k`: a minimal semantics for the option/merge/filter fragment.
- `fvk/autodoc-private-members-spec.k`: reachability claims for parsing, merging, and private filtering.

Exact commands to machine-check later, not run here:

```sh
kompile fvk/mini-autodoc.k --backend haskell
kast --backend haskell fvk/autodoc-private-members-spec.k
kprove fvk/autodoc-private-members-spec.k
```
