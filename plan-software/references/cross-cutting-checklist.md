# Cross-cutting checklist

Concerns that don't belong to any single feature but change the shape of most of
them. Walk this list at **stage 03 (scope)** and re-check it at **stage 05 (data
model)**. Each one gets a decision or an explicit "not needed, because…" — an
unanswered item here is the usual cause of a plan collapsing in week six.

## Identity & access

- **Authentication** — how do users prove who they are? Email/password, SSO,
  magic link, third-party? Who provisions accounts?
- **Roles & permissions** — is it a flat user/admin split, role-based, or
  per-resource? Can permissions differ per record (owner vs shared)?
- **Tenancy** — is data partitioned by organisation/team/workspace? If yes,
  every table and every query is affected. Decide before the data model.
- **Impersonation & support access** — can staff act as a user? It's a permission
  model change, not a feature.

## Data lifecycle

- **Soft delete vs hard delete** — and what "deleted" means for things that
  reference the deleted record.
- **Audit / history** — does anyone need to know who changed what and when? Is
  the previous version recoverable? Retrofitting this is expensive.
- **Drafts & versioning** — can a record exist in an incomplete state? That's a
  lifecycle state, so it belongs in the domain model too.
- **Data retention & export** — legal or contractual obligations to delete or
  hand over data.

## Time & background work

- **Scheduled jobs** — anything that must happen without a user present:
  reminders, expiry, recurring generation, digests.
- **Long-running operations** — imports, exports, report generation, anything
  slower than a request. These need progress state the UI can read.
- **Idempotency & retries** — for anything triggered by a webhook, queue or
  external system.

## Communication

- **Notifications** — email, in-app, push, SMS? Triggered by what? Can users
  configure them? Digest or immediate?
- **Transactional email** — who sends it, from what domain, with what templates.

## External surface

- **Integrations** — third-party systems read from or written to. For each: auth
  method, rate limits, failure behaviour, whether it's on the critical path.
- **File & media storage** — where do uploads live, what limits, is access
  authenticated, do you need thumbnails or virus scanning?
- **Public API or webhooks** — if others build against you, contracts become
  versioned commitments.

## Operational

- **Environments** — local, staging, production. How is data seeded? How do you
  test something that emails real people?
- **Observability** — errors, logs, and the one or two business metrics anyone
  will actually ask about.
- **Configuration** — what varies per environment or per tenant, and where it
  lives.

## Non-functional

- **Expected scale** — rows, concurrent users, largest realistic query. Only
  matters where it changes a decision; write the number, not "should scale".
- **Availability & recovery** — what breaks if it's down for an hour, and what's
  the backup story?
- **Compliance** — PII, payment data, health data, regional hosting. These
  constrain the data model directly.
- **Accessibility & localisation** — decide now if either is a requirement;
  both are structural, not cosmetic.
