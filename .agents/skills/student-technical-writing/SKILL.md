---
name: student-technical-writing
description: Rules for writing the student-facing docs. Use when writing or reviewing content for computer science beginner students.
---

# Style & voice

## Writing constraints (hard rules)

Not optional. They govern how the docs read and how they behave when a future search
or RAG layer splits them into chunks.

- **No em-dashes.** Use a comma, a colon, parentheses, or a full stop instead. An
  em-dash is a common machine-writing tell and cheap to avoid.
- **No AI slang.** Skip words like *delve*, *leverage*, *seamless*, *robust*,
  *unlock*, *empower*, *streamline*, *elevate*, and filler like *it's worth noting*
  or *in the realm of*. Say the plain thing a teacher would say.
- **Write self-contained sections; no anaphora across headings.** Any section may
  later be pulled out on its own and shown without the rest of the page, so it has to
  stand alone. Name the subject in each section instead of pointing back at an
  earlier one. Write "Photo answers are off by default", not "This is off by
  default". Avoid "as mentioned above", "the former"/"the latter", and a "this",
  "that", or "it" whose referent sits under another heading. A normal pronoun inside
  the same paragraph is fine; the rule is about references that break when a chunk is
  read alone.

## Voice and tone

Warm, clear, and ready to help. Sound like a knowledgeable teacher sitting next to
the student, not a manual.

- **Talk like a person.** Write the way you would explain it out loud; read a
  sentence aloud and if it sounds stiff, rewrite it. Use contractions ("you'll",
  "it's", "don't").
- **Get to the point.** Lead with what matters to the student, then the detail.
  Bigger ideas, fewer words. Cut any sentence that doesn't help them act.
- **Be positive and direct.** Tell the student what to do, not only what to avoid.
  "Use explicit typing in your code" beats "Don't forget to explicitly type your code".
- **Second person, active voice, present tense.** "You write the TypeScript code and
  the compiler converts it to JavaScript", not "The TypeScript code is written and 
  converted to JavaScript by the compiler".
- **Encouraging.** Students are learning something new. "You can do this" is the tone.

## Words

- **Simple, common words.** "Use", not "utilize". "Enough", not "sufficient". "Help",
  not "facilitate".
- **No idioms or cultural metaphors.** Skip sports metaphors, wordplay, and humour students 
  could miss. Plain and literal reads clearly for everyone.
- **Spell out Latin abbreviations.** "For example", not "e.g."; "that is", not "i.e.";
  "and so on", not "etc." where you can.
- **American English, consistently.** The audience is Austrian schools, which teach
  British English, so use American spelling ("behavior", "color", "organize",
  "practice" the verb) and never mix in British forms ("behaviour", "practise")
  within or across chapters. Keep proper nouns and code (model ids, field names, CLI
  flags) exactly as written in the source.
- **Introduce a term clearly the first time it matters**, so a section still makes
  sense on its own (for example, "a `char`, short for a _character_").
  Expand an acronym the first time it appears.
- **Plain words, no glossary markers.** There is no glossary; never write `[[term]]`
  markers or link a term to a definitions page. The "introduce a term clearly"
  rule above is the whole mechanism: define a term in place the first time it
  matters.

## Mechanics

- **Sentence-style capitalization** for headings and titles: capitalize the first
  word and proper nouns only. "Time-limiting a code", not "Time-Limiting a Code".
- **Serial (Oxford) comma:** "tutors, quizzes, and writing tasks".
- **Numbers:** spell out zero to nine in ordinary prose; use numerals for 10 and up,
  and always for versions, counts shown on screen, and anything technical.
- **Descriptive link text**, never "click here" or a bare URL. The link text should
  make sense on its own, which also helps a reader skimming or a standalone chunk.
- **Short blocks.** Short sentences, short paragraphs, generous headings and lists. A
  student skims between lessons.

## Audience

Students age 15-17 in Austrian schools, reading English as a second language. They
are computer science beginners with very limited experience with programming.
