# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed Public Symbol

`HashedFilesMixin.post_process(self, paths, dry_run=False, **options)`

Compatibility result: Pass.

Reason: V1 changes only the emission policy inside the method. The method
signature is unchanged, and yielded public items remain triples of
`(original_path, processed_path, processed)`.

## Public Consumer

`collectstatic.collect()` consumes the generator at
`repo/django/contrib/staticfiles/management/commands/collectstatic.py:126-138`.

Compatibility result: Pass.

Reason: `collectstatic` still receives triples. The uniqueness change aligns
with its documented behavior in the issue because `collectstatic` counts each
successful yielded tuple as one post-processed file.

## Subclass and Wrapper Consumers

The issue explicitly names subclasses/wrappers such as WhiteNoise and possible
S3 backends as consumers that perform work per yielded tuple.

Compatibility result: Pass.

Reason: Those consumers still receive the same tuple shape, but no longer see
intermediate adjustable successes. That is the requested compatibility repair.

## Internal Overrides

`ManifestFilesMixin.post_process()` delegates with `yield from super().post_process`
and then saves the manifest. V1 preserves the delegated generator shape.

Compatibility result: Pass.

Reason: No override signature or call protocol changed.

## Residual Compatibility Risk

The timing of adjustable successful yields changes: they are emitted after
stabilization rather than during each internal pass. This is intentional and is
required by public intent because the final hash is not known until the repeated
passes settle. Non-adjustable yields retain their initial-pass timing.
