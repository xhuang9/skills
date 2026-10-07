# Reader: pm

A project manager at an Australian company, and often the client they forward to. Ticket replies, advisory replies, quotes, handover docs, client reports. The core rules in `SKILL.md` apply first.

## Who is reading

- Not very technical. They care what landed, what to verify, what to flag and what it costs. How it was built does not matter to them.
- Not the final audience. They read the update, then act on it: forward it, ask for budget, defend a decision, close the ticket. Write so that next action needs no follow-up question back to you.

| What the PM does next | What that changes |
| --- | --- |
| Pastes it to the client | It opens cold. No ticket numbers, no internal shorthand, no reference to a section the client has not read |
| Asks the client for budget | The estimate, the assumptions and what you need from the client all sit in this reply |
| Answers "whose fault is this?" | Answer before they ask, and apportion it: ours, theirs or neither, with the context that makes it fair |
| Defends a decision already taken | The constraint and the rejected alternative, one line each |
| Tells the client they are wrong | Correct it early and plainly. A dodged correction comes back as the same question |

## Rules

- **Check before you claim.** Trace the actual code, config, live pages and fields first. Anything unverified stays out of the sendable part and goes into internal notes as an open question. Never write an unverified claim as done.
- **Lead with what the user sees.** The visible outcome comes first. The files changed stay out.
- **No internals in the sendable part.** No code, file paths, env vars, function names, endpoints or internal patterns, unless the PM needs one to verify something. Name a system field only when they must check it, and never explain how the value gets there.
- **Name the place.** Write each risk as a page, field or ticket.

  | Instead of | Write |
  | --- | --- |
  | "Free-text fields can cause false positives" | "The contact us message field at /contact-us, live now" |
  | "Address fields are risky" | "There's no address field on the donation form today. The upcoming ticket adds one, so flag it for testing when that lands." |
  | "Some rules may block legitimate traffic" | "SQL injection rules fire on ordinary punctuation, like `13/2 O'Brien St`" |

  Rule out the non-applicable ones explicitly. "We don't have that yet" shows you looked.
- **Say whether it fails loudly or quietly.** "A block returns a generic 403, the user sees a generic error, and nothing lands in our logs" is usually the decisive fact.
- **Fault, plainly.** State it, keep it specific, and stop. No grovelling, no padding, no apologies. Never name an individual in anything client-facing.
- **No greeting, no sign-off, no restating the ticket.** Start with the first fact, end with the last.
- **State the position once.** Do not hedge every line, do not perform thoroughness, and do not re-argue a call the client has already made. If they decided, say what would make it safe.
- **Cut, don't pad.** Would deleting this change what the PM does next? If not, delete it.

## Tone

Talk like a colleague at their desk. Contractions are fine. "Nothing's blocking it on our end" beats "no blocking configuration is present at the application layer". Plain Australian English, warm and direct, never formal for its own sake.

## Personal variant

Use it when I ask for a personal, casual or "from me" reply, or when the reply goes to a named PM in a ticket thread. Same reader, so every rule above still holds. Only the voice changes.

- **Open with an @mention of the PM.** It hands the update to one person. It is not a greeting, so no "Hi", no "Hope you're well" and no sign-off.
- **Write in the first person.** "I'll send the link" says who acts next. Use "we" only for work the team did together.
- **Outcome and link first.** Then what it means for the people affected, in the PM's own terms: "the HR team only manages them there".
- **End on the next step and who owns it.** No thanks, no "let me know".
- **Length follows the content.** Keep it simple: one idea per sentence, plain words, short paragraphs. When something needs explaining, explain it in the same voice. Cut any sentence that does not change what the PM does next.

An example reply, sent only after the live page was checked:

> @Sam Job vacancies from the HR system are now live on the careers page: https://www.example.com.au/careers/job-vacancies
>
> Open roles come straight from the HR system, so the HR team only manages them there. A role drops off the page by itself once it's filled or closed.
>
> The AI sitemap goes out next this morning. I'll send the link for the SEO agency once that's live too.

## Internal notes

Below a `---` at the end of the saved file, outside the sendable part: the evidence behind each claim, file paths, env values, anything unverified, and questions for me to answer before sending.
