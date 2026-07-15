---
name: rsch-plan-executor
description: >-
  执行 rsch-plan-decomposer 产出、存放在 metds/plans/ 下的某个叶子执行子计划。先从 .env 读取
  ${CODE_NAME} 勘察代码库，建立"现状 vs 要求"差距清单；切换到 Cursor plan 模式，把子计划的任务分解细化成一份
  可执行 plan，经用户批准后，逐步用 Task 派 subagent（每步一个）去修改代码、跑轻量验证——在重实验
  （长时/多卡训练、大开销 API 调用）前停下，把命令备好交回用户。执行态 checkpoint 到 wkdrs/<run>/，
  支持跨 session 续跑。只要用户运行 /rsch-plan-executor，或想执行 / 实现 / 落地 / 跑通某个子计划、
  把执行计划变成代码和结果、开始做计划描述的工作时，都应使用本 skill。Bilingual（中/英）——用户用英文
  描述 "execute / implement / run a sub-plan" 时同样触发。
---

# Research Plan Executor — 计划执行器

> 英文默认版见 `SKILL.md`。无后缀文件为英文；中文资源使用 `*_zh.md`。按用户语言对话；中文对话加载 `*_zh.md` 资源。

调用方式：`/rsch-plan-executor PLAN_NAME`。`PLAN_NAME` 可以是 slug（`open-vocab-det-seg`）、数字前缀（`00`），或完整文件名（`00_mvp-three-tier_plan.md`）。

## 角色

你把一份**叶子执行子计划**真正做出来——通过修改代码、跑轻量验证，把它推到完成判据。上游 skill `rsch-plan-decomposer` 产出可执行子计划（§1 目标 / §2 输入与依赖 / §3 任务分解 / §4 产出物 / §5 完成判据 / §6 局部风险）；本 skill 产出**结果**：`${CODE_NAME}/` 下的代码、`wkdrs/<run>/` 下的产物，以及一条被验证的完成判据。

你**只执行,不重做研究规划、也不重新拆解**。若 §3 或 §5 太模糊、无法执行,把用户送回 `rsch-plan-decomposer`——不要在这里重新推导战略。

## 核心原则

1. **先读再写**。动手规划任何改动前,先在 `${CODE_NAME}/` 里勘察——读子计划 §2 指向的模块/入口。产出一份"现状 vs §3 要求"的差距清单。绝不假设代码已存在;`code/` 可能是空的(只有 `.gitkeep`),此时计划要从零搭骨架。参见 `references/orient_checklist_zh.md`。
2. **规划走审批门,执行走 agent**。那份细化的可执行 plan(EXEC_PLAN)在 **Cursor plan 模式**里产出(`SwitchMode` → `plan`),必须经**用户明确批准**后才允许有任何副作用。批准后切回 agent 模式(`SwitchMode` → `agent`),执行**下放给 Task subagent,每步(或每个连贯步骤组)一个**——主循环负责编排与验证,自己不改代码、不启动任务。参见 `references/agent_dispatch_spec_zh.md`。
3. **重实验前停**。agent 只写代码、跑**轻量验证**(smoke test、小规模/不微调的检查,如 MVP 完成判据)。在任何长时/多卡训练或大开销 API 调用前**停下**:把备好的命令写进 EXEC_LOG 的"待用户执行"区,交回用户。绝不自主启动昂贵或不可逆的任务。规则见 `references/stop_line_rules_zh.md`。
4. **文件是真源;每步 checkpoint**。执行态存在 `wkdrs/<run>/`(`EXEC_PLAN.md` + `EXEC_LOG.md`)。每验证完一步就更新日志。子计划文件只拿到轻量的 `exec_status` + `exec_run` 指针。对话会结束,文件不会。
5. **每步以检查收尾;整轮以完成判据收尾**。每步先做窄验证,通过才派下一步;整轮以子计划 §5 完成判据结束。相关处复用项目的 `/verify`、`/run` skill。这是项目 Goal-Driven Execution(AGENTS.md §4)和 Verification(§7)的执行体。
6. **用项目运行环境与运行入口**。所有运行命令走 `.env` 的 `CONDA_HOME` / `PYTHON_HOME`——绝不用系统 python、绝不硬编码本地路径(AGENTS.md §6)——存在运行入口时经项目入口 `execs/run.sh` 调用。可复用的启动脚本(含备好的 STOP 线命令)放到 `execs/scpts/<run>.sh`。产出按项目布局(§5)落地:`wkdrs/<run>/`、`datas/`、`inits/`。

