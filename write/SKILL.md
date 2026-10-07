---
name: write
description: The wording rules for every piece of English you produce, routed by who reads it. Read this before writing or revising any prose, then the file for the reader. Readers - me (chat replies, findings, plans and explanations for the developer), llm (.readme docs, CLAUDE.md, skill files, sub-agent prompts, handoffs, memory), pm (PM and client replies, quotes, handover docs, ticket comments), dev (commit messages, PR bodies, code review findings, technical and support docs), public (blog posts, landing pages, ads, emails, product and web copy, CTAs, end-user replies, notifications). Auto-invoke whenever prose is about to be written, when asked for a personal, casual or "from me" reply to a PM, and when asked to shorten, tighten, condense, compress, trim, reword, rewrite, localise into Australian English, or fix copy that "reads like AI" or "sounds robotic".
---

# write

How every sentence gets worded, for any reader. Four steps:

1. Pick the reader. Read that reader's file.
2. Apply the core rules below. They hold for every reader.
3. If another skill governs the output's format, it sets the sections, order, template and length. These rules set the wording inside them.
4. Run the check at the end.

## Pick the reader

| Reader | File | Typical outputs |
| --- | --- | --- |
| **me**, the developer | `me.md` | Chat replies, status updates, findings, plans, review write-ups, explanation docs, design rationale |
| **llm**, another agent | `llm.md` | `.readme/` chunks, CLAUDE.md and AGENTS.md, skill files, sub-agent and Codex prompts, handoffs, memory files, task context |
| **pm**, a non-technical Australian PM or client | `pm.md` | Ticket replies, advisory replies, quotes, handover docs, client reports. Its personal variant covers first-person replies to a named PM |
| **dev**, another developer | `dev.md` | Commit messages, PR descriptions, issue comments, code review findings, technical docs, support docs |
| **public**, anyone | `public.md` | Blog posts, landing pages, ads, emails, product and App Store copy, end-user bug replies, system notifications |

Pick by who reads it first. A PR description is dev even when I asked for it. A prompt for a sub-agent is llm even when it will later be shown to me.

### Mixed readers

One output often serves several readers, such as a technical issue reply that a PM forwards and a developer acts on. Then:

- Every section has one reader, and follows that reader's file.
- Order sections from least technical to most. The first section must stand alone for the least technical reader.
- Never mix registers inside a section. A PM sentence holding a file path is a dev sentence in the wrong place.
- Evidence comes last, complete, and is never compressed for length.

## What never changes

Leave these exactly as they are, for every reader: code, identifiers, file paths, command output, configuration values, error strings, URLs, and anything quoted from a person, document or system. Rewording them changes meaning or breaks them.

## Australian English

- `-ise` and `-yse` endings: organise, analyse, recognise.
- `-our` endings: colour, behaviour, favour.
- `-re` endings in theatre, centre, metre.
- `towards`, `per cent`, `judgement`, `programme` for a scheduled series, `licence` as the noun and `license` as the verb, `practice` as the noun and `practise` as the verb.
- Single quotation marks for primary quotes, double inside them. Straight quotes, never curly.
- Punctuation outside the closing quotation mark unless the quoted material is a full sentence.
- No serial comma unless clarity needs it.
- Australian terms over American ones: `mobile`, `car park`, `holiday`, `postcode`, `autumn`.
- Dates as 4 September 2026. Never 9/4/26.

Three exceptions, and only three:

- **Identifiers and code keep their own spelling.** `color`, `initialize`, `licenseKey`, a CSS property, an API field, a package name, a database column.
- **Quotations keep the original.**
- **A document already established in another variant keeps it.** Match the file you are editing, and say once that you did.

## Sentences and paragraphs

- One idea per sentence, with a verb. About 25 words. If the reader has to backtrack to parse it, split it.
- A paragraph holds 60 words and four sentences at most. Past that, split at the change of idea. Reader files and format skills may set a tighter limit.
- The first sentence of any unit carries its point. Heading, paragraph, bullet, section, reply.
- Headings carry the point, in sentence case. Write "Pick the mode first" in place of "Modes".
- Active voice. Name the actor: "queries are validated" becomes "the compiler validates queries". Passive is fine only when the actor is unknown or does not matter.
- Condition before the instruction, warning before the step it guards. "To delete the document, click Delete."
- Common case first, exceptions after.

