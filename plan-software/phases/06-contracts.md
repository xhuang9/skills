# Stage 06 — Contracts

**Depends on:** `02-use-cases`, `04-screen-map`, `05-data-model` · **Produces:** `06-contracts.md`

The server boundary: endpoints or server actions, payload shapes, errors, auth.
The most-skipped stage, and the one that decides whether two people can build
front and back independently or have to keep asking each other what a response
looks like.

## What to do

1. **One entry per use case, not per table.** Contracts follow what users do.
   `POST /projects/:id/submit` beats a generic PATCH that the client has to know
   how to drive.
2. **Write request and response shapes concretely** — actual field names and
   types, not "returns the project". The response shape should be driven by what
   the screen from stage 04 needs to render, including nested data, so the
   client doesn't need three round-trips.
3. **Define the error taxonomy once**, then reference it. A small closed set of
   error codes with a consistent envelope. Every endpoint lists which ones it can
   return — those are exactly the failure modes from stage 02, so cross-check.
4. **State auth per endpoint** from the permissions matrix: who may call it, and
   what per-record check applies. Anything with a per-record rule needs it
   written here or it will be forgotten.
5. **Validation rules** — the invariants from stage 01 have to be enforced
   somewhere; say whether it's the database constraint, the endpoint, or both.
6. **Cover the non-HTTP surfaces too** — webhooks received, jobs enqueued,
   emails sent. They're contracts with the same failure and idempotency
   questions.

## Artifact template

```markdown
---
phase: 06-contracts
track: <full|compact>
status: draft
depends_on: [02-use-cases, 04-screen-map, 05-data-model]
updated: <date +%F>
---

# Contracts — <project>

## Conventions
- Base: `/api/v1` · auth: `Authorization: Bearer <jwt>` · JSON, snake_case
- Error envelope: `{ "error": { "code": "...", "message": "...", "field": "..." } }`

## Error taxonomy
| Code | HTTP | Means |
|------|------|-------|
| `not_found` | 404 | resource absent or not visible to caller |
| `state_conflict` | 409 | action invalid for the record's current state |

## Endpoints

### `POST /projects/:id/submit` — UC-04
- **Auth:** Member; must be assigned to the project and it must be `draft`
- **Request:** `{ "note": string | null }`
- **Response 200:** `{ "id": uuid, "status": "submitted", "submitted_at": ts }`
- **Errors:** `state_conflict` (already submitted), `forbidden`, `not_found`
- **Enforces:** invariant "a project can only be submitted once"

<Repeat per use case.>

## Background & external surfaces
| Surface | Direction | Payload | Idempotency |
|---------|-----------|---------|-------------|

## Contract → use case coverage
| Use case | Endpoint(s) | 
|----------|-------------|

## Assumptions & open questions
```

## Gate

*Could a front-end and a back-end developer build against this in separate rooms
without talking?*

Then propose stage 07 (lo-fi) on the full track, or stage 10 + 11 on compact.
