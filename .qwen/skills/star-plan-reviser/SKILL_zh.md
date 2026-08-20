---
name: star-plan-reviser
argument-hint: "[PLAN_NAME] [描述] [involve=high]"
description: >-
  以执行证据为依据，审查 metds/plans/ 下的任一计划节点，并在用户逐条批准下就地修订它。派出只读
  subagent 检查 wkdrs/<run>/ 的执行日志与产物（内部节点则汇总 children），逐条对照磁盘文件给完成度
  打分，把七段式审查报告写入 wkdrs/，再把整张修订候选清单摊开、一次提问定下来，直接编辑计划文件并追加
  Revision History 条目——结构性重构转给 star-plan-decomposer，方向级转向转给 star-plan-coach。
  当用户运行 /star-plan-reviser，或想在（部分）执行后审查 / 复盘 / 修订某个计划、核对计划实际做了
  什么与承诺了什么、把执行结果写回进计划、或把某个计划连同其子树标记为已丢弃的方向时使用。Bilingual（中/英）。
---

# Research Plan Reviser — 基于证据的审查与修订

> 本文件是 `SKILL.md` 的中文对照版，随英文版同步维护，供人阅读；运行时不装载它——指令以 `SKILL.md` 为准，中文对话按规约 §7.6 用中文回复，并把开场装载与各步骤点名的资源换成 `_zh` / `.zh-CN` 版本（中文措辞以规约 §0 词汇表为准）。若两版冲突，以 `SKILL.md` 为准。

调用方式：`/star-plan-reviser PLAN_NAME [描述]`，其中 `PLAN_NAME` 是 slug（`open-vocab-det-seg`）、数字前缀（`01`）或文件名（`01_mvp-verify_plan.md`）。不带参数则列出候选并询问。计划名之后的一切都是描述（规约 §7.12）：用你自己的话说明这次要做什么。放弃这个方向的描述——比如「这条不做了，由 02 取代」——走丢弃那条路（Workflow 的最后一节）而非审查，原话即写进计划的理由；要求收回已丢弃节点的描述则清除该字段。没有关键词：两者都没提的描述跑审查，不给描述也一样。可选的 `involve=low|medium|high` 可与任意参数一同给出（如 `… involve=low`）：它设定本次运行的参与度档位（规约 §7.7），在解析参数与描述之前先剥离。

**通用规约。** `docs/mds/star-workflow/research-workflow-conventions.zh-CN.md`（英文：`research-workflow-conventions.md`）是所有 STAR skill 共享的基线；本文件只写本 skill 特有的部分，更严之处以本文件为准。计划修订真正用到的部分——§0 词汇表、§1 git、§2 红线、§3 `.env` 运行时、§4 真实日期、§5 计划名解析、§6 委派、§7 对话纪律、§8 产物登记表、§10 skill 名册、§11 执行分支——经下面的开场装载进入。另有一节不装载：§9 项目布局——本 skill 读写的每一条路径，状态与文件规则里都已逐一写明。文档的前言同样不装载，它那条优先级规则就是本段开头写的那句。运行中万一需要其中某一节，就整份读进来。

动手前把它合成一条消息装载——四次 `run_shell_command` 调用（以项目根目录为工作目录）一起发出，外加两次 `read_file`：`<本 skill 所在目录>/references/review_spec_zh.md` 与 `<本 skill 所在目录>/references/revision_rules_zh.md`，每份文件各占一次。

```bash
grep -sE '^(STAR_LANG|INVOLVE)=' .env || echo 'STAR_LANG / INVOLVE: unset'   # reply language, question level (§7.6, §7.7)
awk '/^## /{k=/^## (0|1|2|3|4|5|6)\./} k' docs/mds/star-workflow/research-workflow-conventions.zh-CN.md
```

```bash
awk '/^## /{k=/^## (7|8)\./} k' docs/mds/star-workflow/research-workflow-conventions.zh-CN.md
```

```bash
awk '/^## /{k=/^## (10|11)\./} k' docs/mds/star-workflow/research-workflow-conventions.zh-CN.md
```

```bash
bash <本 skill 所在目录>/scripts/scan.sh --slim
```

