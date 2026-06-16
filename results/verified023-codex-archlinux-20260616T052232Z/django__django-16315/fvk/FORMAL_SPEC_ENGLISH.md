# FORMAL_SPEC_ENGLISH

Status: English paraphrase of the constructed K claims.

## Claim C1: Resolve Update Fields on Upsert

If the conflict mode is `update`, then each model field name in the
`update_fields` option is looked up in the model field map and replaced by the
corresponding field record.

## Claim C2: Resolve Unique Fields on Upsert

If the conflict mode is `update`, then each normalized model field name in the
`unique_fields` option is looked up in the model field map and replaced by the
corresponding field record.

## Claim C3: Compile Columns on Upsert

If the conflict mode is `update`, then the compiler sends the backend the
`column` component of each resolved field record for both update and unique
field lists.

## Claim C4: Non-Upsert Frame

If the conflict mode is not `update`, then the new conversion does not inspect
or change the conflict option lists.

## Claim C5: Backend Identifier Contract

Backend conflict SQL generation receives database column identifier strings.
For a field record `field("blacklistid", "BlacklistID")`, the backend receives
`"BlacklistID"`, not `"blacklistid"`.
