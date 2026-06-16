# Formal Spec English

`PRESERVE-CACHED-RELATION`: If a fetched related object already has a relation
cache entry before the descriptor prefetch cache-seeding step, the step must
leave that entry unchanged.

`SEED-MISSING-RELATION`: If a fetched related object lacks the relation cache
entry before the descriptor prefetch cache-seeding step, the step must create
the entry and set it to the origin object.

`COVER-RELATION-FAMILY`: The preserve-or-seed rule applies to the one-to-one
path and the ForeignKey reverse path named by the issue, and to the symmetric
forward many-to-one descriptor cache-seeding path changed by V1.

