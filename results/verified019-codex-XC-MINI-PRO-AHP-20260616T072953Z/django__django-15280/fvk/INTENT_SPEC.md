# Intent Spec

The public issue requires nested prefetches back to an origin model to preserve
the fields loaded by the nested queryset. In the concrete example, accessing
`user.profile.user.kind` after evaluating the outer queryset must not issue a
query because the inner `User.objects.only("kind")` queryset loaded `kind`.

The public hint adds the winner rule: keep the default behavior of assigning
the origin object when no more specific nested cache exists, but allow nested
prefetches to override that default by preserving already-cached relations.

The same rule applies to the ForeignKey reverse relation variant named in the
issue.

