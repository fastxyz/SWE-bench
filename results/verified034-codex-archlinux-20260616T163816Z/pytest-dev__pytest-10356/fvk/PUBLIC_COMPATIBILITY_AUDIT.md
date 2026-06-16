# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed symbol: `get_unpacked_marks`

Change: added keyword-only parameter `consider_mro: bool = True`.

Callsite search result: existing callsites pass only the positional `obj`, so the
default preserves source compatibility.

Compatibility status: compatible.

## Changed behavior: class mark lookup

Change: classes use direct `__dict__` reads across the MRO instead of normal
`getattr` lookup.

Public API impact: intended behavior change for `Node.iter_markers` and
`Node.get_closest_marker` after collection. This is the bug fix.

Compatibility status: compatible with the issue intent; potentially breaking for
code depending on missing marks.

## Changed behavior: class decorator storage

Change: `store_mark` appends only direct marks for class objects.

Public API impact: raw `Sub.pytestmark` may no longer contain inherited marks
immediately after decoration. The supported public retrieval path is through node
marker APIs during collection.

Compatibility status: acceptable for this fix; recorded as part of PO2/PO3.

## Out-of-domain compatibility: metaclass descriptors

Change risk: direct class `__dict__` reads do not generally consume arbitrary
metaclass `pytestmark` descriptors.

Compatibility status: unresolved outside the public issue obligation. See
Finding F4.
