# Go Implementation Patterns

Use this when writing production Go for distributed systems, consumers, producers, workers, APIs, and workflows.

## Defaults

- Pass `context.Context` through every I/O boundary.
- Configure HTTP clients with timeouts.
- Bound goroutines, channels, worker pools, queues, and retries.
- Use structured logs with message id, correlation id, trace id, tenant, topic, partition, offset, attempt.
- Expose metrics for rate, errors, duration, saturation, queue age, retry, DLQ.
- Handle SIGTERM gracefully.
- Keep broker clients behind small interfaces for tests.

## Worker pool sketch

```go
type Job struct {
	ID string
}

func RunWorkers(ctx context.Context, n int, jobs <-chan Job, handle func(context.Context, Job) error) error {
	errs := make(chan error, n)
	for i := 0; i < n; i++ {
		go func() {
			for {
				select {
				case <-ctx.Done():
					errs <- ctx.Err()
					return
				case job, ok := <-jobs:
					if !ok {
						errs <- nil
						return
					}
					if err := handle(ctx, job); err != nil {
						errs <- err
						return
					}
				}
			}
		}()
	}
	for i := 0; i < n; i++ {
		if err := <-errs; err != nil {
			return err
		}
	}
	return nil
}
```

## HTTP client defaults

```go
client := &http.Client{
	Timeout: 5 * time.Second,
	Transport: &http.Transport{
		MaxIdleConns:        100,
		MaxIdleConnsPerHost: 20,
		IdleConnTimeout:     90 * time.Second,
	},
}
```

## Idempotency interface

```go
type Deduper interface {
	SeenOrMark(ctx context.Context, key string, ttl time.Duration) (seen bool, err error)
}
```

## Retry classifier

```go
type FailureKind int

const (
	Permanent FailureKind = iota
	Transient
)

type Classifier func(error) FailureKind
```

## Graceful shutdown checklist

- Stop accepting new requests/messages.
- Cancel polling context.
- Let in-flight work finish within deadline.
- Commit/ack only completed work.
- Flush logs/traces/metrics.
- Close broker/database clients.

## Temporal Go reminders

- Workflow code must be deterministic.
- Use `workflow.Now`, not `time.Now`.
- Put network calls and random values in Activities.
- Activities must be idempotent.
- Version long-running workflows before incompatible changes.
