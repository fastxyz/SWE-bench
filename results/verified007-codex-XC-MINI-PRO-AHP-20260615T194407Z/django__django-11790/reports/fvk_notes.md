# FVK Notes

The FVK audit confirms V1 unchanged.

Finding F-001 and proof obligations PO-001 and PO-002 justify the source change
already present in `repo/django/contrib/auth/forms.py`: after
`AuthenticationForm.__init__()` computes the dynamic username max length, it
refreshes widget attrs through `username.widget_attrs(username.widget)`. That
repairs the reported rendered-HTML regression because `CharField.widget_attrs()`
adds `maxlength` only after `max_length` is set.

Finding F-002 confirms the same code covers the user-model family already
present in public tests: a custom username length such as `255`, and the
fallback `254` when the model field has no max length. This traces to PO-001
for effective length selection and PO-002 for rendering that length.

Finding F-003 and PO-004 justify keeping V1's delegated implementation instead
of directly assigning `widget.attrs['maxlength']`. Delegation preserves
compatibility with subclasses that replace `username`, including public tests
using `IntegerField()`.

Finding F-004 and PO-005 explain the only broader issue considered and rejected:
rebuilding `MaxLengthValidator` instances would change runtime validation
behavior, while the public issue is specifically about the missing rendered
`maxlength` HTML attribute. No source edit was made for that ambiguity.

Finding F-005 and PO-006 record the proof-process constraint: the K-style
artifacts and commands were produced but not executed, as required by the task.
