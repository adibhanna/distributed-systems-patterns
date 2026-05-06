# Security And Compliance Guide

Use this when messages, events, workflows, APIs, logs, traces, DLQs, or replay stores may contain sensitive data or cross trust boundaries.

## Security checklist

- [ ] Message payloads contain no secrets: passwords, tokens, API keys, private keys.
- [ ] Headers, attributes, logs, traces, and DLQs are treated as data stores.
- [ ] PII/PHI/PCI fields are tagged in schema and redacted from logs.
- [ ] Encryption in transit and at rest is enabled.
- [ ] Producer and consumer identities are least-privilege.
- [ ] Webhooks and partner events are signed and timestamp/replay-window checked.
- [ ] Replay/redrive roles are restricted and audited.
- [ ] Retention and deletion policies match legal/privacy requirements.
- [ ] Tenant isolation is enforced in auth, partitioning, logging, metrics, and support tooling.
- [ ] Cross-region replication complies with data residency requirements.

## Threat model prompts

- Who can publish to this channel?
- Who can subscribe or replay?
- Can a malicious producer poison consumers?
- Can a tenant infer another tenant's data through lag, errors, IDs, or metrics?
- What happens if a message is replayed maliciously?
- Are signatures verified before storing or processing webhooks?
- Are DLQs accessible to broad support roles?
- Can schema changes introduce sensitive fields accidentally?

## Common controls

| Risk | Control |
| --- | --- |
| Spoofed event | mTLS/IAM/SASL, signed payloads, producer ACLs |
| Replay attack | Timestamp, nonce/delivery id, dedup store, signature validation |
| Sensitive DLQ | Redaction, encryption, narrow IAM, retention, audit logging |
| Tenant leakage | Tenant-scoped auth, partitioning, quotas, per-tenant observability |
| Over-permissioned consumers | Topic/queue ACLs per service, separate read/write roles |
| Immutable log privacy | Field minimization, tokenization, retention, legal review |
| Trace/log leakage | Redaction processors, baggage restrictions, log sampling policy |

## GDPR/right-to-delete and immutable logs

Immutable event logs complicate deletion. Prefer:

- Do not put unnecessary PII in events.
- Use opaque IDs and fetch sensitive data from the owning service when needed.
- Tokenize or encrypt fields with erasable keys where policy requires erasure.
- Keep retention as short as business/replay needs allow.
- Separate operational events from audit records with different retention.

## Webhook security

Webhook receivers should:

1. Read raw body before parsing.
2. Verify signature using provider-specific scheme.
3. Validate timestamp freshness.
4. Dedupe provider delivery id.
5. Store only what is necessary.
6. Return quickly after durable accept.
7. Process asynchronously.

## Workload identity (SPIFFE/SPIRE, OIDC)

In distributed systems, services need stable cryptographic identities to authenticate to each other - mesh mTLS, broker ACLs, downstream APIs, partner integrations. Long-lived secrets (static API keys, baked-in service-account credentials) leak through logs, repos, and stale rotations; they also tie authZ to a credential rather than to a workload.

SPIFFE / SPIRE. SPIFFE defines a portable workload-identity standard. Each workload gets a SPIFFE ID URI of the form `spiffe://trust-domain/path/to/workload` that is independent of host, IP, or transport. SPIRE is the most common open-source SPIFFE issuer; it attests workloads (via Kubernetes, AWS, Unix process attributes, etc.) and distributes short-lived X.509 SVIDs or JWT-SVIDs over the local Workload API socket. Service mesh stacks - Istio, Linkerd, Consul - use SPIFFE under the hood for mesh mTLS, so adopting a mesh often gives you SPIFFE identities for free.

OIDC for cloud / non-mesh workloads. Outside a mesh, workload-identity tokens map to short-lived cloud credentials: AWS IAM Roles Anywhere, GCP Workload Identity Federation, Azure Workload Identity, and GitHub OIDC for CI all exchange a workload-issued JWT for cloud credentials with a short TTL. Use these instead of long-lived access keys; they remove the secret-distribution problem entirely.

What to require for any cross-service authN claim:

- A stable identity (SPIFFE ID or OIDC subject) bound to the workload, not to a credential file.
- Short credential lifetime - 1 hour or less is the practical target; SPIRE SVIDs default to ~1h and rotate automatically.
- Automatic rotation handled by the issuer, not by humans or deploy scripts.
- Audit trail mapping identity to action - logs and traces should record the SPIFFE ID or OIDC `sub`, not just an opaque service name.

Brokers and identity. Bind broker ACLs to workload identities, not to shared service accounts. Kafka supports SASL/OAUTHBEARER with OIDC for token-based authN; RabbitMQ supports external auth via x509 / mTLS / OAuth2; NATS uses JWT-based authN with nkey workload keys. The pattern in each: the broker validates the workload-identity claim and authorizes based on identity, so a leaked credential cannot be reused outside its intended workload.

Anti-patterns:

- Shared API key checked into a secret manager and read by every replica - rotation is impossible without coordinated downtime, and the blast radius is the whole fleet.
- Service account that survives multiple deployments and outlasts the workloads that originally used it.
- "Service-to-service" calls riding a user's OAuth token - the call inherits the user's permissions, so authZ is wrong on both ends.
- Long-lived JWTs (24h+) without rotation - effectively static bearer tokens with worse audit trails than IAM keys.

## Compliance evidence

For enterprise reviews, capture:

- Data classification table.
- Retention and deletion policy.
- IAM/ACL matrix.
- Encryption configuration.
- Audit log location.
- DLQ access policy.
- Redaction test evidence.
- Threat model decisions.

## References

- https://spiffe.io/docs/latest/spiffe-about/overview/
- https://spiffe.io/docs/latest/spire-about/spire-concepts/
- https://docs.aws.amazon.com/rolesanywhere/latest/userguide/introduction.html
- https://cloud.google.com/iam/docs/workload-identity-federation