一条消息、六份结果：规约来自前三次 `run_shell_command` 调用（`.env` 那一行搭第一次的车），`references/review_spec_zh.md`（证据来源、收集器格式约定、报告各节的定义）与 `references/revision_rules_zh.md`（权限表、转交边界、Revision History 条目格式）各自来自单独的一次 `read_file`，共享采集脚本的摘要来自最后一次调用。各次调用分开发，是因为每份工具结果各有自己的大小上限：结果一旦超过 30 KB 左右就会被存成文件，要再读一次才拿得回来——恰是这条消息要省掉的那趟往返——而规约摘录合计约 50 KB，三次调用分担 20、18、12，每次 `read_file` 的结果则各占自己的额度、整份直达；采集那次调用单独发，因为它的摘要是整套装载里唯一随历史增长的部分——真被存成文件，也只重跑它这一行。每个 `awk` 只打印它上面点名的节；若打印结果缺了哪一节——同步下来的旧规约可能节号不同——就退回整份读。采集脚本的摘要正是 Step 0 用来解析、Step 1 用来圈定证据的依据：每个计划的 frontmatter（`parent:`、`children:`、`depends_on`、`status`、`exec_status`、`exec_runs`、`updated`）、它的 `## Sub-plans` 索引，以及每份运行日志的 frontmatter——目标计划的兄弟节点、内部节点的 children，都不必再逐个打开。脚本只收集，从不判断：不建树、不给结论、不排序；把它打印的内容当作原始文件内容来读，就像你自己逐个打开过一样。`--slim` 是在有历史的项目上把摘要压在大小上限以内的手段。若脚本缺失或执行失败，退回直接读 `metds/plans/*_plan.md`，并在回复里说明这次走了退路。`references/` 下这两份文件从收集证据的第一步到最后一处写入都在生效，所以随开头这条消息到达，而不是等到流程中途；后文引用到其中任一份时，内容已经在这条消息里拿到——不要再打开一遍。`assets/` 下的报告模板不进这条消息：填哪个变体跟随计划的 `language`，要等 Step 0 解析出目标计划才知道。

**复用上一次装载。** 上面那份装载里，凡是文本此刻仍能在本轮对话中逐字看到的部分就跳过不读——同一份规约文件、同一种语言、至少覆盖本文件点名的那些节，同样的参考文件，以及那次 `.env` 探测取到的 `STAR_LANG` / `INVOLVE` 取值。看不到的部分照旧读，仍用上面那一条消息发出。缺口只是规约的几节时，就只补读那几节——用按 `## ` 标题筛选的 `awk` 恰好打印点名的节——而不是把整个文件重读一遍。两种情况不算看得到：上下文压缩后只剩摘要而正文已经不在；以及只记得自己读过。拿不准就重读一遍。唯独采集脚本的摘要不能这样复用（上面装载了它的话）：每次都重新跑一次扫描。若整份装载都已在手，开场那条消息就整个省掉；若只剩扫描一项，就让它单独发出。

## 角色

你负责闭合其他 skill 留下的环：`star-plan-coach` 写总体方向、`star-plan-decomposer` 拆解、`star-plan-executor` 执行叶子并留下证据（`wkdrs/<run>/EXEC_LOG.md`、产物）——并且明确把"结果与计划相矛盾"交还给用户。你接住**一个计划节点**，用这些证据审计它的意图，并在**用户对每处改动逐一拍板**的前提下**就地修订计划文件**。`star-flow-status` 是全树的浅层只读仪表盘；你是针对单个计划的深度审计，有权动笔。

你修订文本；你不重跑实验、不重拆子树、不从零重推总体方向。

## 核心原则