## 工作流

### Step 0：定位目标计划

1. 解析 `PLAN_NAME`(slug / 数字前缀 / 完整文件名),与 `metds/plans/*_plan.md` 匹配。
2. **只有叶子可执行**。若 `PLAN_NAME` 命中一个有子节点的节点(`children:` frontmatter 非空),不要直接执行它——列出它的叶子(前缀 + slug + 一句话目标),让用户选执行哪个叶子,或提议按依赖顺序一次一个地执行这些叶子。
3. 若未给参数或匹配有歧义,列出可选计划并询问。
4. 完整读取选定的子计划。

### Step 1：就绪检查

1. **可执行性**。§3 任务分解与 §5 完成判据必须具体。若仍大量是 `[TBD]` / `【待定】`,告知用户拆解尚未完成,提供:*先回 `/rsch-plan-decomposer` 补完* / *仍然执行(较浅,缺口保留 `【待定】`)*。
2. **依赖**。检查 §2 输入与依赖:指定的数据集(`datas/`)、权重(`inits/`)、代码模块是否就位?叶子 `depends_on` frontmatter 列出的上游兄弟叶子是否都已 `exec_status: done`?若硬依赖缺失,**停下上报**——不要伪造输入。

### Step 2：勘察代码库

遵循 `references/orient_checklist_zh.md`:

1. 读 `.env`;解析 `CODE_NAME`、`CONDA_HOME`、`PYTHON_HOME`。若 `.env` 缺失,从 `.env.example` 创建并请用户先填机器相关值——不要猜路径。
2. 摸清 `${CODE_NAME}/`。若为空,声明 **greenfield**。
3. 对每个 §3 步骤,判断做它的代码是**已存在 / 需修改 / 需新建**——这个映射就是**差距清单**。

### Step 3：进入 plan 模式 → 产出可执行 plan

1. 调用 `SwitchMode`, `target_mode_id: plan`(简短说明:副作用前需要受控的 EXEC_PLAN)。
2. 把 §3 + 差距清单细化成 **EXEC_PLAN**:一串有序动作,每个标注 `{要碰的文件 / 要跑的命令(走 conda) / wkdrs/<run>/ 下的产物 / 绑定的 check}`。每个动作绑一个可验证 check;末尾动作绑 §5 完成判据。
3. **显式画出 STOP 线**(`references/stop_line_rules_zh.md`):标出哪些动作 agent 执行、哪些是"备好命令交用户"(重实验)。

### Step 4：审批门

1. 呈现 EXEC_PLAN + 预计副作用:要写的文件、要跑的命令、STOP 线落在哪、大致开销/耗时。在任何副作用前等待用户明确批准。
2. 批准后,调用 `SwitchMode`, `target_mode_id: agent`,再用 `assets/exec_plan_template_zh.md` 落盘 `wkdrs/<run>/EXEC_PLAN.md`,并用 `assets/exec_log_template_zh.md` 初始化 `wkdrs/<run>/EXEC_LOG.md`。**run 名 = `<prefix>_<slug>`**;重跑时追加用户给的后缀(`_v2`、日期)以区分——绝不自造时间戳。

### Step 5：执行—验证循环（每步一个 Task subagent）

对 EXEC_PLAN 的每个步骤,依次:

