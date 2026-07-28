---
name: star-plan-reviser
description: >-
  以执行证据为依据，审查 metds/plans/ 中的一份研究计划，并在用户逐条批准下就地修订它。读取
  wkdrs/<run>/ 的执行日志与产物（内部节点则汇总 children），逐条对照磁盘文件给完成度
  打分，把七段式审查报告写入 wkdrs/，再以一次一问的方式走完修订候选，直接编辑计划文件并追加
  Revision History 条目——结构性重构转给 star-plan-decomposer，方向级转向转给 star-plan-coach。
  当用户调用 $star-plan-reviser，或要求 Codex 在（部分）执行后审查、审计或修订某个计划，或把
  执行结果写回进计划时使用。支持中英文双语工作。
---

# Research Plan Reviser

> 英文默认版见 `SKILL.md`。无后缀文件为英文；中文资源使用 `*_zh.md`。按用户语言对话；中文对话加载 `*_zh.md` 资源。若 `SKILL_zh.md` 与 `SKILL.md` 冲突，以 `SKILL.md` 为准。

调用方式：`$star-plan-reviser PLAN_NAME`，其中 `PLAN_NAME` 是 slug（`open-vocab-det-seg`）、数字前缀（`00`）或文件名（`00_mvp-3way-ablation_plan.md`）。不带参数则列出候选并询问——优先推荐有执行证据或已被标记失配的节点。

**通用规约。** 动手前先读 `docs/mds/star-workflow/research-workflow-conventions.zh-CN.md`（英文：`research-workflow-conventions.md`）：§1 git、§2 红线、§3 `.env` 运行时、§4 真实日期、§5 计划名解析、§6 委派、§7 对话纪律、§8 产物登记表、§9 项目布局。那是所有 STAR skill 共享的基线；本文件只写本 skill 特有的部分，更严之处以本文件为准。

## 角色

闭合其他 skill 留下的环：`$star-plan-coach` 写总体方向、`$star-plan-decomposer` 拆解、`$star-plan-executor` 执行叶子并留下证据（`wkdrs/<run>/EXEC_LOG.md`、产物）——并且明确把"结果与计划相矛盾"交还给用户。接住**一个计划节点**，用这些证据审计它的意图，并在**用户对每处改动逐一拍板**的前提下**就地修订计划文件**。`$star-flow-status` 是全树的浅层只读仪表盘；本 skill 是针对单个计划的深度审计，有权动笔。

修订文本；不重跑实验、不重拆子树、不从零重推总体方向。

## 核心原则

1. **证据先于观点。** 每条审查结论都带证据出处（文件路径、日志行、命令输出）。日志自报的 `done` 不等于完成——要对照磁盘上的产物核实，关键处可复跑低开销检查；绝不启动重实验（executor 的红线同样生效）。这是把项目的 Verification 规则（AGENTS.md §10）应用到计划本身。规则见 `references/review_spec_zh.md`。
2. **默认在本地收集；选择性委派。** 自行读取日志、工件和代码状态。仅当对多个 run 或工件集合进行有边界、相互独立、只读的检查确有帮助时才委派收集；受委派者必须遵守 `references/review_spec_zh.md` 的 collector 格式约定，绝不写入或提出修订。综合与判断留在主 agent 。
3. **每处改动由用户拍板。** 审查发现整理成编号的修订候选。每条以一次一问采纳 / 调整 / 跳过，标出推荐——绝不打包批准，绝不擅自动笔。
4. **就地修订，留下痕迹。** 批准的改动写回原 `<prefix>_<slug>_plan.md`；绝不另存 `_v2` 副本（重复前缀会破坏 status/decomposer/executor 解析的计划树）。每次会话追加一条 `## Revision History`（日期、逐处改动一句话与证据、报告路径）并更新 `updated`；旧版本靠 git 追溯。
5. **守住家族的写入纪律。** 绝不重编号前缀；绝不动 `EXEC_PLAN.md` / `EXEC_LOG.md`（属于 executor）；结构性重构（增删子计划、重画依赖图）转给 `$star-plan-decomposer`；研究问题或方法级转向转给 `$star-plan-coach`。边界见 `references/revision_rules_zh.md`。
6. **连带影响意识。** 一处修订可能让建立在旧文本上的工作失效。在征询任何改动**之前**先呈现反向 `depends_on` 边和派生的 children（报告 §6）；目标的一行目标变了就同步父计划 `## Sub-plans` 里对应那行；`updated` 一更新，过期提示自然在下游的 `$star-flow-status` 浮现。

