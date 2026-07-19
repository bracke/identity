# Identity Threat Model

Version: 1.0.0-dev

Protected assets include passwords, bearer tokens, recovery codes, TOTP seeds,
peppers, keys, verifier records, principals, bindings, sessions, transactions,
attempts, lockout state, replay markers, provider trust records, and events.

Security objectives are confidentiality, integrity, availability, privacy, and
accountability.

Trust boundaries: untrusted caller, transport adapter, Forms and Validation,
repository, cryptolib, key provider, external provider adapter, notification
infrastructure, and the Authorization boundary.

Attacker capabilities include arbitrary inputs, replay, concurrency races,
timing observation, subject guessing, active token theft, database read
compromise, selected persistence corruption, provider misuse, resource
exhaustion, event injection, secret leakage, and supply-chain compromise.

Residual risk is explicitly bounded by adapter correctness, cryptolib
correctness, compiler/runtime behavior for memory clearing, and durable
repository integrity.
