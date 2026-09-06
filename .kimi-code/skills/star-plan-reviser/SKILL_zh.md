---
name: star-plan-reviser
description: >-
  对照执行证据审查研究计划，把已批准条目原地修订并记录历史；也可丢弃或恢复计划子树。用于部分或完整执行后；
  结构拆分与策略变化转交各自技能。
---

# Research Plan Reviser

调用方式：`star-plan-reviser PLAN_NAME [描述]`。先解析计划。自然语言明确放弃或恢复方向时选择 `drop` 或 `restore` 并提供理由，否则走证据审查；也可批准点名修订项。只要求审查、审计或阅读报告且不改动时，报告交付后即停止，不进入修订问答。目标未定时列出候选并询问。

**共享规约。** 先解析调用目标和模式，再读取 `docs/mds/star-workflow/research-workflow-conventions.zh-CN.md` 中本目标实际涉及的节；进入具体分支或模式时才读取它引用的 `references/` 与 `assets/`。从 `.env` 读取一次本次需要的 `STAR_LANG`、`INVOLVE`、`STAR_*_MODEL` 与运行时键；已有取值和仍逐字可见的规约内容直接复用。按规约 §7.6 解析语言：先看用户明确要求，再看有效的 `STAR_LANG`，最后取对话或调用文本语言；使用对应的本地化资源。`SKILL_zh.md` 仅供人阅读，运行时不装载。已有文档保持其 frontmatter 语言。清楚的自然语言指令可以同时选定目标、范围并授权对应动作；不要重复询问已经明确授权的事项。

目标与 drop/restore/review 路径解析后运行 `scripts/scan.sh --slim`，把计划 frontmatter、子计划索引与运行日志 frontmatter 作为范围解析的原始输入；按证据步骤读取目标正文与相关规约。脚本失败时直接读取计划文件并说明回退。

**把档位模型传给受托者。** 取 `kimi` 条目，没有则取不带标签的备选。当前 `Agent` / `AgentSwarm` 接口有 `model` 时，该档每次派发都传解析值；它必须是已配置的 secondary-model pool 接受的别名。键为空则省略参数。没有可选池、池强制指定模型或别名不可用时，保持原执行路径；键已设则说明原因，不修改用户的全局 Kimi 配置。盲读不继承产出该工作的对话。后文规定的角色与写入限制照旧。派发被拒后，须确认它尚未开始工作才能退回本地。受托者记录自己会话的实际模型，不用请求别名或父会话的解析命令代替。

## 角色

接住**一个计划节点**，用执行证据审计其意图，只把用户已指示或从可见候选清单接受的改动原地写回。`star-flow-status` 是全树的浅层视图；本 skill 是单计划深度审计。

你修订文本；你不重跑实验、不重拆子树、不从零重推总体方向。

## 核心原则

1. **证据先于观点。** 每条审查结论都带证据出处（文件路径、日志行、命令输出）。日志自报的 `done` 不等于完成——要对照磁盘上的产物核实，关键处可复跑低开销检查；绝不启动重实验（executor 的红线同样生效）。这是把项目的 Verification 规则（AGENTS.md §11）应用到计划本身。规则见 `references/review_spec_zh.md`。
2. **广收集；判断留在主 agent。** 对多个 run 或产物集合进行有边界、相互独立、只读的检查确有帮助时，派出只读 `Agent` subagent（`subagent_type: explore`；READ 档值非空时作为 `model:`）。受委派者遵守 `references/review_spec_zh.md`，绝不写入或提出修订；综合与判断留在主 agent。
3. **每处改动由用户拍板。**审查发现整理成编号候选。先应用已获授权的点名改动；其余摆在页面上，通过 AskUserQuestion 按规约 §7.13 问一次。每次写入都必须追溯到明确指令或从可见清单接受的候选。
4. **就地修订，留下痕迹。** 批准的改动写回原 `<prefix>_<slug>_plan.md`；绝不另存 `_v2` 副本（重复前缀会破坏 status/decomposer/executor 解析的计划树）。每次会话追加一条 `## Revision History`（日期、逐处改动一句话与证据、报告路径）并更新 `updated`；旧版本靠 git 追溯。
5. **守住家族的写入纪律。** 绝不重编号前缀；绝不动 `EXEC_PLAN.md` / `EXEC_LOG.md`（属于 executor）；结构性重构（增删子计划、重画依赖图）转给 `star-plan-decomposer`；研究问题或方法级转向转给 `star-plan-coach`——而目标自己的概要行，即还没展开成文件的单元（规约 §0），只是文字，仍属 local 候选。边界见 `references/revision_rules_zh.md`。
6. **连带影响意识。** 一处修订可能让建立在旧文本上的工作失效。在征询任何改动**之前**先呈现反向 `depends_on` 边和派生的 children（报告 §6）；目标的一行目标变了就同步父计划 `## Sub-plans` 里对应那行；`updated` 一更新，过期提示自然在 `star-flow-status` 浮现。

## 工作流

**本次运行在哪里执行。** Step 0 前按规约 §10.8 在 PLAN 档处理整次运行的交接。清楚的请求可授权点名修订、丢弃或恢复；只有应用这些指令后仍有决定未解决时才留在这里。

