# Creative Coding — course book

The source of **Creative Coding**, a beginner programming course that teaches TypeScript
with the [p5.js](https://p5js.org/) drawing library by making things you can see. The
audience is students aged 15 to 17 in Austrian schools (English book, German-speaking
students, no prior programming experience).

This repository holds **only the book**: prose chapters written in Quarto Markdown, plus
the quiz definitions that go with them. It contains no exercise code and no runnable
playground. One `quarto render` produces two outputs from the same sources:

* an HTML book (chapter sidebar, prev/next navigation) in `_output/`
* one combined PDF handout, `_output/Creative-Coding.pdf`, laid out for print

## The three-repository system

The course is not one product but three, and this book is the narrative layer that ties
the other two together. **A chapter never reproduces content owned by a sibling
repository — it links to it.** Duplicated exercise text or quiz questions would go stale
the moment the sibling changes, so the book stores a URL or a code instead.

| Repository | Owns | This book's relation |
| --- | --- | --- |
| **this repo** | Chapter prose, illustrations, quiz YAML sources | Explains concepts, then sends the student out to an exercise and a quiz |
| [`rstropek/ts-web-playground`](https://github.com/rstropek/ts-web-playground) | The browser IDE and every **exercise**: task description, starter code, sample solution, result images | Chapters link to exercises by raw YAML URL; goal images are hot-linked from the same repo |
| [`Teaching-HTL-Leonding/novedu-chat-mvp`](https://github.com/Teaching-HTL-Leonding/novedu-chat-mvp) | The **novedu** app (novedu.at) that runs AI learning activities, plus the CLI that validates and publishes them | Chapters link to a **quiz** by its activity code; the quiz YAML lives here but is served to novedu from this repo's raw URLs |

```text
                     ┌──────────────────────────────┐
                     │  this repo (the book)        │
                     │  chapters .qmd + quiz .yaml  │
                     └───────┬──────────────┬───────┘
       {{< example url >}}   │              │   {{< quiz code >}}
                             ▼              ▼
              ts-web-playground        novedu (novedu-chat-mvp)
              exercise YAML +          renders <base>/<code>, reads the
              browser IDE + p5.js      quiz YAML back from this repo's
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

### Relation to `novedu-chat-mvp` (the quizzes)

Every chapter ends with a "Check your understanding" quiz: open-ended questions, graded by
a small LLM against a hidden rubric, with an optional per-question discussion chat.
Students take them anonymously as self-checks, and answers in German are accepted.

Those quizzes run on **novedu**, the app built in `novedu-chat-mvp`. A teacher mints a
short **activity code** for a quiz, and the chapter links to it with the `quiz` shortcode:

```markdown
{{< quiz t8bw13i9of title="Your first program" >}}
```

which renders a callout linking to `novedu.at/<code>`. The book never contains the
questions themselves.

The quiz *sources* do live here, as `<chapter>-quiz.yaml` next to each `.qmd`, because
novedu reads activity YAML from a public URL on every load. It reads this repository's raw
GitHub URLs, so publishing a quiz edit is a `git push`: no re-upload, and no new code. A
code is minted once, on first publish, with the novedu CLI, which also validates a quiz
file against the app's own rules before it goes live.

`ddp-quiz-fragments.yaml` in the repo root is a shared prompt-fragment library: every
chapter quiz pulls the same student-context and grading preamble from it. Editing that one
file changes every quiz at once.

## Repository layout

| Path | What it is |
| --- | --- |
| `_quarto.yml` | Book definition: chapter order, output formats, and the playground and novedu base URLs |
| `index.qmd` | The preface |
| `0010-introduction/`, `0020-variables/` | Book parts. Numbered folders and files: a chapter `.qmd` next to its `<chapter>-quiz.yaml` and its images |
| `_extensions/` | The Quarto extensions providing the `example`, `playground`, and `quiz` shortcodes |
| `ddp-quiz-fragments.yaml` | Shared novedu prompt fragments used by every chapter quiz |
| `.agents/skills/` | Authoring skills for AI agents; see below |
| `.github/workflows/` | CI: renders the book and uploads the PDF and the zipped website as artifacts |
| `_output/`, `.quarto/` | Build output. Git-ignored |

Chapters are ordered by the `book.chapters` list in `_quarto.yml`, not by file name. Adding
a chapter means adding the file **and** listing it there.

Both shortcodes render for paper as well as screen: in the PDF, where a button is dead ink,
the callout also carries a QR code and the printed address.

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

Which repository does a change belong to? An **exercise** (task, starter code, solution,
result image) is `ts-web-playground`. A **platform** change to how quizzes are graded or
displayed is `novedu-chat-mvp`. A quiz's **questions**, and everything a student reads
around them, is here.
