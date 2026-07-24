---
name: star-plan-executor
description: >-
  执行 star-plan-decomposer 产出、存放在 metds/plans/ 下的某个叶子执行子计划。先从 .env 读取
  ${CODE_NAME} 勘察代码库，建立"现状 vs 要求"差距清单；进入 plan 模式，把子计划的任务分解细化成一份
  可执行 plan，经 ExitPlanMode 审批后，逐步派 subagent（每步一个）去修改代码、跑轻量验证——在重实验
  （长时/多卡训练、大开销 API 调用）前停下，把命令备好交回用户。执行过程的中间工作文件放到
  tasks/<plan-name>/，持久执行状态及生成的 run 产物 checkpoint 到 wkdrs/<run>/，支持跨 session 续跑。经用户确认的偏差、以及执行敲定的值会同步写回子计划并留下 Revision History 记录，让计划文件与实际
  执行保持一致。只要用户运行 /star-plan-executor，或想执行 / 实现 / 落地 / 跑通某个子计划、
  把执行计划变成代码和结果、开始做计划描述的工作时，都应使用本 skill。Bilingual（中/英）——用户用英文
  描述 "execute / implement / run a sub-plan" 时同样触发。
---

# Research Plan Executor — 计划执行器

> 英文默认版见 `SKILL.md`。无后缀文件为英文；中文资源使用 `*_zh.md`。按用户语言对话；中文对话加载 `*_zh.md` 资源。

调用方式：`/star-plan-executor PLAN_NAME`。`PLAN_NAME` 可以是 slug（`open-vocab-det-seg`）、数字前缀（`00`），或完整文件名（`00_mvp-three-tier_plan.md`）。可选的 `involve=low|medium|high` 记号可与 `PLAN_NAME` 一同给出（如 `… involve=low`）：它设定本次运行的参与度档位（规约 §7.7），不属于 `PLAN_NAME`，解析前先剥离。

**通用规约。** 动手前先读 `docs/mds/star-workflow/research-workflow-conventions.zh-CN.md`（英文：`research-workflow-conventions.md`）：§1 git、§2 STOP 线、§3 `.env` 运行时、§4 真实日期、§5 计划名解析、§6 委派、§7 对话纪律、§8 产物注册表、§9 项目布局。那是所有 STAR skill 共享的基线；本文件只写本 skill 特有的部分，并在更严处生效。

## 角色

你把一份**叶子执行子计划**真正做出来——通过修改代码、跑轻量验证，把它推到完成判据。上游 skill `star-plan-decomposer` 产出可执行子计划（§1 目标 / §2 输入与依赖 / §3 任务分解 / §4 产出物 / §5 完成判据 / §6 局部风险）；本 skill 产出**结果**：`${CODE_NAME}/` 下的代码、`tasks/<plan-name>/` 下的中间工作文件、`wkdrs/<run>/` 下的生成产物与持久执行记录，以及一条被验证的完成判据。`<plan-name>` 取选定计划文件名去掉 `_plan.md` 后的部分。

你**只执行,不重做研究规划、也不重新拆解**。若 §3 或 §5 太模糊、无法执行,把用户送回 `star-plan-decomposer`——不要在这里重新推导战略。

## 核心原则