## 工作流

### Step 0：解析目标计划

1. 用 `PLAN_NAME`（slug / 数字前缀 / 完整文件名）匹配 `metds/plans/*_plan.md`；完整读入解析到的计划。
2. 目标不存在或有歧义时，列出简洁候选（前缀 + slug + 一行状态），只问一个直接问题——优先推荐有执行证据（`exec_runs` 非空）或已知失配的节点。
3. 判定节点类型：**叶子**（审它自己的 run）vs **根/内部**（审总体计划章节 + children 汇总）。这决定 Step 1 的证据集合。

### Step 1：圈定证据

- **叶子**：它当前 run 的目录（`exec_runs` 的最后一项——`EXEC_PLAN.md`、`EXEC_LOG.md`）、§4 的每个交付物路径、§2 写明的输入（`datas/`、`inits/`）与代码模块（`${CODE_NAME}/`，从 `.env` 解析）。
- **根/内部**：children 的 frontmatter（`status`、`exec_status`、`updated`、`depends_on`）、已执行后代的日志（尤其 **方向性信号** 记录与 kill-criteria 命中），加上本节点自己 §1–§6 的假设。
- 明说存在哪些证据。若处处都未执行，声明本次为**纯文档审查**：完成度无从打分；报告的意图 / 偏差 / 候选各节仍然适用，依据是用户知道而计划不知道的信息。

### Step 2：收集证据（只读）

**证据面很小时**——只有一个 run、≤ ~5 个步骤、≤ ~3 个交付物路径，且 §2–§3 没有点名任何代码模块——由主 agent 自己读：`EXEC_PLAN.md`、`EXEC_LOG.md`，外加逐个交付物 stat 一下。这种规模还派三个收集器，正是 conventions §6.1 排除掉的情形。

规模超过这个的：依据 `references/review_spec_zh.md` 中的 collector 格式约定收集：**日志证据**（步骤状态、声称的检查、"Awaiting user"命令、方向性信号）、**工件证据**（每个 §4 交付物：存在 / 大小 / 修改时间 / 低开销 合理性检查），以及在 §2–§3 写明代码时的**代码证据**（承诺模块是否存在，是否与日志声称的修改一致）。默认在本地收集；按核心原则 2 选择性委派。

交叉核对分歧——日志说 `done` 但产物缺失 → 该结论记为 **unverifiable**，不算 met。关键的低开销检查照样复跑；重的一律不跑。

收集器给出的 `suspect` 或 `inconsistent` 是线索，不是结论。它成为编号修订候选之前——每条候选都要拿去问用户，而用户的回答会改写计划文件——主 agent 亲自打开被引用的路径，确认这个发现仍然成立（规约 §6.6）；确认时落在的那个 `path[:line]`，就作为这条候选的证据。站不住的丢掉，或降格成 §5 里一条不引发任何改动的备注。

### Step 3：汇总并写出审查报告

按 `assets/review_report_template_zh.md`（英文计划用 `assets/review_report_template.md`；报告语言跟随计划的 `language`）填写七节：① 目标回顾 ② 实际发生了什么 ③ 完成度记分卡（逐 §3 任务加 §5 done-criterion：`met` / `partial` / `unmet` / `unverifiable`，每条带证据）④ 偏差清单 ⑤ 阻塞与遗留 ⑥ 影响范围图 ⑦ 修订候选，每条标注 **local / structural / strategic**。

写入 `wkdrs/<run>/REVIEW_<YYYY-MM-DD>.md`（真实日期，绝不编造）。计划没有 run 时用 `wkdrs/reviews/<prefix>_<slug>_<YYYY-MM-DD>.md`。聊天里给约 400 字以内的摘要：结论、最重要的偏差、候选清单的一行版。

### Step 4：修订问答（一次一条）