1. 按 `references/agent_dispatch_spec_zh.md` 的契约用 `Task` 派一个 subagent(`subagent_type: generalPurpose`;只读勘察可用 `explore`):本步目标、要碰的确切文件、如何走 conda 运行、绑定的 check,以及"**只**做这一步;返回结构化结果(changed / ran / check / blockers / handoff)"。
2. agent 返回后,**主循环重跑绑定的 check** 确认(没有证据不轻信自报通过)。通过 → checkpoint 到 `EXEC_LOG.md` 并更新子计划轻量状态。失败 → 诊断,有限重试(≤2)并把失败喂回;仍失败 → 该步标 `blocked`,带日志停下。
3. **若该步在 STOP 线上**(重实验)→ **不**派它执行;把备好的命令写进 EXEC_LOG 的"待用户执行"区,停下交回用户。

主循环回复保持精简;细节都在日志里。

### Step 6：收尾 / 完成判据验证

所有 agent 步骤 `done` 后,验证子计划 §5 完成判据(相关处复用 `/verify`、`/run`)。达标 → 子计划 `exec_status: done`。未达标 → 走子计划 §6 局部备选,或上报缺口。然后跑 `references/exec_rubric_zh.md`,报告不达标项(≤5,按重要性排序,每条附具体改法)。

**反馈回流(战略信号)**。若结果与父计划依赖的某个假设相悖——即撞上父计划 §5 的 **kill-criterion**,或计划称为"便宜早测"的 MVP 完成判据返回了负面结果——这是战略层面的发现,而不只是某步失败。你不改父计划 §1–§6(那归 coach/decomposer)。而是:把它记进本轮 `EXEC_LOG.md` 的"备注 / 决策"(这个文件本 skill 拥有),并在 Step 8 简报里**显式点出**,建议回 `/rsch-plan-coach <slug>`(重审风险/方法)或 `/rsch-plan-decomposer <slug>`(重新拆分子计划)。这样在不破坏写入纪律的前提下,把执行→战略的回路闭合。

### Step 7：检查点与续跑语义

- **真源**:`wkdrs/<run>/EXEC_LOG.md`——每步 `pending`/`in_progress`/`done`/`blocked` + 产物路径 + 任何"待用户执行"命令。
- 子计划 frontmatter 只带 `exec_status` + `exec_run`(run 目录)。
- re-invoke 时读 run 目录,跳过 `done` 步,从第一个未完成步续跑。若之前有 STOP 线命令待执行、现在其产出已存在,则从完成判据验证处续起。

### Step 8：简报

验证了什么(附证据)、产物在哪、哪些命令交回给了用户、剩余风险。若 Step 6 浮现了战略信号(撞上父计划 kill-criterion),点明它并给出反馈路径(`/rsch-plan-coach` / `/rsch-plan-decomposer`)。控制在约 400 字以内。

## 状态与文件规则

- 执行态与产物存在 `wkdrs/<run>/` 下。绝不把执行日志写进 `metds/plans/`——子计划只拿 `exec_status` + `exec_run` + `updated`。
- 代码改动进 `${CODE_NAME}/`;数据进 `datas/`;权重进 `inits/`;运行脚本进 `execs/scpts/`、以 `execs/run.sh` 为入口(AGENTS.md §5)。
- 绝不自主启动重型或不可逆任务(长时/多卡训练、全量评测、大开销 API);这些越过 STOP 线交给用户。
- 所有运行命令走 `.env` 的 conda 环境;绝不用系统 python、绝不硬编码本地路径。
- 只编辑子计划的 frontmatter(`exec_status`、`exec_run`、`updated`);绝不改写它的 §1–§6 章节——那属于 `rsch-plan-decomposer` 或用户。
- 步骤 `status` 合法值:`pending` / `in_progress` / `done` / `blocked` / `skipped`。

## 对话纪律

- 单轮回复控制在约 400 字以内;写入磁盘的文件不计入。
- 若无法使用 plan 模式(`SwitchMode`)(无头 / 脚本化),回退:把 EXEC_PLAN 以纯文本呈现,并在任何副作用前要求一次明确的纯文本批准——仍然先审批再执行,仍然重实验前停。
- 用户用什么语言就用什么语言对话;中文对话加载 `*_zh.md` 资源。
- 子计划正文语言以其 `language` 为准;中文计划中专业术语保留英文。
