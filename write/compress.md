# Shortening a document that already exists

Read this when producing a short version of a document, tightening a report, or reviewing someone
else's compression. Derived from compressing eight commercial proposals and reviewing the result twice.

## The contract

The short version says everything the long version said, in fewer words. A reader who has only the
short version reaches the same decision, with the same confidence, and can defend it with the same
evidence.

Word count is not the goal on its own. A version that is 30 per cent shorter and drops one hedge is
worse than the original.

## What survives compression, always

| Category | Examples |
| --- | --- |
| Numbers and their qualifiers | Hours, prices, counts, percentages, dates, versions, line numbers |
| Hedges | `appears to`, `we have not tested`, `inferred`, `not confirmed`, `to be confirmed` |
| The proven and unproven boundary | What was observed against what follows from it |
| Unknowns | A list of open questions is content, not padding |
| Exclusions | What the work does not cover, and why |
| Dependencies and sequencing | What must happen first, and what breaks otherwise |
| Status metadata | Hours, priority, blocked by, `not quoted`, owner |
| Reproducible evidence | Commit hashes, file paths with line numbers, advisory identifiers, the commands a reader can run |
| Cost and risk warnings | Anything that changes what the reader spends or exposes |

## The ten ways it goes wrong

Every one of these was found in a real compression of a document that was otherwise good.

1. **A hedge becomes a fact.** `the policy appears to allow uploads` turns into `anyone can upload`.
   The compressed sentence is shorter and states something nobody verified.
2. **An unknown becomes settled.** An open question, listed as open in the source, is answered in
   passing by the short version. Check every question the source raised.
3. **An inference the source refused to make.** The source says `that looks like a failed
   deployment`. The short version says why it failed. Nobody knows why.
4. **An invented process or entity.** `requires written authorisation`, `the company access
   group`, a named approval step. If the source never named it, it does not exist.
5. **Status metadata dropped.** The Summary table loses hours, priority or `not quoted`. A reader
   with only this file cannot quote or schedule the work.
6. **Evidence dropped for length.** Commit hashes, line numbers, the exact permissions, the command
   anyone can run. This is what makes a claim checkable. Losing it turns a finding into an opinion.
7. **Scope widened by a word.** `every page fails` when the data covers three pages. `27 commits
   affect the maps` when nine do. Compression invites the general word; the general word is wrong.
8. **A number keeps its digits and loses its qualifier.** `as little as 6 pixels` becomes `6
   pixels`. A range measured across a month gets attached to a single date. The figure is intact
   and the claim is now false.
9. **An exclusion disappears.** The source said the estimate excludes third-party controls. The
   short version quotes the estimate alone, and the estimate now means something else.
10. **Vocabulary creeps towards the writer.** Internal jargon, tool names and the word `client`
    enter a body written for forwarding. Terminology belongs in the closing evidence section.

One more, seen once: **a claim borrowed from a sibling document**. A finding that belongs to
another report appears here, unsourced. Check that every claim traces to this document's source.

## Where the length actually goes

After the first review, compressed documents tend to regain their full evidence section verbatim,
and end up at 60 to 85 per cent of the original. That is a real result and often the right one.

Decide deliberately where the words live:

- **The body carries the argument.** This is where lossless compression pays. Cut hard here.
- **The evidence section carries the checkable facts.** Compress its wording, keep every item.
- If the document must be genuinely short, move the evidence to a companion file and link it.
  Never delete it to hit a number.

## The mechanical check

Compare the compressed file against the original before returning it. Reading twice does not catch
a changed digit; this does.

```python
import re, sys
from collections import Counter
def feats(t):
    return {
      'numbers':  Counter(re.findall(r'(?<![\w/.-])\d[\d,.]*%?', t)),
      'code':     Counter(re.findall(r'`[^`\n]+`', t)),
      'urls':     Counter(re.findall(r'https?://\S+', t)),
      'headings': re.findall(r'^#{1,6} .+$', t, re.M),
      'images':   re.findall(r'^!\[.*$', t, re.M),
    }
before, after = (open(p).read() for p in sys.argv[1:3])
b, a = feats(before), feats(after)
for k in ('numbers', 'code', 'urls'):
    lost, new = b[k] - a[k], a[k] - b[k]
    if lost: print('LOST', k, dict(lost))
    if new:  print('NEW ', k, dict(new))
if b['headings'] != a['headings']: print('HEADINGS changed')
if b['images']   != a['images']:   print('IMAGES changed')
for p in re.split(r'\n\s*\n', after):
    if p.lstrip()[:1] in '|#`-!<' or re.match(r'\s*\d+\.', p): continue
    s = ' '.join(p.split())
    if len(s.split()) > 60 or len(re.findall(r'[.!?](\s|$)', s)) > 4:
        print('LONG', len(s.split()), 'words:', s[:60])
for m in re.finditer(r'(?i)\b(is not [^.]{0,80}\. It is|not [^.]{0,60}, but |rather than|, not [a-z])', after):
    print('CONTRAST', after[max(0, m.start()-40):m.end()+30].replace('\n', ' '))
```

A `LOST` or `NEW` number is a defect until proven otherwise. A dropped heading means a section went
missing. Anything the script flags gets read by eye before the file is returned.

The script cannot see hedges, scope or invented claims. Those need a read against the source, using
the list above.

## Reviewing someone else's short version

Report in this order, and separate the categories. They carry different consequences.

1. **Wrong or overstated.** Quote the words, say what the source actually says, say why it matters.
2. **Meaning lost.** Name it and say whether a reader needs it.
3. **Better than the original.** Compression often finds a clearer line. Say so.
4. **Audience.** Whether the vocabulary suits whoever receives it.
5. **Recommendation.** The specific edits, and the resulting length.

Verify each claim by reading the source, never by inference. A review that invents a fault costs
more trust than the fault would have.
