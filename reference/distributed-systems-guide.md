# Distributed Systems And Enterprise Scale Guide

Use this when the task is broader than messaging: microservices, service boundaries, scaling, resilience, multi-region, data ownership, service mesh, platform engineering, enterprise governance, or distributed failure modes.

## Core stance

Messaging and integration patterns cover how systems communicate. Distributed systems design also has to answer:

- How services are bounded and owned.
- How data is partitioned, replicated, cached, and kept consistent enough.
- How the system behaves under partial failure, overload, deploys, and regional loss.
- How teams operate, secure, observe, and evolve the platform.

Name integration patterns when messages are involved. Name distributed-systems patterns when topology, scale, consistency, or resilience is the main risk.

## Distributed systems checklist

Run this in addition to the reliability checklist when the task crosses process, machine, region, or team boundaries:

1. **Boundary and ownership?** What service owns the data, API, SLO, and on-call path?
2. **Consistency model?** Strong, read-your-writes, monotonic reads, causal, eventual, or best-effort? Where can stale reads appear?
3. **Scaling axis?** Horizontal replicas, partitions/shards, tenants, regions, async buffering, cache/CDN, or read replicas?
4. **Failure mode?** What happens under timeout, retry storm, partial outage, slow dependency, deploy rollback, and region loss?
5. **Backpressure and load shedding?** Where are queues bounded, requests rejected, rate limits enforced, and overload signaled?
6. **Data movement?** Which data is replicated, denormalized, cached, or materialized? How is it invalidated or rebuilt?
7. **Observability?** SLOs, golden signals, traces, high-cardinality dimensions, saturation, queue age, and dependency health.
8. **Operations and governance?** Runbook, capacity plan, security boundary, tenant isolation, compliance, and cost controls.

## Pattern map

| Need | Pattern | Modern realization |
| --- | --- | --- |
| Isolate service ownership | Bounded Context + Database Per Service | DDD context map, service catalog, API/event contracts |
| Prevent cascading failure | Circuit Breaker + Bulkhead + Timeout | Envoy/Istio/Linkerd, resilience libraries, Dapr resiliency |
| Survive overload | Backpressure + Load Shedding + Rate Limiting | Token bucket, Envoy local/global rate limit, API gateway quotas |
| Scale workers by demand | Horizontal Autoscaling + Queue-Based Scaling | Kubernetes HPA, KEDA ScaledObject, Lambda concurrency |
| Scale data writes | Sharding/Partitioning | DynamoDB partition key, Kafka partitions, Citus, Cassandra, Vitess |
| Scale reads | Cache-Aside + Read Replica + CQRS Read Model | Redis, CDN, RDS replicas, Elasticsearch/OpenSearch |
| Reduce latency globally | Edge Cache + Regional Read Replica | CloudFront/Fastly, global database replicas, local read models |
| Coordinate exclusive work | Lease + Fencing Token | etcd/Consul/ZooKeeper, DynamoDB conditional writes |
| Elect a leader | Leader Election | Kubernetes Lease API, etcd/Consul sessions |
| Replicate safely | Change Data Capture + Materialized View | Debezium, DynamoDB Streams, Kafka Connect, Flink |
| Handle multi-step consistency | Saga / Process Manager | Temporal, Step Functions, Camunda |
| Release safely | Progressive Delivery | Canary, blue/green, feature flags, Argo Rollouts, Flagger |
| Protect tenants | Tenant Isolation + Quotas | per-tenant rate limits, shard placement, IAM boundaries |
| Observe distributed flow | Distributed Tracing + Correlation IDs | OpenTelemetry, traceparent, Prometheus, Grafana, Tempo/Jaeger |

## Service boundaries

Good service boundaries usually have:

- One clear business capability.
- One owning team.
- One source of truth for owned data.
- Public APIs/events that hide internal storage.
- Independent deployability.
- Explicit SLOs.

Red flags:

- "Shared service" that owns no business capability.
- Multiple services write the same OLTP tables.
- Services split by technical layer (`user-api`, `user-db-service`) rather than capability.
- Every change requires synchronized deploys across teams.
- Events leak internal ORM models.

Use a modular monolith when team count, domain clarity, or operational maturity does not justify distributed deployment.

## Consistency and data ownership

Choose the weakest consistency that satisfies the business invariant, and write it down.

