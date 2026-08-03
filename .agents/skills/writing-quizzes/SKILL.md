---
name: writing-quizzes
description: >-
  Author, revise, and publish novedu chapter quizzes and compound (section)
  quizzes for this Creative Coding book. Use this skill whenever the user asks
  to create a quiz for a chapter, add/change/review quiz questions, adjust a
  grading rubric or evaluation prompt, build the section-level exam-prep quiz,
  add an image to a quiz question, or publish/update a quiz (validate, upload,
  mint a code, link it from the chapter) — even if they don't say "quiz YAML"
  or name the novedu app. Also use it when reviewing existing
  *-quiz.yaml files for question or rubric quality.
---

# Writing quizzes for the Creative Coding book

Each book chapter gets one LLM-graded quiz (`<chapter>-quiz.yaml`, sibling of
the `.qmd`), and each book part gets one compound quiz that imports all of its
chapter quizzes for exam preparation. Quizzes are novedu activities: open-ended
questions only, graded by a small LLM against a hidden rubric, with an optional
per-question discussion chat. Students use them as anonymous self-checks.

Ground truth for the platform lives in the novedu repo
(`~/github/chat-prototype`): authoring guide `activities/quizzes/README.md`,
CLI skill `.claude/skills/novedu-tutor-cli/SKILL.md`. Don't re-derive platform
rules — the CLI validates with the app's exact pipeline.

Read `references/question-design.md` before writing or reviewing questions —
it distills the assessment literature this course follows and ends with the
audit checklist. The rules below are the course-specific contract; the
reference explains the why and the general craft.

## Chapter quiz skeleton

Copy this structure exactly (it encodes decisions that have mechanical
consequences — see the comments):

```yaml
# yaml-language-server: $schema=https://raw.githubusercontent.com/Teaching-HTL-Leonding/novedu-chat-mvp/refs/heads/main/activities/quizzes/quiz-yaml.schema.json
# Quiz for the book chapter "<Title>" (<folder>/<file>.qmd).

id: <chapter-slug>-quiz
name: "Quiz: <Chapter title>"
title: "Check your understanding: <chapter title, lowercase>"
description: |
  <N> short questions about the chapter *<Title>*. Answer in your own
  words. There are no answer options to pick from, and this quiz is
  anonymous: it's here for you, so you can see what you already understand
  and what you should read again. One or two sentences are enough for most
  answers, and answering in German is fine too.

llm:
  model: RedHatAI/gemma-4-31B-it-FP8-Dynamic

# The shared preamble (student context + grading rules) comes from the shared
# fragment library so every chapter quiz renders a BYTE-IDENTICAL preamble.
# The compound quiz deduplicates identical preambles to one copy — never
# inline this text, never edit it per chapter (edit ddp-quiz-fragments.yaml
# at the repo root instead; one upload updates all quizzes live).
fragment_files:
  - id: shared
    url: "./ddp-quiz-fragments" # sibling app-hosted file
instructions: |
  {{fragment "shared.quiz_context"}}

discussion:
  # Appended AFTER the app's built-in discussion prompt (role, context, and
  # "concise, encouraging, stay on this question" are already set there).
  # This field cannot use fragments and does NOT travel into compound
  # quizzes. Keep the first and last sentences verbatim; adapt only the
  # chapter-scope sentence ("Stay strictly within…") to the current chapter.
  instructions: |
    You may reveal and explain the correct answer. Keep explanations tiny
    and concrete: one idea at a time, with a short code line like
    `circle(200, 260, 360);` where it helps. Stay strictly within what a
    beginner knows after <this chapter>: <list the concepts>. Do not
    introduce <the next concepts students have not seen yet>. If the student
    writes in German, you may answer in German; keep code and command names
    in English.

questions:
  - id: <kebab-case-stable-id> # unique, no "/", never renamed (stats key)
    title: "<Short label>"
    question: |
      <Student-visible Markdown. See references/question-design.md.>
    evaluation: |
      <Server-only rubric. Template below.>
```

Defaults deliberately NOT set (do not add them): `anonymous` (defaults true —
self-check), `shuffle` (defaults true; set `false` only when questions build
on each other), `question_count` (chapter quizzes ask everything).

## Question rules (course contract)

- **One concept per question, one or at most two sub-questions.** "What do
  you see, and why?" is the allowed maximum. Three asks in one prompt is a
  hard rule violation — split or cut (make the dropped part a feedback bonus).