1. **证据先于观点。** 每条审查结论都带证据出处（文件路径、日志行、命令输出）。日志自报的 `done` 不等于完成——要对照磁盘上的产物核实，关键处可复跑低开销检查；绝不启动重实验（executor 的红线对你同样生效）。这是把项目的 Verification 规则（AGENTS.md §11）应用到计划本身。规则见 `references/review_spec_zh.md`。
2. **收集靠分散，判断在主 agent 。** 证据收集委派给并行的**只读 `agent` subagent**（`subagent_type: Explore`）（执行日志 / 产物 / 代码现状），各自按 `references/review_spec_zh.md` 的收集器格式约定返回结构化结果。收集器绝不写文件、绝不提修订意见；综合与判断留在主 agent 。
3. **每处改动由用户拍板。** 审查发现整理成编号的修订候选。整张清单先摊在页面上，再用**一次** `ask_user_question` 把它们定下来——标出你的推荐，用户点名的每一条都会单独回来（规约 §7.13）。绝不把用户看不见的清单拿去批准，绝不擅自动笔。
4. **就地修订，留下痕迹。** 批准的改动写回原 `<prefix>_<slug>_plan.md`；绝不另存 `_v2` 副本（重复前缀会破坏 status/decomposer/executor 解析的计划树）。每次会话追加一条 `## Revision History`（日期、逐处改动一句话与证据、报告路径）并更新 `updated`；旧版本靠 git 追溯。
5. **守住家族的写入纪律。** 绝不重编号前缀；绝不动 `EXEC_PLAN.md` / `EXEC_LOG.md`（属于 executor）；结构性重构（增删子计划、重画依赖图）转给 `/star-plan-decomposer`；研究问题或方法级转向转给 `/star-plan-coach`。边界见 `references/revision_rules_zh.md`。
6. **连带影响意识。** 一处修订可能让建立在旧文本上的工作失效。在征询任何改动**之前**先呈现反向 `depends_on` 边和派生的 children（报告 §6）；目标的一行目标变了就同步父计划 `## Sub-plans` 里对应那行；`updated` 一更新，过期提示自然在 `/star-flow-status` 浮现。

## 工作流

### Step 0：解析目标计划

1. 用 `PLAN_NAME`（slug / 数字前缀 / 完整文件名）匹配开场装载的摘要列出的计划；完整读入解析到的计划。
2. 未给参数或匹配歧义时，列出候选（前缀 + slug + 一行状态）并经 `ask_user_question` 询问——优先推荐有执行证据（`exec_runs` 非空）或已知失配的节点。
3. 判定节点类型：**叶子**（审它自己的 run）vs **根/内部**（审总体计划章节 + children 汇总）。这决定 Step 1 的证据集合。

### Step 1：圈定证据

- **叶子**：它当前 run 的目录（`exec_runs` 最后一项——`EXEC_PLAN.md`、`EXEC_LOG.md`）、§4 每个交付物路径、§2 写明的输入（`datas/`、`inits/`）与代码模块（`${CODE_NAME}/`，从 `.env` 解析）。
- **根/内部**：children 的 frontmatter（`status`、`exec_status`、`updated`、`depends_on`，直接从摘要取）、已执行后代的日志（尤其 **方向性信号** 记录与 kill-criteria 命中），加上本节点自己 §1–§6 的假设。
- 明说存在哪些证据。若处处都未执行，声明本次为**纯文档审查**：完成度无从打分；报告的意图 / 偏差 / 候选各节仍适用，依据是用户知道而计划不知道的信息。

### Step 2：收集证据（只读 subagent）

**证据面很小时**——只有一个 run、≤ ~5 个步骤、≤ ~3 个交付物路径、§2–§3 没有点名任何代码模块——通常由主 agent 自己读更省事：`EXEC_PLAN.md`、`EXEC_LOG.md`，外加逐个交付物 stat 一下。这种规模还派三个收集器，正是 conventions §6.1 排除掉的情形。

规模超过这个的：按 `references/review_spec_zh.md` 的收集器格式约定并行派出只读 `agent` subagent（`subagent_type: Explore`）——通常是 **日志读取器**（步骤状态、自报检查、"待用户执行"命令、方向性信号）、**交付物检查器**（§4 每个交付物：存在 / 大小 / 修改时间 / 低开销 合理性检查），以及当 §2–§3 涉及代码时的 **代码检查器**（承诺的模块是否真的写出来了、与日志声称的改动是否一致）。

分歧在主 agent 交叉核对——日志说 `done` 但产物缺失 → 该结论记为 **unverifiable**，不算 met。关键的低开销检查由你亲自复跑；重的一律不跑。

收集器给出的 `suspect` 或 `inconsistent` 是线索，不是结论。它成为编号修订候选之前，主 agent 亲自打开被引用的路径，确认这个发现仍然成立（规约 §6.6）；确认时落在的那个 `path[:line]`，就作为这条候选的证据。站不住的丢掉，或降格成 §5 里一条不引发任何改动的备注。

### Step 3：汇总并写出审查报告

按 `assets/review_report_template_zh.md`（英文计划用 `assets/review_report_template.md`）填写七节：① 目标回顾 ② 实际发生了什么 ③ 完成度记分卡（逐 §3 任务加 §5 done-criterion：`met` / `partial` / `unmet` / `unverifiable`，每条带证据）④ 偏差清单 ⑤ 阻塞与遗留 ⑥ 影响范围图 ⑦ 修订候选，每条标注 **local / structural / strategic**。