| Requirement | Prefer | Avoid |
| --- | --- | --- |
| Must reject overspend or double booking immediately | Single writer, transaction, compare-and-set, reservation/lease | Async event after the fact |
| User must see their own write | Writer-owned read path or workflow status | Waiting on arbitrary downstream projections |
| Search/reporting freshness can lag | CDC to read model | Shared OLTP database |
| Multi-service outcome must converge | Process Manager with commands/events/compensations | Hidden choreography with no state query |
| Concurrent global edits | CRDT/merge policy or single-region writer | Last-write-wins without business review |

Do not say "eventual consistency" without naming max acceptable lag, reconciliation, and user experience.

## Scaling patterns

Scale in this order:

1. Reduce work: cache, coalesce, batch, filter, precompute.
2. Add replicas: horizontal scale stateless services.
3. Partition: split by tenant, aggregate, account, region, or key.
4. Move work async: queues, streams, background workers.
5. Materialize reads: read models, search indexes, replicas.
6. Shift to edge: CDN, edge compute, regional caches.

Ask:

- What is the bottleneck: CPU, memory, DB locks, network, connection pool, partition, downstream rate limit, or queue age?
- Is the workload stateless or stateful?
- Which key creates hot partitions?
- What is the maximum useful concurrency before the dependency saturates?
- What is the scale-down behavior and cold-start impact?

Kubernetes HPA is good for CPU/memory/custom metrics. KEDA is good when scaling should follow external event sources such as queue length, Kafka lag, SQS depth, or Prometheus metrics.

## Backpressure, rate limiting, and load shedding

Every distributed system needs a plan for too much work.

- **Timeout:** Bound how long callers wait.
- **Retry budget:** Retrying cannot amplify an outage.
- **Circuit breaker:** Fail fast when dependency is unhealthy.
- **Bulkhead:** Separate pools for critical vs non-critical traffic.
- **Queue limit:** Bounded queue with explicit reject/drop policy.
- **Rate limit:** Per-user, per-tenant, per-token, and global budgets.
- **Load shedding:** Return 429/503 or drop low-priority work before collapse.

Avoid unbounded goroutines, unbounded channels, unlimited HTTP connection pools, and unlimited broker prefetch.

## Caching patterns

| Pattern | Use when | Risks |
| --- | --- | --- |
| Cache-aside | App can tolerate miss path to source | Stampede, stale reads |
| Read-through | Central cache abstraction is acceptable | Hidden dependency, hard testing |
| Write-through | Writes must populate cache synchronously | Higher write latency |
| Write-behind | Throughput matters more than immediate persistence | Data loss/ordering risk |
| CDN/edge cache | Static/public/semi-public content | Invalidation complexity |
| Negative cache | Repeated misses are expensive | Caching transient absence too long |

Always specify TTL, invalidation trigger, stampede protection, and stale-data tolerance.

## Sharding and partitioning

Pick partition keys by access pattern and hot-key risk:

- Tenant sharding helps isolation but large tenants can dominate.
- Aggregate/entity sharding preserves per-entity ordering.
- Region sharding helps latency and residency but complicates global workflows.
- Hash sharding balances load but hurts range queries.
- Time partitioning helps retention but can hot-spot current time.

Plan for resharding before launch: key migration, dual reads/writes, backfill, verification, rollback, and tenant move operations.

## Coordination and locks

Distributed locks are a last resort. Prefer idempotency, single-writer ownership, queues, or compare-and-set.

If a lock/lease is required:

- Use a lease with expiry.
- Use fencing tokens so stale lock holders cannot write.
- Make critical sections short.
- Decide what happens during clock skew, network partition, and process pause.
- Monitor lock wait time and expired leases.

Tools: etcd, Consul, ZooKeeper, PostgreSQL advisory locks for single-db scope, DynamoDB conditional writes with version/fencing fields.

## Multi-region patterns

| Pattern | Use when | Trade-off |
| --- | --- | --- |
| Active-passive | Simple DR, lower conflict risk | Failover time and regional idle cost |
| Active-active | Low latency and regional resilience | Conflict resolution and operational complexity |
| Single writer, multi-region reads | Stronger write consistency with local reads | Write latency for remote regions |
| Cell-based architecture | Blast-radius isolation at scale | Routing, balancing, and tenant placement complexity |
| Global queue/stream bridge | Regional event distribution | Duplicate/reorder handling and replay design |

Name RPO, RTO, data residency, failover trigger, failback plan, and conflict policy.

### Cell-based architecture

A cell is an isolated stack - compute, storage, queues, dashboards, alarms - that serves a partition of users or tenants. Failures inside one cell are contained: blast radius is one cell, not the whole system. A bad deploy, a poison message, a hot tenant, or a regional dependency outage that brings down a cell does not bring down the others.