- **Questions in English** (the book's language); the shared preamble makes
  the grader accept German answers and judge content, not language.
- Write student-facing text per the `student-technical-writing` skill: warm,
  plain, short sentences, no em-dashes, sentence-style capitalization.
- Cover the chapter's actual emphases, not trivia; prefer prediction,
  explanation, and bug-finding stems over definition recall (see reference).
- Code snippets in questions: only constructs the chapter has taught.
- `id`s are permanent — they key the teacher statistics and get namespaced
  as `alias/id` in compound quizzes. Choose meaningful kebab-case; never
  rename after publishing.

## Rubric (`evaluation`) template

Slim, one shape for every question:

```
Expected: <the expected answer, stated ONCE, 2-3 lines. Questions with a
literal result (an array, a number, a line of code) state the exact value.>

- `correct`   - <the boundary, concretely: which elements must be present>
- `partial`   - <the typical half-right answer — be concrete HERE; this is
                where a small judge model wobbles>
- `incorrect` - anything else<, plus at most one classic misconception>.

Feedback: <ONE question-specific hint, e.g. "if the student wrote radius,
name the exact word: diameter">
```

Write verdict bullets as procedures a human marker would perform ("says the
background is painted after the circle"), never adjectives ("shows good
understanding"), and list accepted everyday paraphrases where students will
use them ("size" counts for diameter) — synonym handling is where small
judge models fail most. Do not restate the expected answer inside verdict
bullets, do not add generic tone rules (the shared preamble and the app's
grading frame already demand encouraging feedback in simple English, forbid
rewarding length, and make uncertain verdicts fail safe), and do not exceed
~12 lines. The
rubric is server-only and never reaches the browser — it may state answers
freely. The discussion agent never sees it; the shared preamble already tells
the grader to state the correct answer in feedback when the verdict isn't
`correct` (that feedback is the only channel into the discussion chat).

## Images in questions

A question may carry a content image (rendered above the Markdown):

```yaml
image:
  hosted: true
  src: <hosted-image-name> # e.g. first-program-red-squiggles
  alt: >-
    <Describe exactly what is shown, including any text in the image — the
    grader never sees the image alt, but screen readers and fallback do.>
```

Store source PNGs in `<chapter>-quiz/` next to the quiz YAML. Hosting: check
`npm run cli -- images --help` in the novedu repo first (an images command is
planned); if the CLI doesn't have it yet, a teacher uploads at
`https://novedu.at/images/new` (name = the `src` above). Unknown hosted names
resolve leniently (image simply omitted), so the quiz can be published before
the image exists. Use `imageInput: true` on a question only when a
photographed handwritten answer is the natural medium (pen-and-paper traces).

## Compound (section) quiz

One per book part, e.g. `0010-introduction/introduction-quiz.yaml`:

- `quiz_files:` lists every chapter quiz as `{id: <short-alias>, url: "./<hosted-name>"}`
  (aliases: no dots/slashes; they prefix imported ids in stats). Includes are
  live — chapter edits appear immediately; a broken chapter blocks the
  compound (fail-closed, never a silently shorter quiz).
- **No top-level `instructions`** — imported questions already carry the
  chapter preamble; adding it again would duplicate the text in every prompt
  (the app does not dedup compound-vs-source).
- **Own `discussion.instructions` required** (chapter ones don't travel):
  same canonical text, with a section-level scope sentence ("Stay strictly
  within what a beginner knows after the <Part> chapters: …").
- Set `question_count` to a sensible attempt length (~2× a chapter quiz);
  leave `shuffle` on.
- No own `questions` needed.

## Publish workflow

Run the CLI from the novedu repo (`cd ~/github/chat-prototype`, prefix
commands with `npm run cli --silent --`). Needs a signed-in teacher for
uploads (`whoami` to check; `login` opens a browser the human must finish).

1. Author/edit the YAML in the book repo.
2. Upload: `files upload <hosted-name> [--kind quiz] --file <path>` — the
   server validates with the full pipeline and rejects invalid files; `--kind`
   only on first upload. Hosted name = file basename without `.yaml` (e.g.
   `0020-first-program-quiz`). Local `validate` does NOT work for chapter
   quizzes (the `./ddp-quiz-fragments` ref only resolves between app-hosted
   siblings) — upload IS the validation.
3. Confirm end-to-end render:
   `validate https://novedu.at/api/files/<hosted-name> --kind quiz`.
4. First publish only: mint a code —
   `codes create --module quiz --file https://novedu.at/api/files/<hosted-name> --note "Creative Coding book: <chapter> (<nr>)"`
   (no `--start`/`--end` for book quizzes). Later edits need NO new code:
   existing codes serve the newest upload immediately.
5. First publish only: link it at the end of the chapter `.qmd`:
   `{{< quiz <code> title="<Chapter title>" >}}`.
6. Ask the user to spot-check grading with one deliberately half-right answer
   (the correct/partial boundary is the fragile part).

Editing the shared preamble = edit `ddp-quiz-fragments.yaml` (repo root),
`validate <path> --kind fragment` (this one DOES validate locally), then
`files upload ddp-quiz-fragments --file …`. Every quiz picks it up live. Keep
the library minimal — a broken fragment fails ALL quizzes at once.

## Student feedback loop

Students can flag a chat or a graded answer. `reports list` / `reports show
<id>` (embeds the transcript or the question/answer/feedback snapshot) →
usually the fix is a rubric edit in the quiz YAML → upload → `reports resolve
<id…>`. Reports usually point at rubric boundaries, not questions.