## Precision

These silently produce a wrong reading. Check them every time.

- Put "only" and "not" next to the word they change. "Only fails on growth" and "fails only on growth" differ.
- Every "it", "they" and "this" points at one obvious thing. Repeat the noun when in doubt. Never let "this" or "which" point at a whole clause.
- One name per thing, everywhere. Never cycle synonyms (protagonist, main character, hero) for variety.
- Break up long noun strings. "The proto import budget check script" becomes "the script that checks the proto-import budget".
- Keep the verb in a parallel clause. "Phase 1 moves the converters and Phase 2 the runtime" leaves Phase 2 without one.
- Keep "the" and "a" where they disambiguate. "Remove backup file" reads two ways. "Remove the backup file" reads one.
- Say which parts "and" or "or" joins when the sentence can group two ways. "Both...and" and "either...or" are free.
- Write the real symbol, file, flag or command name. A synonym or a description of it sends the reader searching.
- Link text says where it goes. Never "click here".
- No slashes (`a/b`, `and/or`). Write "a, b, or both". No "(s)" plurals.
- Never "simply", "easy" or "quickly" in a procedure.
- Do not widen scope with a word. "Every page fails" is false when the data covers three pages.

## Banned constructions

- **Preamble.** No opener that announces, restates the request, or praises it: "Great question", "Let me...", "Sure!", "To answer your question". Start with the content.
- **Throat-clearing.** "It is worth noting that", "It is important to note that", "What makes this important is". Delete.
- **Closing recap** of what the reader has just read, and **closing pleasantries**: "Hope this helps", "Let me know if...", "Happy to clarify". Stop when the content stops.
- **Contrast framing.** "It is not X, it is Y", "not X but Y", "not just X, but Y", "X rather than Y", "X, not Y". State Y. When X is itself a fact the reader needs, write two plain statements: "Reading is confirmed. Writing is untested."
- **A restating sentence** that repeats the one before it for emphasis or rhythm.
- **A word repeated in consecutive sentences.** Restructure or use a pronoun. Never swap in a synonym.
- **Rule of three.** Use the natural number of items.
- **False ranges.** "From X to Y" when X and Y are not on one scale.
- **Sycophancy and chatbot phrases.** "You're absolutely right!", "Of course!", "Certainly!", "Found the smoking gun!" Respond directly.
- **Cutoff disclaimers.** "While specific details are limited..." Find the source or cut the claim.
- **Generic conclusions.** "The future looks bright." State the plan or the fact.
- **How the work was produced**, in anything a PM, client, colleague or the public reads. No `agent`, `AI`, `Claude`, `automated by`, `generated`, and no column splitting hours by who typed. The reader buys the outcome and the responsibility for it. Head a build column `Build`, describe checks as `captured` or `swept`, and keep the mechanism for internal files only.

## Words