1. **先读再写**。动手规划任何改动前,先在 `${CODE_NAME}/` 里勘察——读子计划 §2 指向的模块/入口。产出一份"现状 vs §3 要求"的差距清单。绝不假设代码已存在;`code/` 可能是空的(只有 `.gitkeep`),此时计划要从零搭骨架——更好的做法是先用 `/star-code-architect` 奠基参考代码库。参见 `references/orient_checklist_zh.md`。
2. **规划走审批门,执行走 agent**。那份细化的可执行 plan(EXEC_PLAN)在 **plan 模式**里产出,经 **`ExitPlanMode`** 审批后才允许有任何副作用。执行**下放给 subagent,每步(或每个连贯步骤组)一个**——主循环负责编排与验证,自己不改代码、不启动任务。参见 `references/agent_dispatch_spec_zh.md`。
3. **重实验前停**。agent 只写代码、跑**轻量验证**(smoke test、小规模/不微调的检查,如 MVP 完成判据)。在任何长时/多卡训练或大开销 API 调用前**停下**:把备好的命令写进 EXEC_LOG 的"待用户执行"区,交回用户。绝不自主启动昂贵或不可逆的任务。规则见 `references/stop_line_rules_zh.md`。
4. **文件是真源;每步 checkpoint;子计划保持真实**。执行态存在 `wkdrs/<run>/`(`EXEC_PLAN.md` + `EXEC_LOG.md`),中间工作文件存在 `tasks/<plan-name>/`。每验证完一步就更新日志。子计划文件拿到轻量的 `exec_status` + `exec_runs` 指针——当执行被证实偏离它、或敲定了它留白而某份方法文档会引用的值时,还会经**用户确认后同步回写**受影响的 §2–§5 内容并追加 `## Revision History` 条目(`references/plan_sync_rules_zh.md`),让用户日后重读计划时看到的就是实际执行的内容。对话会结束,文件不会。
5. **每步以检查收尾;整轮以完成判据收尾**。每步先做窄验证,通过才派下一步;整轮以子计划 §5 完成判据结束。相关处复用项目的 `/verify`、`/run` skill。这是项目 Goal-Driven Execution(CLAUDE.md §4)和 Verification(§7)的执行体。
6. **用项目运行环境与运行入口**。所有运行命令走 `.env` 的 `CONDA_HOME` / `PYTHON_HOME`——绝不用系统 python、绝不硬编码本地路径(CLAUDE.md §6)——存在运行入口时经项目入口 `execs/run.sh` 调用。为计划执行过程的中间工作文件新建 `tasks/<plan-name>/`;可复用的启动脚本(含备好的 STOP 线命令)放到 `execs/scpts/<run>.sh`;生成输出及持久执行记录、数据、权重分别落到 `wkdrs/<run>/`、`datas/`、`inits/`。不要把生成的 run 产物放在 `tasks/`。

## 工作流

### Step 0：定位目标计划

1. 解析 `PLAN_NAME`(slug / 数字前缀 / 完整文件名),与 `metds/plans/*_plan.md` 匹配。
2. **只有叶子可执行**。若 `PLAN_NAME` 命中一个有子节点的节点(`children:` frontmatter 非空),不要直接执行它——列出它的叶子(前缀 + slug + 一句话目标),用 AskUserQuestion 让用户选执行哪个叶子(推荐依赖顺序中第一个就绪的叶子),或提议按依赖顺序一次一个地执行这些叶子。
3. 若未给参数或匹配有歧义,列出可选计划并询问。
4. 完整读取选定的子计划。

### Step 1：就绪检查

1. **可执行性**。§3 任务分解与 §5 完成判据必须具体。若仍大量是 `[TBD]` / `【待定】`,告知用户拆解尚未完成,用 AskUserQuestion 提供:*先回 `/star-plan-decomposer` 补完*(推荐) / *仍然执行(较浅,缺口保留 `【待定】`)*。
2. **依赖**。检查 §2 输入与依赖:指定的数据集(`datas/`)、权重(`inits/`)、代码模块是否就位?叶子 `depends_on` frontmatter 列出的上游兄弟叶子是否都已 `exec_status: done`?若硬依赖缺失,**停下上报**——缺失的数据集或权重是拆解上的缺口,不是绕开就行的阻塞:点名本该负责它的数据就绪叶子,或路由到 `star-plan-decomposer <父计划>` 去补一个。不要伪造输入。

### Step 2：勘察代码库

遵循 `references/orient_checklist_zh.md`:

1. 读 `.env`,解析 `CODE_NAME`、`CONDA_HOME`、`PYTHON_HOME`(规约 §3)。若这些路径指向的环境缺失或无法运行 python,建议先用 `/star-env-builder` 构建后再执行;run 需要而环境里没有的包,走 `/star-env-builder add <包名>`——本 skill 自己不装任何东西。
2. 摸清 `${CODE_NAME}/`。若为空,声明 **greenfield**。
3. 对每个 §3 步骤,判断做它的代码是**已存在 / 需修改 / 需新建**——这个映射就是**差距清单**。

### Step 3：进入 plan 模式 → 产出可执行 plan

1. `EnterPlanMode`。
2. 把 §3 + 差距清单细化成 **EXEC_PLAN**:一串有序动作,每个标注 `{要碰的文件 / 要跑的命令(走 conda) / wkdrs/<run>/ 下的产物 / 绑定的 check}`。每个动作绑一个可验证 check;末尾动作绑 §5 完成判据。
3. **显式画出 STOP 线**(`references/stop_line_rules_zh.md`):标出哪些动作 agent 执行、哪些是"备好命令交用户"(重实验)。
4. **收集实质性偏差**:把 EXEC_PLAN 相对子计划 §2–§5 的实质性出入,以 delta 形式(ADDED / MODIFIED / REMOVED / ENRICHED——`references/plan_sync_rules_zh.md`)记入 EXEC_PLAN 的"与子计划的偏差"表。在子计划自身粒度上的矛盾算偏差;"更具体"不算——除非那是计划未写明、而某份方法文档会引用的值,那要记为一条 ENRICHED 行并点名该章节。

