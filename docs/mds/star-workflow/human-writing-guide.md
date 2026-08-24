# Human writing in an evidence-bound research project

**Language:** English | [简体中文](human-writing-guide.zh-CN.md)

This guide adapts common observations about formulaic AI prose to research plans, literature notes, experiment reports, method documents, README files, and agent replies.
Its purpose is clearer technical writing and a stable authorial voice, not guessing how text was produced or defeating an AI detector.
The evidence, provenance, status, and file-ownership contracts in [research-workflow-conventions.md](research-workflow-conventions.md) always take priority.

## 1. Non-negotiable boundaries

Making prose sound natural is a language edit, not permission to change the research record.

- Preserve every fact, number, date, quotation, citation key, source URL, path, command, field name, field value, status, done-criterion, technical term, uncertainty boundary, negative result, and attribution.
- Do not add a concrete detail merely to replace a vague sentence.
  Use a recorded source, retain an accurate limitation, leave the owning template's `TODO` / `[TBD]`, or report the gap to the workflow that owns it.
- Do not add first-person opinions, humor, emotion, personal experience, or deliberate irregularity unless the user supplied that voice and the document's purpose supports it.
- Do not simplify a necessary technical distinction, strengthen a claim, or delete a qualifier that carries evidential meaning.
- Treat quotations, titles, proper names, code, mathematical notation, literal commands, YAML frontmatter, tables of data, link targets, identifiers, and source excerpts as protected text unless the task explicitly owns them.

## 2. Match the writer before applying defaults

When the user provides a writing sample, or names an existing document as the voice to preserve, read it before drafting or editing.
Observe sentence length, paragraph movement, preferred transitions, punctuation, qualification, repeated terms, formatting habits, and deliberate quirks.
A user-confirmed sample outranks the defaults below.

Without a sample, use a restrained technical default:

- state the substantive point before announcing its importance;
- prefer stable technical terms to decorative synonyms;
- name the actor when agency matters;
- connect evidence to the local inference, then connect that inference to the research question or decision;
- vary sentence length when the reasoning calls for it, not at random;
- use headings and lists only when they make structure easier to inspect;
- end on the last useful implication, limitation, action, command, or blocker rather than a generic endorsement.

## 3. Patterns that merit review

No single word or construction proves that a passage is formulaic.
Review a passage when several patterns accumulate or when one high-confidence chatbot artifact appears.

### Inflated significance

The prose makes an ordinary design choice or result a pivotal moment, enduring testament, broad transformation, or major contribution without a mapped claim and evidence.
Replace the ceremonial framing with the specific result and its supported consequence.

Chinese warning shapes include unsupported uses of “具有重要意义”, “标志着关键转折”, “彰显了重要性”, and “为……奠定坚实基础”.
English warning shapes include unsupported uses of “pivotal”, “stands as a testament”, “underscores the importance”, and “evolving landscape”.

### Vague attribution

Phrases such as “experts argue”, “industry reports show”, “已有研究表明”, or “学者普遍认为” hide the source of a research claim.
Name the verified source and the proposition it supports.
If no source supports the assertion, do not invent one.

### Shallow analytical tails

A sentence reports a fact and then appends a broad consequence with “highlighting”, “underscoring”, “thereby demonstrating”, “从而彰显”, or “进而说明”.
Keep the consequence only when the reasoning or evidence establishes it, and express the inferential step directly.

### Formulaic contrast and symmetry

Repeated “not only X but Y”, “not merely X; it is Y”, “不仅……而且……”, forced groups of three, or paragraphs with identical internal shapes can make prose sound assembled from a template.
Retain a contrast or parallel structure when it carries a real distinction.
Otherwise state the operative point without staging a rejected alternative.

### Generic signposting

Openers such as “it is important to note”, “this section delves into”, “值得注意的是”, “不难发现”, and repeated descriptions of what the next paragraph will do delay the content.
Remove a signpost when the heading or the following sentence already supplies the orientation.
Keep roadmaps that genuinely help a reader navigate a long or structurally complex argument.

### Stock challenges, outlooks, and endings

Generic “challenges and future outlook” sections, claims that work “continues to thrive”, or conclusions that promise a bright future add no research decision or supported synthesis.
End with the supported finding, limitation, open question, concrete next step, or routing decision.

### Terminology cycling

Replacing a repeated technical term with near-synonyms can change its scope or make one entity appear to be several.
Use the canonical term from the plan, code architecture, or source material and vary the surrounding syntax instead.

### Hidden agency and abstract noun chains

