# Public Evidence Ledger

Status: constructed from public sources only.

## E-001

Source: prompt / issue (`benchmark/PROBLEM.md`).

Quote: "add ModelAdmin.get_inlines() hook to allow set inlines based on the
request or model instance."

Semantic obligation: add a public hook named `get_inlines` that receives both
`request` and optional `obj`.

Spec status: encoded by PO-001 and PO-002.

## E-002

Source: prompt / issue (`benchmark/PROBLEM.md`).

Quote: "Currently, We can override the method get_inline_instances to do such a
thing, but a for loop should be copied to my code."

Semantic obligation: users should not have to copy the construction and
permission loop merely to vary the inline class list.

Spec status: encoded by PO-002 and PO-003.

## E-003

Source: prompt / issue (`benchmark/PROBLEM.md`).

Quote: "What I want to do is just set self.inlines to dynamic values according
to different person or object. not inline instances."

Semantic obligation: the new hook returns inline classes, and existing
`get_inline_instances()` remains responsible for constructing instances.

Spec status: encoded by PO-001, PO-002, and PO-003.

## E-004

Source: implementation before V1 (`repo/django/contrib/admin/options.py`).

Quote: `for inline_class in self.inlines:`.

Semantic obligation: default behavior before customization is iteration over
the static `inlines` sequence.

Spec status: encoded by PO-001 as the default hook contract.

## E-005

Source: public docs (`repo/docs/ref/contrib/admin/index.txt`).

Quote: overriding `get_inline_instances()` should return instances of classes
defined in `inlines` or related-object additions might produce "Bad Request".

Semantic obligation: do not accidentally change the related-object validation
registry from static `inlines` to an objectless dynamic hook call.

Spec status: encoded by PO-004 and Finding F-001.

## E-006

Source: implementation (`repo/django/contrib/admin/checks.py`).

Quote: `_check_inlines()` validates `obj.inlines`.

Semantic obligation: checks are tied to static `inlines`; no public evidence
requires request-dependent checks.

Spec status: encoded by PO-006.
