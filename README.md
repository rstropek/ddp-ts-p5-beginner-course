# Creative Coding — course book

The source of **Creative Coding**, a beginner programming course that teaches TypeScript
with the [p5.js](https://p5js.org/) drawing library by making things you can see. The
audience is students aged 15 to 17 in Austrian schools (English book, German-speaking
students, no prior programming experience).

This repository holds **only the book**: prose chapters written in Quarto Markdown, plus
the novedu activity definitions that go with them, the chapter quizzes and the AI tutors.
It contains no exercise code and no runnable playground. One `quarto render` produces two
outputs from the same sources:

* an HTML book (chapter sidebar, prev/next navigation) in `_output/`
* one combined PDF handout, `_output/Creative-Coding.pdf`, laid out for print

## The three-repository system

The course is not one product but three, and this book is the narrative layer that ties
the other two together. **A chapter never reproduces content owned by a sibling
repository — it links to it.** Duplicated exercise text or quiz questions would go stale
the moment the sibling changes, so the book stores a URL or an activity key instead.

| Repository | Owns | This book's relation |
| --- | --- | --- |
| **this repo** | Chapter prose, illustrations, quiz and tutor YAML sources | Explains concepts, then sends the student out to an exercise, a quiz, and an AI tutor |
| [`rstropek/ts-web-playground`](https://github.com/rstropek/ts-web-playground) | The browser IDE and every **exercise**: task description, starter code, sample solution, result images | Chapters link to exercises by raw YAML URL; goal images are hot-linked from the same repo |
| [`Teaching-HTL-Leonding/novedu-chat-mvp`](https://github.com/Teaching-HTL-Leonding/novedu-chat-mvp) | The **novedu** app (novedu.at) that runs AI learning activities, plus the CLI that validates and publishes them | Chapters link to a **quiz** and to an **AI tutor** by registry key; the activity YAML lives here but is served to novedu from this repo's raw URLs |

```text
                  ┌────────────────────────────────────┐
                  │  this repo (the book)              │
                  │  chapters .qmd + activity .yaml    │
                  └───────┬────────────────────┬───────┘
    {{< example url >}}   │                    │   {{< quiz key >}}
                          │                    │   {{< tutor key >}}
                          ▼                    ▼
           ts-web-playground            novedu (novedu-chat-mvp)
           exercise YAML +              renders <base>/<code>, reads the
           browser IDE + p5.js          activity YAML back from this repo's
                                        raw GitHub URL
```

### Relation to `ts-web-playground` (the exercises)

Students never install an editor. They open a link into the playground, a browser IDE that
compiles and runs their TypeScript with p5.js right on the page. Each exercise is one YAML
file in that repository, and it owns the task description, the starter code, and the
sample solution.

A chapter points at one with the `example` shortcode:

```markdown
{{< example https://raw.githubusercontent.com/rstropek/ts-web-playground/main/exercises/0010-Basics/shapes.yaml >}}
```

which renders a callout with an "Open in the playground" button. The playground's base URL
is set once in `_quarto.yml`, so a server move is a one-line change. Nothing is fetched at
render time, so the book never breaks when an exercise file changes.

Most chapters also open with the finished artifact as a **goal image**, hot-linked from the
playground repo. So the build needs internet access, and renaming a result image there
breaks the book's PDF. Add new result images to the playground repo, not here.

Practical consequence: **writing a chapter usually means editing two repositories.** The
exercise belongs in `ts-web-playground`; the teaching that leads up to it belongs here.

### Relation to `novedu-chat-mvp` (the quizzes and the tutors)

Every chapter ends with a "Check your understanding" quiz: open-ended questions, graded by
a small LLM against a hidden rubric, with an optional per-question discussion chat.
Students take them anonymously as self-checks, and answers in German are accepted.

Those quizzes run on **novedu**, the app built in `novedu-chat-mvp`. Every quiz has a short
**activity code** there, and a chapter links to it with the `quiz` shortcode — naming the
quiz by its **registry key**, never by the code:

```markdown
{{< quiz first-program title="Your first program" >}}
```

which renders a callout linking to `novedu.at/<code>`. The book never contains the
questions themselves.

The quiz *sources* do live here, as `<chapter>-quiz.yaml` next to each `.qmd`, because
novedu reads activity YAML from a public URL on every load. It reads this repository's raw
GitHub URLs, so publishing a quiz edit is a `git push`: no re-upload, and no new code.

#### AI tutors

Every chapter opens with an **`## AI tutor` section**: two or three sentences saying what
the AI situation in that chapter is, followed by a box linking the AI tutor for the book
part, a chat activity on novedu that answers questions about the material. The prose is
chapter-specific (a chapter with an exercise AI says so, the reading-documentation chapter
sends students elsewhere); the standing rules of a tutor, hints instead of solutions and
answers in English or German, are the box's fixed body text in `_extensions/tutor/tutor.lua`,
so they are written once. The `tutor` shortcode works exactly like `quiz`, on a registry key:

```markdown
## AI tutor {#sec-tutor-dice}

Two AIs appear in this chapter, with different jobs. ...

{{< tutor tutor-conditions >}}
```

Each of those headings carries a unique id (`#sec-tutor-<chapter>`), because the PDF is one
LaTeX document and a repeated label would collide.

There are two kinds of tutor, and keeping them apart is the point:

| Kind | Files | Behavior |
| --- | --- | --- |
| **Part tutor**, one per book part | `<part>/<part-name>-tutor.yaml` | Hints only. It never writes a finished program, it knows the cumulative scope of its part, and it refuses anything beyond it |
| **Exercise AI**, only where an exercise calls for one | `0010-introduction/elephant-tutor.yaml`, `0030-conditions/dice-rewrite-tutor.yaml` | Generates complete code from the student's prompt, because writing that prompt *is* the exercise. Linked from inside the exercise section, not at the top of the chapter |

All tutor behavior lives in `ddp-tutor-fragments.yaml` in the repo root, a shared
prompt-fragment library the activities compose from. Each book part's knowledge scope is
one static fragment in it, shared by that part's tutor **and** that part's exercise AI, so
a concept moving between chapters is a one-line edit in one place. The header comment of
that file is the contract: which fragments each kind of activity gets, and why.

One exercise deliberately does *not* use a tutor from this book: the reading-documentation
chapter sends students to a general AI on the internet, so they meet material nobody
pre-filtered for them.

#### The activity registry

**Codes come from the registry, not from hand-minting**, and quizzes and tutors go through
the same one. Two files in the repo root hold the whole mapping:

| File | What |
| --- | --- |
| `ddp-activities.yaml` | Hand-written. Every activity under a key (`first-program`, `tutor-conditions`), grouped into `tutors:` and `quizzes:`, with its file path and any minting options. This is the file you edit. |
| `ddp-activities.lock.yaml` | Generated by the novedu CLI. Maps each key to the code novedu minted for it. Commit it, never edit it. |

`_quarto.yml` pulls the lock file in via `metadata-files`, so its `activity-codes` map is
document metadata and the `quiz` and `tutor` shortcodes resolve the key at render time.
Nothing is fetched during a render, and a key missing from the lock file **fails the
build** instead of publishing a dead link.

Publishing a new quiz or tutor is therefore: write the YAML, validate it, push, add one
entry to `ddp-activities.yaml`, then

```bash
npx @novedu/cli codes sync ddp-activities.yaml
```

and commit both files. Re-running that command is routine: an activity whose file,
availability window, and model override are unchanged keeps its existing code, so only
genuinely new entries are minted. The `writing-quizzes` skill has the full loop; the
format reference is
[`docs/registry.md`](https://github.com/Teaching-HTL-Leonding/novedu-chat-mvp/blob/main/docs/registry.md)
in the novedu repo.

The repo root holds two shared prompt-fragment libraries, one per activity kind:
`ddp-quiz-fragments.yaml`, from which every chapter quiz pulls the same student-context and
grading preamble, and `ddp-tutor-fragments.yaml`, which holds every tutor's role, scope,
and safety rules. Editing one file changes every activity of that kind at once, which cuts
both ways: a broken fragment breaks them all, so validate the library and the activities
that use it after every edit.

## Repository layout

| Path | What it is |
| --- | --- |
| `_quarto.yml` | Book definition: chapter order, output formats, and the playground and novedu base URLs |
| `index.qmd` | The preface |
| `0010-introduction/`, `0020-variables/` | Book parts. Numbered folders and files: a chapter `.qmd` next to its `<chapter>-quiz.yaml` and its images, plus the part's `*-tutor.yaml` |
| `_extensions/` | The Quarto extensions providing the `example`, `playground`, `quiz`, and `tutor` shortcodes |
| `ddp-activities.yaml` | The activity registry: every quiz and tutor under a stable key. Hand-written |
| `ddp-activities.lock.yaml` | Generated key → activity code map, read by the `quiz` and `tutor` shortcodes. Do not edit |
| `ddp-quiz-fragments.yaml` | Shared novedu prompt fragments used by every chapter quiz |
| `ddp-tutor-fragments.yaml` | Shared novedu prompt fragments used by every tutor and exercise AI, including the per-part knowledge scopes |
| `.agents/skills/` | Authoring skills for AI agents; see below |
| `.github/workflows/` | CI: renders the book and uploads the PDF and the zipped website as artifacts |
| `_output/`, `.quarto/` | Build output. Git-ignored |

Chapters are ordered by the `book.chapters` list in `_quarto.yml`, not by file name. Adding
a chapter means adding the file **and** listing it there.

The `example`, `quiz`, and `tutor` shortcodes all render for paper as well as screen: in the
PDF, where a button is dead ink, the callout also carries a QR code and the printed address.
That printed-link block is duplicated in the three Lua files, so a change to one belongs in
all three.

## Building the book

```bash
quarto render          # both formats into _output/
quarto preview         # live-reloading HTML while writing
```

You need Quarto (CI pins the version), a LaTeX distribution for the PDF, `rsvg-convert` so
the SVG diagrams survive the LaTeX pass, and internet access for the hot-linked goal
images. CI builds the book on every push and pull request to `main` and publishes the PDF
and the website as artifacts.

## Authoring conventions

The rules that keep chapters consistent are captured as agent skills in `.agents/skills/`.
Read the relevant one before writing; each is a contract, not a suggestion.

* **`student-technical-writing`** — voice and hard style rules for everything a student
  reads.
* **`writing-quizzes`** — the quiz contract end to end: YAML structure, question design,
  rubric style, and the publish flow.
* **`svgbob`** — diagrams. Each figure is an ASCII-art `.bob` source next to the `.svg` it
  produces. Quarto does not run svgbob at build time, so the `.svg` must be regenerated in
  the same edit as the `.bob`; otherwise the book renders a stale diagram and no build step
  catches it.

Tutor prompts have no skill of their own. Their contract is the header comment of
`ddp-tutor-fragments.yaml`, and the scope fragments there must stay in step with what the
chapters actually teach, so a chapter that introduces a new command means editing that part's
scope fragment too.

Which repository does a change belong to? An **exercise** (task, starter code, solution,
result image) is `ts-web-playground`. A **platform** change to how quizzes are graded or
how activities are displayed is `novedu-chat-mvp`. A quiz's **questions**, a tutor's
**prompt**, and everything a student reads around them, is here.
