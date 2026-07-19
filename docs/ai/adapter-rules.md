# AI Adapter Rules

Adapters depend only on public API and SPI. They must not import
`Identity.Internal` and must pass the conformance harness before advertising a
profile.

External provider adapters must validate protocol assertions before calling
Identity. They pass normalized assertions only, never raw provider assertions,
and must not ask Identity to auto-link by email or contact value.
