# Formal Spec in English

Status: paraphrase of the constructed K claims.

## STANDARD-CANONICAL-NAMES

For any valid settings dictionary with non-empty `NAME`, non-empty `PASSWORD`,
and no user-supplied legacy aliases in `OPTIONS`, a normal return from
`get_connection_params()` contains `database` with the database name and
`password` with the password. The returned params do not contain `db` or
`passwd`.

## CANONICAL-OPTIONS-PRECEDENCE

For any valid settings dictionary where `OPTIONS` contains canonical
`database` or `password`, the final params use those option values for the
canonical keys because options are merged after standard settings.

## LEGACY-OPTIONS-PASSTHROUGH

For any valid settings dictionary where `OPTIONS` contains `db` or `passwd`,
those keys remain user-supplied pass-through driver options. Their presence is
not attributed to Django's standard settings mapping.

## FRAME-UNCHANGED-BEHAVIOR

The proof does not alter or re-specify unrelated behavior for `conv`, `charset`,
`user`, host/socket selection, port conversion, `client_flag`, isolation level
validation, or non-isolation `OPTIONS` merging.