- **AI vocabulary.** Additionally, crucial, delve, enduring, enhance, fostering, garner, interplay, intricate, landscape (abstract), pivotal, showcase, tapestry (abstract), testament, underscore, vibrant. Use the plain word.
- **Puffery and promotion.** "Pivotal moment", "testament to", "evolving landscape", "setting the stage", "indelible mark", "deeply rooted", "nestled", "breathtaking", "groundbreaking", "renowned", "stunning", "must-visit". State what happened.
- **Superficial -ing tails.** "...highlighting...", "...ensuring...", "...reflecting...", "...showcasing...". Delete or expand with a real source.
- **Vague attribution and name-dropping.** "Experts believe", "Industry reports suggest", "Some critics argue", a list of outlets. Name one source and what it said, or cut.
- **Formulaic challenges.** "Despite challenges, it continues to thrive." State the specific fact.
- **Fancy "is".** "Serves as", "stands as", "boasts", "features". Write "is" or "has".
- **Plain words.** `use` over `utilise` or `leverage`, `help` over `facilitate`, `many` over `numerous`, `if` over `in the event that`, `start` over `commence`, `about` over `approximately`.
- **Filler.** "In order to" becomes "to". "Due to the fact that" becomes "because".
- **Abstract metaphor nouns.** Substrate, wedge, vector, locus, vantage, nexus, primitive (as noun), harness (as metaphor), surface (as in "API surface"), bedrock, scaffolding (as metaphor), modality, paradigm, gold-plating, ratchet (as metaphor), evacuate (for moving code), endgame, north star, flywheel. Use the concrete word: "base", "add", "way", "more than the job needs", "a limit that only tightens", "move out", "the last phase".
- **Idioms.** "Circle back", "get the ball rolling", "on the same page", "move the needle". Write the literal action.
- **Adjectives and adverbs carrying no fact.** `significant`, `robust`, `comprehensive`, `critical` when nothing measures them. "Runs quickly" becomes the number. "Significantly improves" becomes the measured delta. An adverb propping up a weak verb means the verb is wrong, so pick a stronger one.
- **Hedging.** Cut stacked hedges: "could potentially possibly be argued that it might" becomes "may". Keep a hedge that separates proven from inferred. Deleting it manufactures confidence.

## Say what it does

Name the mechanism or a number. "The database stays close at hand" names a feeling. "`.toSQL()` returns the exact string sent to the database" names a mechanism.

Ask what the sentence tells the reader to do or know. If you cannot restate it as a concrete instruction, fact or number, cut it. A sentence that could appear unchanged in another project's docs says nothing about this one.

Anchor every claim to a named thing: this form, this field, this URL, this file. Never a category when you can name the place.

## Punctuation and formatting

- **No em dashes.** Use a full stop or a comma. Parentheses, en dashes and spaced hyphens used as dashes trade one tell for another.
- **Colons** before a list or an example only, never as a mid-sentence connector.
- **Bold** sparingly. Never every proper noun.
- **Inline-header lists.** A bold label and colon that restates its line ("**Performance:** Performance improved...") becomes prose. A bold lead-in ending in a full stop and followed by new detail is fine.
- **No decorative emojis** in headings or bullets.

## Compression keeps every fact

Two operations. Keep them apart.

**Lossless, always, no permission needed.** Filler, throat-clearing, repetition, contrast framing, empty adjectives, restating sentences, and any phrase that survives deletion without changing meaning. Typically 20 to 40 per cent of the words, and nothing lost.

**Lossy, only under a stated limit.** A limit exists when I name a word or page count, when the format imposes one (a commit subject, a form field), or when the reader file or format skill sets a budget. Then drop information in this order:

1. Background the reader already has.
2. Alternatives not chosen.
3. Supporting examples, keeping one.
4. Detail behind a conclusion, keeping the conclusion.

Never drop, at any budget: a number the reader may act on, a hedge that separates proven from inferred, a caveat that changes the decision, a stated exclusion, or a safety or cost warning.

Name what went, in the form the output uses: a `More on request:` line, a list of what was left out, a sentence in the covering message. Silent loss is the failure.

When shortening an existing document, read `compress.md` beside this file. It carries the fidelity rules, the ways compression goes wrong, and a mechanical check script.

## When a format skill also applies

A format skill sets sections, section order, templates, length and language. These rules set the wording. Fixed text the format requires, such as template labels or legally required wording, stays verbatim.

## Before returning any prose

- The reader is named, and that reader's file was applied.
- First sentence of each unit carries its point. No preamble, no closing recap, no pleasantries.
- Australian spelling, with identifiers and quotations untouched.
- No em dashes, no contrast framing, no paragraph over the limit, no repeated word in consecutive sentences, no restating sentence.
- Every number, date and name unchanged, and every hedge in the source still a hedge.
- Anything dropped is named.
- Nothing for an outside reader says how the work was produced.
- Ask: what still makes this read as machine-written? Fix it.
