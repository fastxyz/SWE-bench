# FVK Notes

The FVK audit confirms that V1 should stand unchanged.

## Decisions

- Kept the constructor guard in `Blueprint.__init__` because F-001 identifies direct `Blueprint("", __name__)` as the public bug, and PO-1 proves that path now raises `ValueError`.
- Kept the registration guard in `Blueprint.register` because F-002 shows `app.register_blueprint(bp, name="")` can create the same empty effective blueprint identity, and PO-4 proves V1 raises before app registration state is mutated.
- Made no further source edit for nested blueprint recording because F-003 and PO-6 trace nested `name=""` to the same effective `Blueprint.register` path when the parent is registered.
- Did not refactor the duplicate guards into a helper because PO-5 and PO-7 emphasize preserving non-empty-name behavior with the smallest compatibility surface.
- Did not broaden validation to whitespace-only names or `if not name`; NF-001 rejects that as unsupported by the public issue and potentially broader than intended.
- Did not add dotted `name=` override validation; NF-002 records it as a separate compatibility question outside the empty-name issue.

## Verification Status

The artifacts in `fvk/` include the required markdown files plus the supporting adequacy and K files. The proof is constructed, not machine-checked. No tests, Python code, or K commands were executed, in accordance with the task constraints.

