# Formal Spec English

Status: constructed, not machine-checked.

C-DBNAME. For any booleans describing whether user, host, and port options are
present, for any service setting, and for any `PARAMS` list, if a PostgreSQL
database name is present then the constructed argument list is:

`["psql"] + user_option + host_option + port_option + PARAMS + [dbname]`

C-DEFAULT-POSTGRES. For any user, host, and port option presence and any
`PARAMS`, if neither `NAME` nor service is configured then Django's default
database argument is appended after `PARAMS`:

`["psql"] + user_option + host_option + port_option + PARAMS + ["postgres"]`

C-SERVICE-NO-DBNAME. For any user, host, and port option presence and any
`PARAMS`, if service is configured and `NAME` is absent then no positional
database argument is appended:

`["psql"] + user_option + host_option + port_option + PARAMS`

F-ENV. Environment variables produced from password, service, passfile, and SSL
settings are unchanged by V1.

F-COMPAT. The public method signatures and callers are unchanged: `dbshell`
still passes `parameters` to `connection.client.runshell()`, and
`settings_to_cmd_args_env()` still returns `(args, env)`.
