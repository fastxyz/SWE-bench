# Formal Spec In English

Status: constructed, not machine-checked.

## CLAIM-MRO-COMPLETE

For a class object, `get_unpacked_marks(obj)` gathers direct `pytestmark` values
from each class in the class MRO, normalizes them, and exposes every marker name
owned by every marked base class. For the issue example, the resulting marker-name
set for `TestDings(Foo, Bar)` is `{foo, bar}`.

## CLAIM-OWN-ONLY-STORE

When a mark decorator is applied to a class, `store_mark` appends the new mark to
the class's direct marks only. It does not copy inherited marks into the class's
own `pytestmark` list.

## CLAIM-NONCLASS-FRAME

For non-class objects, `get_unpacked_marks` still reads `getattr(obj,
"pytestmark", [])`, wraps non-list values as a single mark, and normalizes the
result.

## CLAIM-INVALID-FRAME

Every path still passes candidate mark objects through `normalize_mark_list`.
Invalid entries therefore continue to raise the same `TypeError`.

## Non-claim: sibling-base order

The K proof models V1's concrete flattening order, but the correctness conclusion
uses only marker-name completeness. Sibling-base list order is not claimed as
public intent.