### Step 4：审批门（`ExitPlanMode`）

1. `ExitPlanMode` 呈现 EXEC_PLAN + 预计副作用:要写的文件、要跑的命令、STOP 线落在哪、大致开销/耗时——以及偏差表,并注明"批准本计划即同时把这些偏差同步回子计划"。在同一道门里一并问:是否把每个通过验证的步骤做成 git checkpoint 提交(推荐),并点名任何已带未提交改动的路径——那些绝不暂存。
2. 批准后,把选定计划文件名去掉 `_plan.md` 得到 `<plan-name>`,为中间工作文件新建 `tasks/<plan-name>/`;用 `assets/exec_plan_template_zh.md` 落盘 `wkdrs/<run>/EXEC_PLAN.md`,并用 `assets/exec_log_template_zh.md` 初始化 `wkdrs/<run>/EXEC_LOG.md`。**run 名 = `<prefix>_<slug>`**;重跑时追加用户给的后缀(`_v2`、日期)以区分——绝不自造时间戳。
3. **把偏差同步回子计划**。若偏差表非空,刚获得的批准已覆盖此事:原地更新受影响的 §2–§5 段落,追加一条 `## Revision History` 条目,更新 `updated`,并给每行标记 `synced`(`references/plan_sync_rules_zh.md`)。子计划从此与即将执行的内容一致。

### Step 5：执行—验证循环（每步一个 agent）

对 EXEC_PLAN 的每个步骤,依次:

1. 按 `references/agent_dispatch_spec_zh.md` 的契约派一个 subagent:本步目标、要碰的确切文件、如何走 conda 运行、绑定的 check,以及"**只**做这一步;返回结构化结果(changed / ran / check / blockers / handoff)"。
2. agent 返回后,**主循环重跑绑定的 check** 确认(没有证据不轻信自报通过)。通过 → checkpoint 到 `EXEC_LOG.md`、更新子计划轻量状态,并在门批准了 checkpoint 时提交本步触碰的文件。失败 → 诊断,有限重试(≤2)并把失败喂回;仍失败 → 该步标 `blocked`,带日志停下。
3. **若该步在 STOP 线上**(重实验)→ **不**派它执行;把备好的命令写进 EXEC_LOG 的"待用户执行"区,停下交回用户。
4. 若重试或 blocker 导致做法在子计划粒度上变了(步骤增/删/替换、产出路径或完成判据移位),在 EXEC_LOG 的"待同步修正"区记一行 delta 后继续——这些留到 Step 6 同步,不在执行中途处理。

主循环回复保持精简;细节都在日志里。

### Step 6：收尾 / 完成判据验证

所有 agent 步骤 `done` 后,验证子计划 §5 完成判据(相关处复用 `/verify`、`/run`)。达标 → 子计划 `exec_status: done`,随后提供一次删除本计划 `tasks/<plan-name>/` **草稿区**的机会——还值得留的先提升到 `wkdrs/<run>/`,并把选择记进 `EXEC_LOG.md`;保留也是正当答案。**该提议绝不覆盖本计划自有的工具脚本**(规约 §9):把它们按名字列为保留项,只有用户自己点名才删。未达标 → 走子计划 §6 局部备选,或上报缺口。然后跑 `references/exec_rubric_zh.md`,报告不达标项(≤5,按重要性排序,每条附具体改法)。

**修正同步(战术信号)**。若 EXEC_LOG 的"待同步修正"非空,用**一次** AskUserQuestion 呈现整批(*全部同步 / 逐条挑 / 不同步*,标出你推荐的一项),确认的行按 `references/plan_sync_rules_zh.md` 写回(原地更新 §2–§5 + 追加 `## Revision History` 条目 + 更新 `updated`,再把行勾掉)。只限战术层:凡触及 §1/§6、父计划或 kill-criterion 的,都是战略信号——走下面的反馈回流,绝不同步。

**反馈回流(战略信号)**。若结果与父计划依赖的某个假设相悖——即撞上根计划 §5 的 **kill-criterion**,或计划称为"便宜早测"的 MVP 完成判据返回了负面结果——这是战略层面的发现,而不只是某步失败。你不改父计划 §1–§6(那归 coach/decomposer)。而是:把它记进本轮 `EXEC_LOG.md` 的"备注 / 决策"(这个文件本 skill 拥有),并在 Step 8 简报里**显式点出**,建议回 `/star-plan-reviser <slug>`(以证据审计并在逐条批准下修订计划)、`/star-plan-coach <slug>`(重审风险/方法)或 `/star-plan-decomposer <slug>`(重新拆分子计划)。这样在不破坏写入纪律的前提下,把执行→战略的回路闭合。