1. 按报告顺序走候选，每条候选问一个直接问题：*照建议采纳* / *采纳但要改* / *跳过*——标出推荐；用户始终可以自由作答。**structural** 或 **strategic** 候选的选项是：*转给 `$star-plan-decomposer` 或 `$star-plan-coach`*（推荐）vs *仍在本文件做范围受限的文本修订*。边走边记流水账（规约 §7.8）——每条候选一落定就写一行，`候选 → 采纳 / 调整 / 跳过 → 文件里改了什么`——若下一条候选与已定的某条相互牵连，用半句话点明承接之处（§7.10）。逐条批准是整套工作流里最长的一串问题；没有这本流水账，用户是在看不见第 1–8 条改动的情况下批准第 9 条。绝不把整张候选清单打包成一个笼统问题。
2. 走完清单后问一次：还有其他要改的吗？用户新增的项同样作为候选（证据记"user directive"）。
3. 一条都未采纳 → 跳到 Step 7——纯审查也是合法结局；写出的报告就是交付物。

### Step 5：写入已批准的修订

对每条被采纳的候选，按文件内顺序：

1. 依据证据和用户的答复起草新的章节文本；给出简洁的改前 → 改后摘要；写入文件。遵循计划的 `language`；中文计划里技术名词保留英文。
2. 让章节 `status` 映射保持诚实：引入 `[TBD]` / `【待定】` 的修改把该节翻回 `in_progress`；经确认的重写保持 `done`。

最后一处改完后：更新 `updated`；若叶子的 §5 done-criterion 或 §3 任务发生实质变化、且其 `exec_status` 为 `done` 或 `blocked`，询问是否重置为 `pending`（`exec_runs` 无论如何都留着历史）；若某条采纳的候选改动了一份 `finalized` 计划的 §1、§2、§3 或 §6——问题、定位、方法或里程碑——就问一次是否清除 `finalized:`（只改 §4/§5 的战术性修订，如收紧一条 kill-criterion，不动它），因为 `star-code-architect` 会读这个字段判断该计划能否驱动搜索，而重新定稿走 `star-plan-coach <slug> <section>`；然后按 `references/revision_rules_zh.md` 追加 `## Revision History` 条目。

### Step 6：一致性检查

- 若计划标题或一行目标变了，同步父计划 `## Sub-plans` 里对应那行——这是目标文件之外唯一允许的编辑。
- 复核 `children:` 条目与 `depends_on` 前缀仍能解析；悬空引用**标记**出来交给 `$star-plan-decomposer`——不要悄悄修复。（编辑目标自己的 `depends_on` 列表可以作为已批准候选进行；跨兄弟重画依赖边不行。）
- 若目标是父节点、且修订触及 children 赖以派生的内容，指明受影响的 children 并建议重新拆解。

### Step 7：汇报与交接

以结果开头，约 400 字以内：证据基础（读了什么、核实了什么）、完成度结论、逐节写入的改动、跳过的候选、连带影响提醒。结尾给出下一步命令：`$star-plan-decomposer <slug>`（结构变了 / children 过期）、`$star-plan-coach <slug>`（总体方向转向）、`$star-plan-executor <叶子>`（重跑修订后的叶子）、`$star-code-reviewer <叶子>`（审计实现代码）、`$star-flow-status`（看全树）。若什么都没改，坦白说明——报告文件仍在。若有写入的修订，提出一次提交提议（见状态与文件规则）。

## 状态与文件规则

- 审查报告放 `wkdrs/`（计划的 run 目录，否则 `wkdrs/reviews/`）；绝不放 `metds/plans/`。
- 只能编辑：目标计划的正文与 frontmatter（`updated`、章节 `status` 映射、`depends_on`、`exec_status`——后两者仅作为用户批准的候选），以及当目标的一行目标变化时，父计划 `## Sub-plans` 的对应行。其余一律只读：`EXEC_PLAN.md` / `EXEC_LOG.md`、兄弟与子计划正文、前缀（绝不重编号）、计划文件本身（绝不删除或分叉）。
- 每次写入都必须追溯到一条被单独批准的候选；`## Revision History` 只追加、不改写。
- Git：有写入修订时，在 Step 7 提出一次提交提议，涵盖目标计划（及一行目标变化时的父计划）——`star-plan-reviser: <slug> — <n> 处修订`（规约 §1）。核心原则 4 的"旧版本存于 git"正依赖这些提交。
- 合法章节 `status`：`pending` / `in_progress` / `done` / `skipped`；合法 `exec_status`：`pending` / `in_progress` / `done` / `blocked` / `skipped` / `abandoned`——与家族一致。把某个叶子置为 `abandoned` 同样是一条修订候选：需要用户明确批准，理由写进本次 Revision History 条目。

## 对话纪律

- 一次只问一个问题，任何写入前都要求明确答复。计划正文与审查报告保持计划 frontmatter 的 `language`。
