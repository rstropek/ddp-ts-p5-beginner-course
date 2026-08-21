# Creative Coding book

This repository holds the source of **Creative Coding**, a beginner programming
course that teaches TypeScript with the p5.js drawing library by making things you
can see. The chapters are Quarto Markdown (`*.qmd`) in the numbered part folders,
and `quarto render` turns them into an HTML book and one PDF handout. The
exercises live in the `ts-web-playground` repository and the quizzes and AI tutors
run on novedu, so a chapter links to them and never copies their content. The
`README.md` describes that three-repository split in full.

## Writing student-facing prose

Every chapter, and every quiz question and tutor prompt next to it, follows the
`student-technical-writing` skill. Load it before drafting or reviewing any of
them. It calibrates against the audience below.

## Audience

Students age 15 to 17 at Austrian schools, with very limited programming
experience. For most of them this course is the first time they write code.

What they bring:

* No prior programming. A variable, a loop, and a function are new ideas that the
  chapters teach, in that order, one at a time.
* English is their second language. They read plain English fine, so short
  sentences and common words are what keeps them reading, and an idiom or a
  cultural joke costs more than it gives.
* Their school teaches British English, which is exactly why American spelling
  needs an explicit pass in every draft.

What that means for the text:

* **Teach everything, assume nothing.** The teaching budget goes to the basics:
  what a value is, what a type is, why the compiler complains. Nothing a chapter
  has not yet introduced is already theirs.
* **Encourage.** Students are learning something new, and the tone is "you can do
  this". Tell them what to do, not only what to avoid: "Write the type after the
  colon" beats "Don't forget to add the type".

## Exercises and linear reading

Students meet an exercise's starter code only when an exercise step tells them to
open it in the playground. A chapter teaches the concept first, as its own idea,
and the exercise steps then point back to it. Never ask the reader to look at,
change, or judge code that is not in front of them at that point.

## No glossary

There is no glossary and no definitions page. Never write `[[term]]` markers or
link a term to a definition. The skill's define-in-place rule is the whole
mechanism: a term gets its explanation the first time it matters, in the sentence
where it appears (for example, "a `char`, short for a _character_").

## Links

Link text is descriptive and makes sense on its own, never "click here" or a bare
URL. Exercises, quizzes, and tutors are linked through the book's shortcodes
(`{{< example >}}`, `{{< quiz >}}`, `{{< tutor >}}`), never by pasted URL.

## Related skills

* `svgbob` for every diagram: edit the `.bob` file, then regenerate its sibling
  `.svg`.
* `writing-quizzes` for the quiz YAML and its golden-answer evals.