- **Tenant placement** is by deterministic routing: `cellId = hash(tenantId) mod N`, static assignment in a config table, or shuffle sharding (each tenant pinned to a small subset of cells) for additional isolation between noisy neighbours.
- **Routing layer** is intentionally thin (`tenantId -> cellId` lookup). It is the only globally critical service, so it must be drastically simpler and more reliable than the cells it routes to. No business logic, no joins, no per-request DB calls beyond the lookup.
- **Deploys** are per-cell and waved (e.g. 1% of cells, then 10%, then 50%, then 100%) so a bad change is caught while still small. Each cell has its own pipeline, monitoring, and rollback.
- **Origin**: AWS Builders' Library pattern; widely used at AWS (S3, DynamoDB, Route 53), Salesforce, Slack, Shopify.
- **Trade-off**: routing complexity, deploy fan-out, observability fan-in, and cross-cell migration tooling (you must support moving a tenant between cells without downtime). Worth it once the blast radius of a single failure exceeds what one team can absorb.

## API gateway, BFF, and service mesh

Use an API gateway for north-south concerns:

- AuthN/AuthZ enforcement.
- Request routing.
- Rate limiting.
- WAF/threat protection.
- Public API versioning.

Use BFF when different clients need different aggregation and UX-specific contracts.

Use service mesh/sidecar/proxy for east-west concerns:

- mTLS.
- Traffic shifting.
- Circuit breaking.
- Outlier detection.
- Retries/timeouts.
- Distributed tracing.

Do not let gateways, BFFs, or mesh policies hide business logic.

## Progressive delivery

Enterprise-scale systems need release patterns:

- Feature flags for behavior rollout and kill switches.
- Canary deploys for traffic sampling.
- Blue/green for fast rollback.
- Shadow traffic for non-mutating comparison.
- Dark launch for warming infrastructure.
- Contract-first deployment for producers/consumers.

Every rollout needs metrics, abort thresholds, and rollback ownership.

## Observability and SLOs

Use the right level:

- **User journey SLO:** checkout completed within N seconds.
- **Service SLO:** API success/latency by route and tenant tier.
- **Dependency SLO:** DB, broker, cache, third-party latency/error.
- **Queue SLO:** age of oldest message, not only message count.
- **Workflow SLO:** time from start to terminal state.

Measure:

- RED: rate, errors, duration.
- USE: utilization, saturation, errors.
- Golden signals: latency, traffic, errors, saturation.
- High-cardinality dimensions carefully: tenant, route, event type, consumer group.

Logs without correlation ids and traces are insufficient for distributed debugging.

## Enterprise governance

Enterprise-ready distributed systems need:

- Service catalog with owner, tier, SLO, dependencies, APIs/events.
- Architecture decision records for major distributed boundaries.
- Data classification and residency map.
- Dependency graph and critical path map.
- Cost allocation by service/tenant/team.
- Runtime policy: auth, mTLS, secrets, image provenance, network policy.
- Incident runbooks and game days.
- Deprecation policy for APIs/events.

## Distributed systems anti-patterns

- Distributed monolith: services cannot deploy independently.
- Shared database integration between teams.
- Retry storms without budgets.
- Cache used as source of truth without durability plan.
- Unbounded queues hiding overload.
- Synchronous chain of many services for user writes.
- Leader election without fencing.
- Global locks on hot paths.
- Active-active with no conflict policy.
- Autoscaling on CPU while bottleneck is DB or queue age.
- Per-tenant noisy-neighbor risk with no quota.
- Gateway or mesh contains business rules.
- "Five nines" service built on three nines dependencies with no fallback.

## Primary sources worth checking

- Kubernetes Services: https://kubernetes.io/docs/concepts/services-networking/service/
- Kubernetes Horizontal Pod Autoscaling: https://kubernetes.io/docs/concepts/workloads/autoscaling/horizontal-pod-autoscale/
- KEDA concepts: https://keda.sh/docs/latest/concepts/
- Envoy circuit breaking: https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/upstream/circuit_breaking
- Envoy outlier detection: https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/upstream/outlier
- Dapr resiliency: https://docs.dapr.io/concepts/resiliency-concept/
- OpenTelemetry: https://opentelemetry.io/docs/
- AWS Builders' Library, avoiding fallback in distributed systems: https://aws.amazon.com/builders-library/avoiding-fallback-in-distributed-systems/
- AWS Builders' Library, workload isolation using shuffle sharding: https://aws.amazon.com/builders-library/workload-isolation-using-shuffle-sharding/
