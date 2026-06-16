# Iteration Guidance

Status: constructed, not machine-checked.

## Code decision

V1 stands unchanged. The FVK audit found no source-level defect against the
intent specification. This decision is justified by:

- F1, which shows the reported wrong-parent-row update is addressed;
- F2, which confirms the parent-link path helper covers the main deeper
  inheritance risk surfaced during audit;
- F3, which finds no public compatibility break;
- PO1-PO7, all of which are discharged by the V1 source mechanisms.

## Future test guidance

Do not edit tests in this benchmark. In a normal Django development pass, add a
regression test for:

- two concrete parents with distinct primary-key sequences, updating a field on
  the second parent through the child manager;
- optionally, a deeper child where the updated field belongs to an indirect
  ancestor reached through a multi-parent intermediate model.

Keep existing integration tests. The FVK proof is abstract and constructed only;
it does not replace database-backed tests until the K artifacts are
machine-checked and the abstraction is reviewed.

## Future proof guidance

The next FVK iteration should either:

- run the emitted `kompile`/`kprove` commands and repair any K syntax issues
  until `#Top`; or
- replace the abstract mini semantics with a richer Python/Django ORM semantics
  if the proof target is expanded to SQL generation or database execution.
