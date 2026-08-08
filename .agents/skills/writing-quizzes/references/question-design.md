# Question and rubric design — research-based guidance

Distilled (Aug 2026) from university teaching-center guidance, item-writing
literature, ESL assessment fairness guidelines, and recent studies on LLM
grading of short answers. Sources at the end. Apply the checklist at the
bottom to every question before publishing.

## Writing the question (student-visible)

**One construct per item.** Each question tests exactly one concept tied to a
chapter takeaway. Compound items dilute what's measured and confuse both the
student and the rubric (Haladyna/TIMSS item-writing guidelines). This is the
research grounding for the course's max-two-sub-questions rule.

**Use one specific task verb, chosen for cognitive level.** *Explain, trace,
predict, fix, name* — the verb tells the student the expected operation and
the rubric its target (Yale Poorvu). Prefer explanation and prediction over
recall: "what does this draw, and why?" beats "what is a statement?" —
answers in the student's own words reveal understanding and can't be guessed
(Waterloo CTE). Bug-finding and predict-the-output stems are also the shapes
that LLM graders handle most reliably, because the answer space is bounded.

**Put all context in the stem.** Show the code snippet, the values, the
picture — never make the student recall setup from memory. For beginners this
narrows what can go wrong to the one tested concept (Yale Poorvu).

**Avoid ambiguity and cross-item cueing.** Wording that can be read two ways
is the top failure mode of open questions (Waterloo; Lister's "explain in
plain English" studies showed prompt wording alone changes answers). Also
check the quiz as a whole: no question may leak another's answer — with
`shuffle: true` students see them in any order, so a leak works both ways.

**Signal expected length.** "One or two sentences are enough" bounds the
answer space, calms ESL students, and improves grading reliability (Yale;
Harvard Bok). Keep suggested lengths SHORT — LLM judges over-reward long
answers, and padded ESL prose gets worse, not better. Put a general length
hint once in the quiz `description`; add per-question hints only where a
question deviates.

## ESL and beginner fairness

Measure programming understanding, not English (ETS ELL guidelines):

- Common words, one clause per sentence, active voice. No idioms, no
  negation traps ("which is NOT…").
- Use technical terms exactly as the chapter introduced them; gloss words
  with both an everyday and a technical meaning (statement, argument).
- A correct answer must be expressible in simple English or code. The shared
  preamble already tells the grader to ignore language quality — the
  question must cooperate by not requiring elegant prose.

## Writing the rubric (server-only `evaluation`)

The research reconciles two findings that pull in opposite directions:
detailed rubrics improve LLM grading (Springer 2025), but fine-grained
verdict scales wreck it — moving binary → 5-way dropped accuracy 76%→57% in
one study, with "partial" absorbing irrelevant answers (arXiv 2601.08843).
The resolution, and this course's slim-rubric template, is: **concrete,
procedural criteria mapped onto the coarse 3-verdict scale.**

- **Procedures, not adjectives.** "States that the background is painted
  after the circle" — never "shows good understanding" (Galtea). Each
  verdict bullet should read like a check a human marker would perform.
- **Define `partial` tightest.** It is the verdict LLM graders get wrong
  most; describe the *specific* half-right answer you expect, not "partly
  correct". `incorrect` can stay "anything else" plus one classic
  misconception.
- **Anticipate paraphrases.** Synonym substitution is the perturbation that
  most degrades LLM grading. Where students will use everyday words for the
  expected idea ("size" for diameter, "the computer skips it" for ignores),
  say in the rubric that these count.
- **Verdicts fail safe.** LLM graders are systematically lenient. The shared
  preamble instructs: when unsure between two verdicts, choose the lower
  one. For an ungraded self-check, a too-cautious "partial" sends the
  student back to the chapter — cheap; a false "correct" hides a gap.
- **No length reward.** The shared preamble states that short answers score
  equal to or better than long ones at the same correctness.
- **Questions with a literal result keep the literal value** (`[2, 4, 1, 5]`,
  `background`, width-then-height) — exact anchors are what a small judge
  model grades most reliably against.

What the course deliberately does NOT do, despite literature support:
example answers per verdict in every rubric (Mertler/CMU recommend them).
They roughly triple rubric length for marginal gain on simple items. Add an
example answer only to a rubric that student reports show is wobbling.

**Calibrate like code.** Pair each chapter quiz with a golden-answer eval file
and keep known correct, deliberately partial, and confidently wrong answers as
regression cases. Validate the pair after edits, then run the eval through the
real grader when authorized. The correct/partial boundary and false-correct
cases are the parts to probe. See `golden-answer-evals.md` for the course's case
design and CLI workflow.

## Audit checklist

Before publishing, check every question:

1. Tests one concept from the chapter; one or at most two sub-questions.
2. One specific task verb; prefers explain/predict/trace/fix over recall.
3. All context (code, values, image) is in the stem.
4. No wording that can be read two ways; no question leaks another's answer
   (remember: shuffle shows them in any order).
5. Simple sentences, taught vocabulary only, answerable in plain English.
6. Bounded answer space (a "discuss"-shaped question is a rubric hazard).
7. Rubric: expected answer stated once; verdict bullets are procedures;
   `partial` describes the specific expected half-answer; accepted
   paraphrases listed; literal values kept literal.
8. Quiz `description` carries the length hint ("one or two sentences are
   enough").
9. Paired golden-answer eval updated: each changed rubric has a correct case,
   every meaningful partial branch, and a confidently wrong case; the eval
   validates, and the real grader run is green when one was authorized.

## Sources

- Yale Poorvu Center, Designing Assessment Questions —
  https://poorvucenter.yale.edu/teaching/teaching-resource-library/designing-assessment-questions
- Waterloo CTE, Exam Questions: Types, Characteristics, Suggestions —
  https://uwaterloo.ca/centre-for-teaching-excellence/catalogs/tip-sheets/exam-questions-types-characteristics-and-suggestions
- CMU Eberly Center, Rubrics —
  https://www.cmu.edu/teaching/assessment/assesslearning/rubrics.html
- Mertler, Designing Scoring Rubrics for Your Classroom (PARE) —
  https://www.clarku.edu/centers/cetal/www-content/blogs.dir/7/files/sites/42/2020/01/Designing-scoring-rubrics-for-your-classroom.-Practical-Assessment-Research-Evaluation.pdf
- Haladyna item-writing guidelines —
  https://site.ufvjm.edu.br/fammuc/files/2016/05/item-writing-guidelines.pdf
  and TIMSS/PIRLS —
  https://timssandpirls.bc.edu/publications/timss/T15_item_writing_guidelines.pdf
- ETS, Guidelines for the Assessment of English Language Learners —
  https://www.ets.org/pdfs/about/ell-guidelines.pdf
- Springer 2025, Automated Scoring of Short Answer Questions with LLMs —
  https://link.springer.com/chapter/10.1007/978-3-031-98465-5_6
- Rubric-Conditioned LLM Grading (arXiv 2601.08843) —
  https://arxiv.org/html/2601.08843
- Galtea, LLM-as-a-Judge best practices —
  https://galtea.ai/blog/llm-as-a-judge-prompts-templates-rubrics-and-best-practices
- Lister et al., Going SOLO to Assess Novice Programmers —
  https://opus.lib.uts.edu.au/bitstream/10453/10719/1/2008001283.pdf

(The 2025-2026 LLM-grading numbers are preprint-based; treat exact figures
as indicative. The qualitative direction — detailed-but-coarse rubrics,
partial is the weak verdict, verbosity bias is real — is consistent across
independent studies.)