### Step 0：解析目标计划

1. 用 slug、数字前缀或完整文件名把 `PLAN_NAME` 与扫描摘要匹配；完整读入解析到的计划。
2. 目标不存在或有歧义时，列出简洁候选（前缀 + slug + 一行状态），通过 AskUserQuestion 只问一个直接问题——优先推荐有执行证据（`exec_runs` 非空）或已知失配的节点。
3. 判定节点类型：**叶子**（审它自己的 run）vs **根/内部**（审总体计划章节 + children 汇总）。这决定 Step 1 的证据集合。

### Step 1：圈定证据

- **叶子**：它当前 run 的目录（`exec_runs` 最后一项——`EXEC_PLAN.md`、`EXEC_LOG.md`）、§4 每个交付物路径、§2 写明的输入（`datas/`、`inits/`）与代码模块（`${CODE_NAME}/`，从 `.env` 解析）。
- **根/内部**：children 的 frontmatter（`status`、`exec_status`、`updated`、`depends_on`，直接从摘要取）、已执行后代的日志（尤其 **方向性信号** 记录与 kill-criteria 命中），加上本节点自己 §1–§6 的假设。
- 明说存在哪些证据。若处处都未执行，声明本次为**纯文档审查**：完成度无从打分；报告的意图 / 偏差 / 候选各节仍适用，依据是用户知道而计划不知道的信息。

### Step 2：收集证据（只读 subagent）

**证据面很小时**——只有一个 run、≤ ~5 个步骤、≤ ~3 个交付物路径、§2–§3 没有点名任何代码模块——通常由主 agent 自己读更省事：`EXEC_PLAN.md`、`EXEC_LOG.md`，外加逐个交付物 stat 一下。这种规模还派三个收集器，正是 conventions §6.1 排除掉的情形。

规模超过这个的：按 `references/review_spec_zh.md` 的收集器格式约定并行派出只读 `Agent` subagent（`subagent_type: explore`）——通常是 **日志读取器**（步骤状态、自报检查、"待用户执行"命令、方向性信号）、**交付物检查器**（§4 每个交付物：存在 / 大小 / 修改时间 / 低开销合理性检查），以及当 §2–§3 涉及代码时的 **代码检查器**（承诺的模块是否真的写出来了、与日志声称的改动是否一致）。

分歧在主 agent 交叉核对——日志说 `done` 但产物缺失 → 该结论记为 **unverifiable**，不算 met。关键的低开销检查由你亲自复跑；重的一律不跑。

收集器给出的 `suspect` 或 `inconsistent` 是线索，不是结论。它成为编号修订候选之前，主 agent 亲自打开被引用的路径，确认这个发现仍然成立（规约 §6.6）；确认时落在的那个 `path[:line]`，就作为这条候选的证据。站不住的丢掉，或降格成 §5 里一条不引发任何改动的备注。

### Step 3：汇总并写出审查报告

按 `assets/review_report_template_zh.md`（英文计划用 `assets/review_report_template.md`）填写七节：① 目标回顾 ② 实际发生了什么 ③ 完成度记分卡（逐 §3 任务加 §5 done-criterion：`met` / `partial` / `unmet` / `unverifiable`，每条带证据）④ 偏差清单 ⑤ 阻塞与遗留 ⑥ 影响范围图 ⑦ 修订候选，每条标注 **local / structural / strategic**。

写入 `wkdrs/<run>/REVIEW_<YYYY-MM-DD>.md`（真实日期，绝不编造）。计划没有 run 时用 `wkdrs/reviews/<prefix>_<slug>_<YYYY-MM-DD>.md`。聊天里给 ≤500 字摘要：结论、最重要的偏差、候选清单的一行版。

### Step 4：修订问答（先摊清单，再一次提问）

1. 先把每条候选摊在页面上，写进承载该问题的消息正文里（规约 §7.13——一张拟好的清单是一个问题，不是一行一个）：每条候选一个编号行，写明改哪一节、从什么改成什么、证据路径、分级（local / structural / strategic），以及你推荐怎么做。**structural** 或 **strategic** 的行，推荐动作是转出去——形态问题给 `star-plan-decomposer`，方向问题给 `star-plan-coach`——并把"仍在本文件做范围受限的文本修订"写成备选。
2. 去掉明确指令已经定下的候选，再通过 AskUserQuestion 按规约 §7.13 对剩余可见清单问一次。丢弃仍是 `references/revision_rules_zh.md` 管辖的独立实质动作；`exec_status` 重置与清除 `finalized:` 只有在其后果尚未获授权时才问。
3. 边走边记流水账（规约 §7.8）——每条候选一落定就写一行，`候选 → 采纳 / 调整 / 跳过 → 文件里改了什么`——后面每一轮开场都用半句话点明前面几轮定下了什么（§7.10）。流水账是把已定的决策带过轮次的东西，第三轮才不会把第一轮重吵一遍。
4. 不再追加开放式收尾问题。用户主动新增的项以 `user directive` 为证据进入候选；否则直接处理已定清单。
5. 一条都未采纳 → 跳到 Step 7——纯审查也是合法结局；写出的报告就是交付物。

