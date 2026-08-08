# Golden-answer evals for chapter quizzes

A golden-answer eval is a teacher-only regression test for a quiz's hidden
grading rubric. It sits beside the quiz as `<chapter>-quiz.eval.yaml`. Each case
contains a synthetic student answer and the verdict the real grader should
return. Students never see eval files, the app stores nothing from a run, and an
eval never gets an activity code.

Use the 0010 Introduction evals as the local quality bar. They go beyond one
textbook answer per verdict: they test realistic short answers, rubric
boundaries, language fairness, verbosity bias, and confident misconceptions.

## File skeleton

```yaml
# yaml-language-server: $schema=https://raw.githubusercontent.com/Teaching-HTL-Leonding/novedu-chat-mvp/refs/heads/main/activities/evals/eval-yaml.schema.json
id: <quiz-id>-eval
target: ./<chapter>-quiz.yaml # relative to THIS eval file

questions:
  - question: <exact-question-id>
    answers:
      - expect: correct
        answer: |
          <short correct answer in realistic student wording>
      # Mirrors one concrete half-right branch in the rubric.
      - expect: partial
        answer: |
          <specific incomplete or partly mistaken answer>
      # Fluent wording must not turn a misconception into credit.
      - expect: incorrect
        answer: |
          <confident, plausible, but decisively wrong answer>
```

`id` accepts letters, digits, `.`, `-`, and `_`. `target` is relative to the
eval file or an absolute HTTP(S) URL. `question` must exactly match an id in the
resolved quiz. Imported compound-quiz ids use `<alias>/<question-id>`; use the
CLI's `prompts` command if the resolved ids are unclear.

`expect` is `correct`, `partial`, `incorrect`, or a non-empty list such as
`[partial, incorrect]` when either verdict is genuinely defensible. Eval files
are text-only; they cannot replay photographed answers.

## Design a useful case set

Start with all questions for a new chapter quiz. For a later focused rubric
change, cover the changed question and retain the rest of the file unchanged as
regression protection. Three cases are a useful floor, not a target. Add cases
until every distinct rubric branch or likely grading failure has a probe.

For each question, choose from this matrix:

| Case | What it proves |
| --- | --- |
| Short correct answer | The grader rewards content without requiring polished prose. |
| Everyday paraphrase | Students need not repeat the rubric's technical vocabulary. |
| German correct answer | The shared bilingual policy works in practice. |
| One partial per rubric branch | Each declared half-right boundary is reachable and distinct. |
| Classic misconception | The `incorrect` rule rejects the likely wrong idea. |
| Confident technical error | Fluency and jargon cannot hide a decisive mistake. |
| Verbose padded answer | Irrelevant length neither raises nor lowers the deserved verdict. |
| Exact-value/code edge | Numbers, order, spacing tolerance, and required syntax land on the intended boundary. |

Not every row fits every question. Prefer a smaller discriminating set over
mechanically duplicating cases. The 0010 files commonly use five or six answers
because two correct phrasings, two distinct partial branches, and one or two
wrong probes each protect a different behavior.

Write answers like 15-to-17-year-olds actually type: usually short, sometimes
lowercase, with ordinary words and harmless mistakes. Keep deliberately verbose
cases long, and comment why. Do not make every answer polished teacher prose; that
would miss the population the quiz is meant to grade.

Never use a real student's response. When a report reveals a useful failure,
write a new synthetic answer with the same misconception and add that instead.

## Validate before spending tokens

Run commands from `~/github/chat-prototype`, and pass the absolute eval path in
this book repository:

```bash
npm run cli --silent -- validate /absolute/path/to/chapter-quiz.eval.yaml --kind eval
```

Validation is offline, needs no sign-in, and spends no model tokens. It checks
the eval schema, loads and strict-checks the target quiz, and rejects unknown
question ids. `validate` accepts one file per call; loop over several files.

## Run the real grader

`eval` uses the same grading path as student submissions. It requires a signed-in
teacher and spends one model call per golden answer per repeat:

```bash
npm run cli --silent -- whoami
npm run cli --silent -- eval /absolute/path/to/chapter-quiz.eval.yaml
npm run cli --silent -- eval /absolute/path/to/chapter-quiz.eval.yaml --repeats 3
npm run cli --silent -- eval "/absolute/path/to/part/**/*.eval.yaml"
```

Before a large batch or any repeated run, report the case count and resulting
grading-call count to the user and ask for approval. Validate every file first.
If server, authentication, or provider behavior has not been confirmed, use a
one-case throwaway smoke eval before launching a large run.

A run evaluates the local quiz file, including unpushed edits. A green run
therefore certifies the working copy. Push the exact tested quiz before treating
the live GitHub-hosted activity as fixed.

## Read and act on the report

- A case is one golden answer. Repeats are observations of that same case; the
  majority verdict counts.
- A mismatch is a rubric finding, not a CLI failure. First decide whether the
  golden expectation or the rubric is wrong, then edit the right one and re-run
  the full file.
- Read the false-correct rate explicitly. Any nonzero value means an answer that
  should not pass was called `correct`; sharpen the rubric with a concrete
  "grade `incorrect` when..." condition.
- `unstable` means repeated observations disagreed. It does not fail the run,
  but it marks a boundary that needs clearer rubric wording.
- `errored` and `skipped` indicate server, authentication, network, or provider
  trouble, not a bad rubric. Diagnose the run before changing assessment text.

Do not delete an awkward golden answer merely to make the run green. Preserve
valid boundary cases and refine the rubric until the grader handles them. Use a
list expectation only after deciding that the educational boundary truly allows
both verdicts.
