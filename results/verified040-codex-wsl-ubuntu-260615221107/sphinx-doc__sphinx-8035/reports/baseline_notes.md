# Baseline Notes

## Root cause

`private-members` was registered with `bool_option` for module and class autodoc directives, so any argument supplied to the option was discarded and the option always became `True`. Later member filtering only checked truthiness, so `:private-members: _one` behaved the same as bare `:private-members:` and included every otherwise eligible private member.

`special-members` already used `members_option` and merged explicit names into `members`, which is why it could document a named special member without requiring a separate `:members:` list. `private-members` did not have the equivalent parsing or merge step.

## Changed files

`repo/sphinx/ext/autodoc/__init__.py`

- Changed `private-members` in `ModuleDocumenter.option_spec` and `ClassDocumenter.option_spec` from `bool_option` to `members_option`, allowing the option to produce either `ALL` for the bare flag or a list of selected private member names.
- Added `merge_private_members_option()` using shared merge logic so explicit private member names are added to `members` just like explicit special member names. This lets `:private-members: _name` request that member even when `:members:` is not separately provided.
- Updated private-member filtering so bare `:private-members:` still includes all eligible private members, while `:private-members: _one, _two` includes only matching private names when autodoc is processing all members.
- Reworked the existing `special-members` merge through the same helper and copied option lists when they seed `members`, avoiding accidental aliasing between selector options and the merged member list.

## Assumptions and rejected alternatives

- I assumed explicit `private-members` values should mirror explicit `special-members` values: they should augment an explicit `members` list, work from `autodoc_default_options`, and not make bare `:private-members:` start member generation by itself.
- I kept existing behavior where private members still need docstrings unless `undoc-members` is set, except for source-documented attributes that autodoc already treats as documented.
- I rejected changing `members_option` itself because `members`, `special-members`, and the new `private-members` behavior share the same parsing shape, and changing the converter would broaden the risk unnecessarily.
- I rejected making `private-members` override an explicit `members` list. If a user explicitly lists a private name in `members`, autodoc already treats that as an explicit request, and this fix preserves that behavior.