### Step 5：写入已批准的修订

对每条被采纳的候选，按文件内顺序：

1. 依据证据和用户的答复起草新的章节文本；给出简洁的改前 → 改后摘要；写入文件。
2. 让章节 `status` 映射保持诚实：引入 `[TBD]` / `【待定】` 的修改把该节翻回 `in_progress`；经确认的重写保持 `done`。

最后一处改完后：更新 `updated`；若叶子的 §5 done-criterion 或 §3 任务发生实质变化、且 `exec_status` 为 `done` 或 `blocked`，询问是否重置为 `pending`（`exec_runs` 无论如何都留着历史）；若某条采纳的候选改动了一份 `finalized` 计划的 §1、§2、§3 或 §6——问题、定位、方法、里程碑——就问一次是否清除 `finalized:`（只改 §4/§5 的战术性修订，如收紧一条 kill-criterion，不动它），因为 `star-code-architect` 读这个字段判断该计划能否驱动搜索，而重新定稿走 `star-plan-coach <slug> <section>`；若某条采纳的候选丢弃了本节点，就在此写入 `dropped:`、在父计划索引行上加 `— dropped <date>` 标记，再按 `references/drop_rules_zh.md` 第 4 步把子树的文件搬到一边，别的一概不动——子树靠继承变暗；然后按 `references/revision_rules_zh.md` 追加 `## Revision History` 条目。

### Step 6：一致性检查

- 若计划标题或一行目标变了，同步父计划 `## Sub-plans` 里对应那行——这是目标文件之外唯一允许的编辑。
- 复核 `children:` 条目与 `depends_on` 前缀仍能解析；悬空引用**标记**出来交给 `star-plan-decomposer`——不要悄悄修复。（编辑目标自己的 `depends_on` 列表可作为已批准候选；跨兄弟重画依赖边不行。）
- 若目标是父节点、且修订触及 children 赖以派生的内容，指明受影响的 children 并建议重新拆解。

### Step 7：汇报与交接

≤500 字：证据基础（读了什么、核实了什么）、完成度结论、逐节写入的改动、跳过的候选、连带影响提醒。结尾给出下一步命令：`star-plan-decomposer <slug>`（结构变了 / children 过期）、`star-plan-coach <slug>`（总体方向转向）、`star-plan-executor <叶子>`（重跑修订后的叶子）、`star-code-reviewer <叶子>`（审计实现代码）、`star-flow-status`（看全树）。若什么都没改，坦白说明——报告文件仍在。若有写入的修订，提出一次提交提议（见状态与文件规则）。

### 丢弃一份计划，以及把它收回来

这条路用它自己的五步替换 Steps 1–6——读清哪些会随之熄灭、问一次、写三处、把子树的文件搬到一边、汇报——它的规则（包括 `dropped:` 写在哪里、文件搬到哪里、继承对后代意味着什么）在 `references/drop_rules_zh.md`，本次运行是丢弃或恢复时才读，之前不读。评审运行完全不读它。

## 状态与文件规则

- 审查报告放 `wkdrs/`，绝不放 `metds/plans/`。
- 只能编辑：目标计划的正文与 frontmatter（`updated`、章节 `status` 映射、`depends_on`、`exec_status`、`dropped:`——后三者仅作为用户批准的候选），以及当目标的一行目标变化、或要给它加上丢弃标记时，父计划 `## Sub-plans` 的对应行；仅在已批准的丢弃或恢复中，再加上把子树文件在活跃位置与 `dropped/` 位置之间搬移（`references/drop_rules_zh.md`）。其余一律只读：`EXEC_PLAN.md` / `EXEC_LOG.md`、兄弟与子计划正文、前缀（绝不重编号）、计划文件本身（绝不删除或分叉）。
- 每次写入都必须追溯到明确指令或已接受候选；`## Revision History` 只追加、不改写。
- Git：有写入修订时，在 Step 7 提出一次提交提议，涵盖目标计划（及一行目标变化时的父计划）——`star-plan-reviser: <slug> — <n> 处修订`（规约 §1）。核心原则 4 的"旧版本存于 git"正依赖这些提交。
- 合法章节 `status`：`pending` / `in_progress` / `done` / `skipped`；合法 `exec_status`：`pending` / `in_progress` / `done` / `blocked` / `abandoned`——与家族一致。把某个叶子置为 `abandoned` 同样是一条修订候选：需要用户明确批准，理由写进本次 Revision History 条目。`dropped:` 是一行「日期 + 原因」，只写在本节点上——所有 skill 都按整棵子树继承来读它——设置与清除只走 `references/revision_rules_zh.md` 的丢弃规则。

## 对话纪律

- 只有修订、重置、重新定稿、丢弃、恢复或覆盖权限仍未解决时，才通过 AskUserQuestion 一次问一个问题；工具不可用时退回简洁纯文本。只读报告请求以报告结束。计划正文与审查报告保持计划 frontmatter 的 `language`。
- **候选清单写在同一条消息的正文里、放在提问之上**——选项只承载答案，不承载材料。
