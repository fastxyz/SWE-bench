# Intent Specification

Status: constructed from public evidence only; current implementation behavior is
treated as candidate behavior, not as the specification.

## Required behaviors

1. Assigning `pk = None` on a multi-table inheritance child must clear the
   primary-key identity used by the child and its concrete parent tables in the
   active parent-link chain.

2. After that assignment, a normal `save()` of the child must create a copied
   object instead of updating the already existing parent row. The original row
   used by the issue reproduction must retain its previous field values.

3. The behavior must cover more than the one-level example. Public discussion
   says the real use may have "several levels of inheritance", so the primary
   key reset must work for a finite chain of parent-link primary keys.

4. Ordinary non-inheritance models must retain the existing `pk` setter
   behavior: assigning `pk` writes the model's own primary-key attribute.

5. The `pk` setter must not reset every multi-table parent link merely because
   it exists. Public issue discussion notes that a patch that touched all
   parents failed for child models that inherit from multiple models, and Django
   also supports explicit parent links that are not the child primary key.

## Out-of-scope or ambiguous behaviors

1. Directly assigning the inherited concrete parent primary-key attribute, such
   as `derived.uid = None`, is the issue's initial workaround-shaped example,
   but the public discussion narrows the reliable API obligation to
   `derived.pk = None`.

2. Copying every table involved in a model with multiple independent concrete
   parents is not fully specified by `pk`, which denotes a single model
   primary-key alias. Non-primary parent links remain ordinary one-to-one
   identity links unless public intent explicitly says to reset them.
