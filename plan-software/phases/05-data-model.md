# Stage 05 — Data model

**Depends on:** `01-domain-model`, `02-use-cases`, `03-scope` · **Produces:** `05-data-model.md`

The most expensive thing in the project to change later. It comes after use
cases deliberately: only now do you know the access patterns, the permission
boundaries and the lifecycle states the schema has to represent.

## What to do

1. **Translate domain entities into tables/collections** — same names as the
   glossary. Where the schema needs a concept the domain doesn't have (join
   tables, denormalised counters), say why.
2. **Columns with real types and nullability.** Nullable is a decision, not a
   default: each nullable column should have a reason.
3. **Lifecycle states become columns or rows.** A simple status enum, or a
   separate transitions table if history matters. The audit decision from stage
   03 determines which — apply it here rather than re-deciding.
4. **Apply every cross-cutting decision from stage 03.** Tenancy key on every
   table or not. Soft-delete columns and what that does to unique constraints.
   Audit columns. Don't re-litigate; implement.
5. **Walk the read paths.** For each significant use case and each screen from
   stage 04, write the query it implies. This is where you find the missing
   index, the N+1, and the relationship you modelled backwards. A table nothing
   queries efficiently is a bug you can still fix for free today.
6. **Constraints and cascades** — foreign keys, unique constraints, and what
   happens to children when a parent is deleted (which interacts with soft
   delete; be explicit).
7. **Note the migration story** if there's existing data.

## Artifact template

```markdown
---
phase: 05-data-model
track: <full|compact>
status: draft
depends_on: [01-domain-model, 02-use-cases, 03-scope]
updated: <date +%F>
---

# Data model — <project>

## Tables
### `projects`
| Column | Type | Null | Notes |
|--------|------|------|-------|
| id | uuid pk | no | |
| org_id | uuid fk → orgs | no | tenancy key, indexed |
| status | enum(draft,active,archived) | no | lifecycle from 01 |
| deleted_at | timestamptz | yes | soft delete |

<Repeat per table.>

## Relationships & cascades
| Parent | Child | On delete | Notes |
|--------|-------|-----------|-------|

## Constraints
- `unique(org_id, slug) where deleted_at is null`

## Access patterns
| Use case / screen | Query | Index used |
|-------------------|-------|-----------|

**Problem patterns found:** <queries that need a new index, denormalisation, or
a schema change — and the change made>

## Migrations
<Existing data to move, or "greenfield".>

## Assumptions & open questions
```

## Gate

*Does every screen's read path work without a pathological query, and is every
stage-03 cross-cutting decision actually reflected here?*

Then propose stage 06 (contracts).
