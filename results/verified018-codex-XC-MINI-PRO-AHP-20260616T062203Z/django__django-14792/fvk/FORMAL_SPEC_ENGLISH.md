# Formal Spec English

Status: paraphrase of `tzname-spec.k`, constructed but not machine-checked.

## Claims

- `SPLIT-NAMED-SIGNED`: A signed IANA timezone name such as `Etc/GMT-10` is classified as `noDelta`, not as a fixed offset.

- `SPLIT-OFFSET-UTC`: A fixed-offset string such as `UTC+05:00` is classified as an offset with prefix `UTC`, sign `+`, and offset `05:00`.

- `SPLIT-OFFSET-BARE`: A fixed-offset string such as `+10` or `-0517` is classified as an offset with no prefix.

- `PG-NAMED-PRESERVE`: PostgreSQL preparation returns a non-offset timezone name unchanged.

- `PG-OFFSET-REVERSE`: PostgreSQL preparation reverses the sign of fixed-offset strings only.

- `MYSQL-NAMED-PRESERVE` and `ORACLE-NAMED-PRESERVE`: MySQL and Oracle preparation return non-offset timezone names unchanged.

- `MYSQL-ORACLE-OFFSET-STRIP-UTC`: MySQL and Oracle strip an optional `UTC` prefix from fixed-offset strings and keep the numeric sign.

- `SQLITE-NAMED-NO-OFFSET`: SQLite does not offset-adjust timezone names that are not fixed-offset strings.

- `SQLITE-OFFSET-APPLY`: SQLite offset-adjusts fixed-offset strings and localizes through `UTC`.
