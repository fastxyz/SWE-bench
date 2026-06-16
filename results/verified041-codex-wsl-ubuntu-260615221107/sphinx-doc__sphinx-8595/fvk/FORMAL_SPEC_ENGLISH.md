# Formal Spec In English

This paraphrases every nontrivial claim in `autodoc-module-all-spec.k`.

## `NO-ALL-BRANCH`

For all finite member lists `MS`, if autodoc wants all module members and the
module export state is `noAll`, then `getObjectMembers` returns
`result(true, MS)`.

Meaning: missing, ignored, or invalid `__all__` keeps the implicit member path.

## `EXPLICIT-ALL-BRANCH`

For all finite member lists `MS` and all export-name lists `NS`, if autodoc
wants all module members and the module export state is `exports(NS)`, then
`getObjectMembers` returns `result(false, markSkipped(NS, MS))`.

Meaning: any explicit valid `__all__` sequence is authoritative. Members whose
names are not in the sequence are forced skipped.

## `EMPTY-ALL-BRANCH`

For all finite member lists `MS`, if autodoc wants all module members and the
module export state is `exports(.Names)`, then `getObjectMembers` returns
`result(false, markSkipped(.Names, MS))`, which marks every member skipped.

Meaning: an explicit empty `__all__` is not the same as missing `__all__`.

## `EMPTY-ALL-FILTER`

For all finite member lists `MS`, default filtering of
`markSkipped(.Names, MS)` returns `.Members`.

Meaning: with no user skip-event override, an explicit empty `__all__` produces
no documented module members.

## `EXPLICIT-MEMBERS-FRAME`

For all export states and member lists, if autodoc does not want all members
because it is processing an explicit selected member list, `getObjectMembers`
returns `result(false, SELECTED)`.

Meaning: the V1 edit does not change explicit named-member selection.