写入 `wkdrs/<run>/REVIEW_<YYYY-MM-DD>.md`（真实日期，绝不编造）。计划没有 run 时用 `wkdrs/reviews/<prefix>_<slug>_<YYYY-MM-DD>.md`。聊天里给 ≤500 字摘要：结论、最重要的偏差、候选清单的一行版。

### Step 4：修订问答（先摊清单，再一次提问）

1. 先把每条候选摊在页面上，写进承载该问题的消息正文里（规约 §7.13——一张拟好的清单是一个问题，不是一行一个）：每条候选一个编号行，写明改哪一节、从什么改成什么、证据路径、分级（local / structural / strategic），以及你推荐怎么做。**structural** 或 **strategic** 的行，推荐动作是转出去——形态问题给 `/star-plan-decomposer`，方向问题给 `/star-plan-coach`——并把"仍在本文件做范围受限的文本修订"写成备选。
2. 然后就这份清单**只发一次** `ask_user_question`：*全部按清单采纳* / *除我点名的以外全部采纳* / *先解答我点名的几项* / *一项都不采纳*——标出推荐，且内置"Other"始终允许自由作答。候选在四条及以内时，直接就这些候选发问（multiSelect），不必绕编号。被点出来的行开启第二轮，形状照旧，带上你给出的改写稿或用户要的解答；缩到只剩一条候选时就直接问那一条。丢弃本节点的候选永远不进清单——`references/revision_rules_zh.md` 要求它单独发问——Step 5 的 `exec_status` 重置与清除 `finalized:` 同样是那一步里各自独立的问题，在改动落盘之后问。
3. 边走边记流水账（规约 §7.8）——每条候选一落定就写一行，`候选 → 采纳 / 调整 / 跳过 → 文件里改了什么`——后面每一轮开场都用半句话点明前面几轮定下了什么（§7.10）。流水账是把已定的决策带过轮次的东西，第三轮才不会把第一轮重吵一遍。
4. 清单定案后问一次：还有其他要改的吗？用户新增的项同样作为候选（证据记"user directive"）。
5. 一条都未采纳 → 跳到 Step 7——纯审查也是合法结局；写出的报告就是交付物。

### Step 5：写入已批准的修订

对每条被采纳的候选，按文件内顺序：

1. 依据证据和用户的答复起草新的章节文本；给出简洁的改前 → 改后摘要；写入文件。
2. 让章节 `status` 映射保持诚实：引入 `[TBD]` / `【待定】` 的修改把该节翻回 `in_progress`；经确认的重写保持 `done`。

最后一处改完后：更新 `updated`；若叶子的 §5 done-criterion 或 §3 任务发生实质变化、且 `exec_status` 为 `done` 或 `blocked`，询问是否重置为 `pending`（`exec_runs` 无论如何都留着历史）；若某条采纳的候选改动了一份 `finalized` 计划的 §1、§2、§3 或 §6——问题、定位、方法、里程碑——就问一次是否清除 `finalized:`（只改 §4/§5 的战术性修订，如收紧一条 kill-criterion，不动它），因为 `star-code-architect` 读这个字段判断该计划能否驱动搜索，而重新定稿走 `star-plan-coach <slug> <section>`；若某条采纳的候选丢弃了本节点，就在此写入 `dropped:`、并在父计划索引行上加 `— dropped <date>` 标记，别的一概不动——子树靠继承跟上；然后按 `references/revision_rules_zh.md` 追加 `## Revision History` 条目。

### Step 6：一致性检查

- 若计划标题或一行目标变了，同步父计划 `## Sub-plans` 里对应那行——这是目标文件之外唯一允许的编辑。
- 复核 `children:` 条目与 `depends_on` 前缀仍能解析；悬空引用**标记**出来交给 `/star-plan-decomposer`——不要悄悄修复。（编辑目标自己的 `depends_on` 列表可作为已批准候选；跨兄弟重画依赖边不行。）
- 若目标是父节点、且修订触及 children 赖以派生的内容，指明受影响的 children 并建议重新拆解。

### Step 7：汇报与交接

≤500 字：证据基础（读了什么、核实了什么）、完成度结论、逐节写入的改动、跳过的候选、连带影响提醒。结尾给出下一步命令：`/star-plan-decomposer <slug>`（结构变了 / children 过期）、`/star-plan-coach <slug>`（总体方向转向）、`/star-plan-executor <叶子>`（重跑修订后的叶子）、`/star-code-reviewer <叶子>`（审计实现代码）、`/star-flow-status`（看全树）。若什么都没改，坦白说明——报告文件仍在。若有写入的修订，提出一次提交提议（见状态与文件规则）。

