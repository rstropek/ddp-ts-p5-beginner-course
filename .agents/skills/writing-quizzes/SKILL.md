---
name: writing-quizzes
description: >-
  Author, revise, and publish novedu chapter quizzes and compound (section)
  quizzes for this Creative Coding book. Use this skill whenever the user asks
  to create a quiz for a chapter, add/change/review quiz questions, adjust a
  grading rubric or evaluation prompt, write or run golden-answer evals, diagnose
  eval mismatches, build the section-level exam-prep quiz, add an image to a quiz
  question, or publish/update a quiz (validate, upload, mint a code, link it from
  the chapter) — even if they don't say "quiz YAML", "eval YAML", or name the
  novedu app. Also use it when reviewing existing *-quiz.yaml or
  *-quiz.eval.yaml files for question, rubric, or regression-test quality.
---

# Writing quizzes for the Creative Coding book

Each book chapter gets one LLM-graded quiz (`<chapter>-quiz.yaml`, sibling of
the `.qmd`) and one paired golden-answer regression file
(`<chapter>-quiz.eval.yaml`). Each book part gets one compound quiz that imports
all of its chapter quizzes for exam preparation. Quizzes are novedu activities:
open-ended questions only, graded by a small LLM against a hidden rubric, with
an optional per-question discussion chat. Students use them as anonymous
self-checks. Eval files are teacher-only test data; never publish them as
activities or mint codes for them.

Ground truth for the platform lives in the novedu repo
(`~/github/chat-prototype`): authoring guide `activities/quizzes/README.md`,
eval guide `activities/evals/README.md`, teacher guide
`teacher-docs/content/10-yaml-for-teachers/06-testing-the-grader.md`, and CLI
skill `.agents/skills/novedu-tutor-cli/SKILL.md` (the repo's `.claude` symlink
exposes the same file at `.claude/skills/novedu-tutor-cli/SKILL.md`). Don't
re-derive platform rules — the CLI validates with the app's exact pipeline.

Read `references/question-design.md` before writing or reviewing questions —
it distills the assessment literature this course follows and ends with the
audit checklist. The rules below are the course-specific contract; the
reference explains the why and the general craft.

Read `references/golden-answer-evals.md` whenever creating or changing a quiz,
touching an `evaluation` rubric, reviewing an eval file, or diagnosing grading.
It captures the calibrated case design established by the Introduction (0010)
quizzes and the exact validate/run loop.

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

# BOTH host texts below pull from the shared fragment library — never inline
# their wording, never edit it per chapter (edit ddp-quiz-fragments.yaml at
# the repo root instead; one push updates all quizzes live).
fragment_files:
  - id: shared
    url: "../ddp-quiz-fragments.yaml" # repo root, resolves on GitHub and locally
instructions: |
  {{fragment "shared.quiz_context"}}

discussion:
  # Appended AFTER the app's built-in discussion prompt (role, context, and
  # "concise, encouraging, stay on this question" are already set there).
  # Does NOT travel into compound quizzes. The policy sentences live in the
  # fragment; supply only the four chapter-specific arguments. `scope`
  # completes "…what a beginner knows ___". Drop `example` if the chapter has
  # no code yet; override `german_tail` only if there are no code names.
  instructions: |
    {{fragment "shared.discussion_frame"
      example="circle(200, 260, 360);"
      scope="after <this chapter>"
      knows=(array
        "<concept the chapter taught>"
        "<…>")
      not_yet=(array
        "<the next concept students have not seen yet>"
        "<…>")}}

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

Store source PNGs in `<chapter>-quiz/` next to the quiz YAML, then host them
with `images upload <name> --file <path>` (`images list` to check what is
already there; name = the `src` above). Unknown hosted names
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
  chapter preamble; adding it again would duplicate the text in every grading
  prompt (the app does not dedup compound-vs-source).