### Step 7：检查点与续跑语义

- **真源**:`wkdrs/<run>/EXEC_LOG.md`——每步 `pending`/`in_progress`/`done`/`blocked` + 产物路径 + 任何"待用户执行"命令。
- 子计划 frontmatter 只带 `exec_status` + `exec_runs`(只追加,最新的在最后;最后一项是当前 run)。
- re-invoke 时读 run 目录,跳过 `done` 步,从第一个未完成步续跑。若之前有 STOP 线命令待执行、现在其产出已存在,则从完成判据验证处续起。
- 同步回写是幂等的:标了 `synced` 的行(EXEC_PLAN)和勾掉的行("待同步修正")绝不二次应用;未同步的待定行在 Step 6 再次提出。

### Step 8：简报

验证了什么(附证据)、产物在哪、哪些命令交回给了用户、哪些修正同步进了子计划、剩余风险。若 Step 6 浮现了战略信号(撞上根计划 kill-criterion),点明它并给出反馈路径(`/star-plan-reviser` / `/star-plan-coach` / `/star-plan-decomposer`)。run 完整跑完后,建议先用 `/star-code-reviewer <叶子>` 对照规范与子计划审一遍实现,再修订计划或继续推进。若有命令在 STOP 线交回给了用户,补一句:等它们的输出就位后,`/star-expt-analyst <叶子>` 会对照 §5 完成判据给结果打分并说明它意味着什么。控制在约 400 字以内。

## 状态与文件规则

- 中间工作文件放在 `tasks/<plan-name>/`,执行态及生成产物放在 `wkdrs/<run>/`。绝不把执行日志写进 `metds/plans/`——子计划只拿 `exec_status` + `exec_runs` + `updated`。`tasks/<plan-name>/` 存放本计划自有的工具脚本(持久)与可弃置草稿,草稿的生命周期归本 skill:收尾且 §5 达标时提供一次删除草稿的机会,绝不删脚本(规约 §9)。生成产物与持久证据绝不放在那里;绝不擅自删除,也绝不碰其他计划的 `tasks/` 目录。
- 代码改动进 `${CODE_NAME}/`;数据进 `datas/`;权重进 `inits/`;运行脚本进 `execs/scpts/`、以 `execs/run.sh` 为入口(CLAUDE.md §5)。
- 绝不自主启动重型或不可逆任务(长时/多卡训练、全量评测、大开销 API);这些越过 STOP 线交给用户。
- 所有运行命令走 `.env` 的 conda 环境;绝不用系统 python、绝不硬编码本地路径。
- 子计划的 frontmatter(`exec_status`、`exec_runs`、`updated`)可自由编辑;它的 §2–§5 **只能**经用户确认的同步回写协议修改(`references/plan_sync_rules_zh.md`)——始终原地更新、始终配一条 `## Revision History` 条目。绝不改写 §1 或 §6、绝不碰父计划——目标级/战略级偏差走 `star-plan-coach` / `star-plan-decomposer`(反馈回流)。
- Git:每个通过验证的步骤一次提交,只 stage 该步触碰的文件,且仅在审批门覆盖时提交;run 开始时就已带未提交改动的路径在门上点名(规约 §1)。
- 步骤 `status` 合法值:`pending` / `in_progress` / `done` / `blocked` / `skipped`。

## 对话纪律

- 若当前环境无法使用 AskUserQuestion 或 plan 模式(无头 / 脚本化),回退:把 EXEC_PLAN 以纯文本呈现,并在任何副作用前要求一次明确的纯文本批准——仍然先审批再执行,仍然重实验前停,任何同步回写子计划前仍需纯文本确认。
- 用户用什么语言就用什么语言对话;中文对话加载 `*_zh.md` 资源。
- 子计划正文语言以其 `language` 为准;中文计划中专业术语保留英文。
- 参与度档位(规约 §7.7)。本 skill 中不受档位影响:ExitPlanMode 审批门(Step 4,含按步提交的确认)、STOP 线(Step 5)、修正同步(Step 6,它回写计划 §2–§5)、删草稿的机会(它把关一次删除)。`low` 档不再问:Step 0 的选叶子(按依赖序取第一个就绪的叶子;无参数或有歧义的调用仍要问,规约 §5.2)、Step 1 的就绪回退(取推荐项:送回 decomposer 并停下)。`high` 档:Step 5 每步派发 subagent 前先确认。生效档位及其来源在 `EXEC_LOG.md` 里记一次。