Passive voice is useful when the actor is unknown, irrelevant, or already established.
Revise it when it obscures who designed, measured, decided, or inferred something.
In Chinese prose, also review long chains built from “通过……实现……从而……进而……” when the actions and actors can be stated directly.

### Uniform cadence and manufactured emphasis

A run of equal-length sentences, repeated sentence openings, dramatic fragments, fake-candid hooks, or slogan-like claims can impose emphasis the evidence has not earned.
Rewrite around the paragraph's main proposition.
Do not create arbitrary variation, and preserve deliberate repetition that has a clear rhetorical function.

### Decorative structure and chatbot residue

Greetings, praise, staged announcements, excessive bold labels, headings that restate themselves, service offers, knowledge-cutoff disclaimers, “I hope this helps”, “Would you like me to continue?”, “希望这对您有帮助”, and similar scaffolding delay or survive past the answer.
Remove them rather than replacing them with a more formal synonym.
Keep formatting that helps a reader compare fields, follow a dependency, or execute a procedure.

### Filler and stacked qualification

Remove phrases that only delay a claim, such as “in order to”, “due to the fact that”, “为了实现这一目标”, or “在这一背景下” when the background has already been established.
Collapse stacked hedges, but preserve calibrated terms such as *may*, *under the evaluated conditions*, or “在本研究范围内” when they define the claim boundary.

## 4. False-positive safeguards

Do not impose a ban on em dashes, passive voice, transition words, three-item lists, long sentences, formal vocabulary, bold text, headings, or first person.
Each can be appropriate in technical writing.
Flag density and function, not mere presence.

Keep:

- a qualifier required by evidence, experimental scope, safety, or legal accuracy;
- a named objection that the text actually answers;
- a real alternative in a method, design, or implementation discussion;
- deliberate parallelism used to compare mapped cases;
- established technical uses of words that may be fashionable elsewhere;
- punctuation and cadence that match a user-confirmed sample;
- quoted wording and faithful descriptions of a cited source;
- literal status, command, path, and field text required by another workflow step.

## 5. Drafting and revision process

Use this sequence for a long reply or a prose artifact:

1. Establish the passage's job, audience, source files, and research decision it must support.
2. Mark protected content: facts, numbers, citations, quotations, source URLs, paths, commands, literals, claim strength, technical terms, uncertainty, negative results, and attribution.
3. Diagnose patterns at paragraph scale.
   A cluster matters more than an isolated watched word.
4. Rewrite around the main proposition instead of patching each watched phrase.
5. Read the passage for cadence, explicit agency, terminology stability, useful formatting, and a concrete final sentence.
6. Compare the revision with the source and restore any lost, weakened, or strengthened claim.
7. Return only the final prose unless the user asked for an audit or explanation.
   In file mode, change prose only and preserve code blocks, frontmatter, data, links, quotations, and literal fields.

For a multi-document pass, also compare openings, summaries, method recaps, contribution statements, limitations, and endings for repeated templates.

## 6. Review verdicts

Do not assign a numerical “human score” as though authorship were measurable from prose alone.
Use these review dimensions instead:

- **claim fidelity:** all protected research content is unchanged;
- **specificity:** importance and implications are tied to recorded evidence or reasoning;
- **directness:** the passage reaches its substantive point without ceremonial setup;
- **cadence:** sentence and paragraph structure follows the reasoning rather than a repeated template;
- **voice consistency:** terminology, stance, punctuation, and formatting agree with the user or the document's established voice;
- **reader trust:** the prose neither over-explains routine points nor hides necessary qualifications.

A passage is ready only when claim fidelity passes.
The other dimensions identify revision needs; they do not classify the author.

## 7. Sources and adaptation

This guide adapts ideas from:

- [`blader/humanizer` version 2.11.2 at commit `e2e92e7`](https://github.com/blader/humanizer/blob/e2e92e7b4b8229253ed5c8e81dc65463fdeddda5/SKILL.md), MIT licensed, including its claim-preservation rule, writer-sample priority, pattern clusters, paragraph-level rewrite, and false-positive safeguards;
- [`op7418/humanizer-zh` at commit `91f3d39`](https://github.com/op7418/humanizer-zh/blob/91f3d394db8419c20d67ebe22a96cf8fee0a404b/SKILL.md), MIT licensed, including its Chinese pattern adaptations and review dimensions.

The wording and research workflow here are STAR-specific and aligned with STORY's evidence-bound human-writing contract.
Where either source suggests adding personality or concrete detail, STAR's provenance, evidence, and user-voice contracts govern.