- **Own `discussion.instructions` required, and it must pull BOTH fragments.**
  The discussion prompt is built only from the compound file's own fields;
  chapter `instructions` travel with imported questions for *grading* only.
  So `quiz_context` goes HERE — without it the discussion chat has no student
  context at all (no age, no "German is fine", no "short answers score
  equally") — and not in a top-level `instructions`, which would double it
  into every grading prompt:

  ```yaml
  discussion:
    instructions: |
      {{fragment "shared.quiz_context"}}

      {{fragment "shared.discussion_frame"
        example="const dice: number = floor(random(1, 7));"
        scope="after the <Part> chapters"
        knows=(array "…" "…")
        not_yet=(array "…" "…")}}
  ```
- Set `question_count` to a sensible attempt length (~2× a chapter quiz);
  leave `shuffle` on.
- No own `questions` needed.
- Do not copy every chapter's golden answers into a compound eval. The source
  rubrics are already protected by their chapter evals. Create a small compound
  eval only when an integration behavior needs testing, using namespaced
  `<alias>/<question-id>` ids.

## Golden-answer evals

Treat the paired `<chapter>-quiz.eval.yaml` as part of the quiz, not as an
optional afterthought. Its synthetic student answers pin down what `correct`,
`partial`, and `incorrect` mean so rubric improvements cannot silently break a
previous boundary.

- Create or update the eval in the same change as its quiz. Cover every new or
  materially changed question; preserve cases for unchanged questions as
  regression tests.
- Model how these students really answer: short fragments, everyday words,
  lowercase starts, occasional harmless typos, and at least one German answer
  where the concept can be expressed naturally in German. Do not paste or
  lightly anonymize a real student's answer; all cases must be synthetic.
- For each covered question, include a clearly correct answer, each meaningful
  half-right branch named by the rubric, and a confidently wrong answer. Add
  adversarial cases where relevant: a terse correct paraphrase, a verbose
  correct answer padded with irrelevant facts, fluent technical prose with one
  decisive error, swapped values, or an exact code boundary such as a missing
  required semicolon.
- Make cases discriminate between verdicts. An answer copied from `Expected:`
  proves little; a partial case should closely mirror the rubric's declared
  boundary, and a wrong case should probe the misconception most likely to be
  over-graded. Use `expect: [partial, incorrect]` only when both really are
  defensible, never to hide uncertainty about the rubric.
- Keep short comments above non-obvious cases explaining the boundary or bias
  being tested. This makes future rubric changes reviewable.

The reference contains the exact skeleton, CLI commands, cost/auth cautions,
report interpretation, and repair loop. Validation is free and must happen
whenever the pair changes. Running `eval` calls the real model and spends tokens,
so validate first and obtain user approval before a large or repeated run.

## Publish workflow

Quizzes are served straight from the book's public GitHub repo
(`rstropek/ddp-ts-p5-beginner-course`); the novedu server re-reads the raw
URL on every load, so publishing an edit = `git push`. The CLI runs from the
novedu repo (`cd ~/github/chat-prototype`, prefix commands with
`npm run cli --silent --`, and pass ABSOLUTE paths for files in the book
repo); `codes sync` and `eval` need a signed-in teacher (`whoami` to check;
`login` opens a browser the human must finish). Validation needs no sign-in.

1. Author/edit the quiz YAML and its sibling golden-answer eval in the book
   repo.
2. Validate the quiz with `validate <quiz-path> --kind quiz`, then validate the
   eval with `validate <eval-path> --kind eval` (the latter also strict-checks
   the target quiz). Relative fragment references resolve on the filesystem.
3. When authorized, run the eval through the real grader and repair genuine
   mismatches before publishing. Read the false-correct and unstable counts.
4. Commit and push (quiz edits go live immediately for existing codes).
5. First publish only: confirm the published render —
   `validate https://raw.githubusercontent.com/rstropek/ddp-ts-p5-beginner-course/refs/heads/main/<folder>/<file>.yaml --kind quiz`
   — then add ONE entry to the **activity registry** `ddp-activities.yaml`
   (book-repo root) under `activities.quizzes`, keyed by chapter slug
   (`number-systems`, no numeric prefix; unique across the whole file):

   ```yaml
       <chapter-slug>:
         file: <folder>/<file>-quiz.yaml   # relative to the registry's base-url
         note: "Creative Coding book: <chapter title> (<nr>) — GitHub-hosted"
   ```

   and run `codes sync <abs path>/ddp-activities.yaml`. That mints the new
   code, reuses every existing one, and rewrites `ddp-activities.lock.yaml`;
   commit registry AND lock file. Book quizzes carry no `start`/`end` and no
   `llm` override. Later edits need no new code and no sync (the code points
   at the raw URL).
6. First publish only: add a "Check your understanding" section at the end
   of the chapter `.qmd` (unique anchor `{#sec-quiz-<short>}`): a short
   intro naming the question count, then
   `{{< quiz <chapter-slug> title="<Chapter title>" >}}` — the registry KEY,
   never a code. An unknown key fails the render.

**Never `codes create` a book quiz and never paste a code into a chapter**:
the registry plus its lock file are the only place codes live. `codes sync`
is safe to re-run (unchanged entries keep their code); pass `--dry-run` when
unsure. An entry reported as `failed` means the server rejected that quiz —
read the message, fix the YAML, push, re-run. An unexpected `minted` for a
quiz that already has a code means the entry does not match it (file path,
window, or model override); stop and fix the entry, or the chapter silently
moves to a fresh code with no history.

Editing shared wording = edit `ddp-quiz-fragments.yaml` (repo root),
`validate <path> --kind fragment`, then push. Every quiz picks it up live.
Keep the library minimal — a broken fragment fails ALL quizzes at once.
`quiz_context` feeds the grader + discussion preamble; `discussion_frame`
feeds the discussion chat. A policy sentence (reveal the answer, keep it tiny,
answer in German) is edited once there and every quiz follows. After editing
the library, re-validate a couple of quizzes too: a changed `input_schema`
breaks their markers, not the library. If `quiz_context` changes grading
behavior, validate the chapter eval files and, when authorized, run the affected
eval suite; `discussion_frame`-only changes do not need grader evals.

(Alternative: `files upload <name>` app-hosts a file at
`https://novedu.at/api/files/<name>`; only relevant if a quiz must not live
in the public repo.)

## Student feedback loop

Students can flag a chat or a graded answer. `reports list` / `reports show
<id>` (embeds the transcript or the question/answer/feedback snapshot) →
usually the fix is a rubric edit in the quiz YAML → add a synthetic regression
case → validate and evaluate → push → `reports resolve <id…>`. Reports usually
point at rubric boundaries, not questions. Never copy the student's answer into
the committed eval; write a new answer with the same misconception. Re-run the
full regression set so the same grading failure stays fixed.