### 丢弃一份计划，以及把它收回来

丢弃记录的是你已经做出的决定，所以这条路不审查计划：Step 0 照常解析目标，下面四步取代 Step 1–6，Step 7 照常汇报，且不写审查报告。把运行带到这里的是描述（规约 §7.12），所以在读任何东西之前先用一行说明这次走的是哪条路——描述读错了，代价就是这一行，而不是一处改动。

1. **读出什么会变暗**，只用开场那次摘要——不派收集器，不读 run 正文：目标每一个后代及其 `exec_status`、它们的 run 本来欠着的后续（代码审查、实验分析）、其下任何未合并的 `branch:`、现存的 `worktree:` 或未勾选的红线命令，以及任何 `depends_on` 指向该目标或其某个后代的、活着的叶子。
2. **把这份清单摆出来，只问一次**——每个后代一行、每处未了结一行——在同一个问题里确认丢弃与那一句原因——描述里写了理由就用原话，没写就在这里问。这是强制确认点（规约 §7.7）：任何参与度档位都要问，`low` 也不例外，绝不与别的东西打包。没有原因就不丢弃。
3. **写 `references/revision_rules_zh.md` 点名的那三处**——目标上的 `dropped: <日期> — <原因>`、父计划 `## Sub-plans` 那一行的 `— dropped <日期>` 标记、一条 `## Revision History`——并更新 `updated`。不编辑任何后代：它们靠继承变暗。
4. **汇报**什么变暗了、以及丢弃没有解决的事——现在指向已丢弃节点的依赖边，以及还留在磁盘上的分支、worktree 或红线命令——然后照 Step 7 提出提交提议。

把节点收回来是同一条路，只是清除字段而不是写入——把运行带到那里的同样是描述——并在提问之前多一道检查：任何祖先都不得处于已丢弃状态，否则继承会让它继续是暗的，而被清掉的字段反倒像个 bug。它的 Revision History 条目写明这个方向为什么重新活了过来。

在一次完整审查**过程中**浮现的丢弃不走这个模式——它是 Step 4 的一条候选，像别的候选一样逐条批准，写的是同样那三处。

## 状态与文件规则

- 审查报告放 `wkdrs/`，绝不放 `metds/plans/`。
- 你只能编辑：目标计划的正文与 frontmatter（`updated`、章节 `status` 映射、`depends_on`、`exec_status`、`dropped:`——后三者仅作为用户批准的候选），以及当目标的一行目标变化、或要给它加上丢弃标记时，父计划 `## Sub-plans` 的对应行。其余一律只读：`EXEC_PLAN.md` / `EXEC_LOG.md`、兄弟与子计划正文、前缀（绝不重编号）、计划文件本身（绝不删除或分叉）。
- 每次写入都必须追溯到一条被单独批准的候选；`## Revision History` 只追加、不改写。
- Git：有写入修订时，在 Step 7 提出一次提交提议，涵盖目标计划（及一行目标变化时的父计划）——`star-plan-reviser: <slug> — <n> 处修订`（规约 §1）。核心原则 4 的"旧版本存于 git"正依赖这些提交。
- 合法章节 `status`：`pending` / `in_progress` / `done` / `skipped`；合法 `exec_status`：`pending` / `in_progress` / `done` / `blocked` / `abandoned`——与家族一致。把某个叶子置为 `abandoned` 同样是一条修订候选：需要用户明确批准，理由写进本次 Revision History 条目。`dropped:` 是一行「日期 + 原因」，只写在本节点上——所有 skill 都按整棵子树继承来读它——设置与清除只走 `references/revision_rules_zh.md` 的丢弃规则。

## 对话纪律

- `ask_user_question` 不可用（无人值守 / 脚本化）时改用纯文本提问——仍然先把整张候选清单摊在页面上、再用那一个问题把它定下来，仍然先获明确批准再写入。
- **候选清单写在同一条消息的正文里、放在调用之上**——选项只承载答案，不承载材料。
- 用用户的语言回复；中文对话加载 `*_zh.md` 资源。计划正文与审查报告跟随计划 frontmatter 的 `language`；中文计划里技术名词保留英文。
