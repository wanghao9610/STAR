---
name: star-plan-executor
description: >-
  对项目代码执行 metds/plans/ 中的一份 leaf 研究子计划。使用 .env 定位代码库，把
  子计划转成具体、带检查的执行计划，以外科手术式修改实现，运行轻量验证，把中间工作
  文件保存在计划专属 tasks 目录，在 run 专属 wkdrs 目录记录进度 checkpoint，并在
  长时间或高成本实验前停止，把准确命令交给用户。将用户确认的偏差和执行中确定的值
  回同步到子计划，并留下 Revision History，使计划文件忠实反映实际执行。当用户调用
  $star-plan-executor，或要求 Codex 执行、实现、落实或运行某份研究子计划时使用。
  支持跨会话恢复和中英文双语工作。
---

# Research Plan Executor

> 英文默认版见 `SKILL.md`。无后缀文件为英文；中文资源使用 `*_zh.md`。按用户语言对话；中文对话加载 `*_zh.md` 资源。

调用方式：`$star-plan-executor PLAN_NAME`，其中 `PLAN_NAME` 是 slug（`open-vocab-det-seg`）、数字前缀（`00`）或文件名（`00_mvp-three-tier_plan.md`）。

**通用规约。** 动手前先读 `docs/mds/star-workflow/research-workflow-conventions.zh-CN.md`（英文：`research-workflow-conventions.md`）：§1 git、§2 STOP 线、§3 `.env` 运行时、§4 真实日期、§5 计划名解析、§6 委派、§7 对话纪律、§8 产物注册表、§9 项目布局。那是所有 STAR skill 共享的基线；本文件只写本 skill 特有的部分，并在更严处生效。

## 角色

通过修改代码和运行轻量验证，推动一份 **leaf 执行子计划**达到完成判据。上游 `$star-plan-decomposer` 拥有子计划的策略和任务拆解。本 skill 拥有实现结果：`${CODE_NAME}/` 下的代码、`tasks/<plan-name>/` 下的中间工作文件，以及 `wkdrs/<run>/` 下的生成工件与验证证据。从所选计划文件名去掉 `_plan.md` 得到 `<plan-name>`（例如 `00_demo_plan.md` → `tasks/00_demo/`）。

只执行；不要重新制定策略或静默重新分解。若 §3 或 §5 模糊到无法执行，报告具体缺口并转回 `$star-plan-decomposer`。

## 核心原则

1. **先读后写。** 规划修改前，检查 `.env`、点名输入、相关代码和实际运行界面。列出当前状态与所需状态的差距。遵循 `references/orient_checklist_zh.md`。
2. **让计划可见，然后在范围内推进。** 把子计划转成 `EXEC_PLAN`，其中每个 action 都点名文件、命令、工件和有界检查。有 Codex progress-plan 机制时使用，并在 commentary 中总结计划。调用 executor 即授权普通的范围内实现与轻量验证；只有决定会实质改变范围或需要新授权时，才请求新方向。
3. **选择性委派。** 默认在本地执行。只有 collaboration 工具可用，且有边界、相互独立的工作确实能从委派中受益时才委派。绝不为每个琐碎顺序步骤创建一个 subagent。给每个受委派者 `references/agent_dispatch_spec_zh.md` 中的窄契约；主 agent 始终负责集成和重新运行检查。
4. **在重型或不可逆工作前停止。** 长时间或多 GPU 训练、全数据集评估、高成本 API 调用、无边界任务、覆盖有价值工件都会跨越 STOP line。准备可复现命令并交给用户；不要启动。遵循 `references/stop_line_rules_zh.md`。
5. **checkpoint 已验证状态——并保持子计划真实。** 把 `EXEC_PLAN.md` 和 `EXEC_LOG.md` 存在 `wkdrs/<run>/`。每次有界检查后更新日志。子计划 frontmatter 只维护 `exec_status`、`exec_runs`、`updated`；此外，仅当执行可证明地偏离子计划，或确定了计划留空而 method 文档会引用的值时，才对受影响 §2–§5 做一次**用户确认的回同步**并添加 `## Revision History`（`references/plan_sync_rules_zh.md`），使用户日后重读的计划与实际执行一致。
6. **使用项目运行时和布局。** 从 `.env` 读取 `CONDA_HOME`、`PYTHON_HOME`、`CODE_NAME`；绝不猜本地路径或使用系统 Python。若项目入口是 `execs/run.sh`，就使用它。创建 `tasks/<plan-name>/` 存放执行该计划时所需中间文件；可复用运行脚本放 `execs/scpts/`；生成输出和持久执行记录放 `wkdrs/<run>/`；数据放 `datas/`；权重放 `inits/`；代码放 `${CODE_NAME}/`。不要把生成的 run 工件放在 `tasks/`。遵循 `AGENTS.md`。

## 工作流

### Step 0：解析目标

1. 按 slug、数字前缀或完整文件名，把 `PLAN_NAME` 与 `metds/plans/*_plan.md` 匹配。
2. 只有 leaf 可执行。若目标的 `children:` 非空，列出其 leaf 并询问执行哪一个，或提议按依赖顺序逐个处理。
3. 目标不存在或有歧义时，列出简洁候选，只问一个直接问题。
4. 完整读取所选子计划。

### Step 1：检查就绪状态

1. 要求具体的 §3 任务分解与 §5 完成判据。若大部分是 `[TBD]` / `【待定】`，报告缺失决定，询问是返回 `$star-plan-decomposer`，还是在明确记录剩余不确定性的前提下继续。
2. 验证点名的数据集、权重、代码模块和每个 `depends_on` sibling。若硬依赖缺失或上游 sibling 未达到 `exec_status: done`，停止并报告准确 blocker。缺失数据集或权重是分解缺口，不能绕过：点名应拥有它的 data-readiness leaf，或转回 `$star-plan-decomposer <parent>` 添加一个。
3. 中间工作区为 `tasks/<plan-name>/`，其中 `<plan-name>` 是所选文件名去掉 `_plan.md`。若所选 leaf 已有 `exec_runs`，读取当前 run 的 `wkdrs/<run>/EXEC_LOG.md` 并恢复。否则 run 名使用 `<prefix>_<slug>`。若该 run 目录已存在但不是此 leaf 可恢复的 run，询问一个区分后缀；绝不自行编造。

### Step 2：定位

遵循 `references/orient_checklist_zh.md`：

1. 读取 `.env`，解析 `CODE_NAME`、`CONDA_HOME`、`PYTHON_HOME`（约定 §3）。若这些路径指定的环境缺失或无法运行 Python，推荐执行前先用 `$star-env-builder` 构建。
2. 映射 `${CODE_NAME}/`；若其中没有实现则声明 greenfield，或先用 `$star-code-architect` 引入参考代码库。
3. 把每个 §3 步骤追踪到真实文件，并分类为 exists / modify / create。
4. 确认实际 run 入口和测试入口。

### Step 3：构建并 checkpoint EXEC_PLAN

1. 把 §3 和 gap 列表细化成有序 action。每个 action 必须绑定 `{files / command through project env / artifact / check}`；最后一个 action 绑定 §5 完成判据。
2. 明确标出 STOP line；已知时估算运行时间/成本。
3. 把 EXEC_PLAN 相对子计划 §2–§5 的实质性出入，以 delta 形式（ADDED / MODIFIED / REMOVED / ENRICHED——`references/plan_sync_rules_zh.md`）记入 EXEC_PLAN 的“与子计划的偏差”表。在子计划自身粒度上的矛盾算偏差；“更具体”不算——除非那是计划未写明、而某份方法文档会引用的值，那要记为一条 ENRICHED 行并点名该章节。
4. 在 commentary 中展示简洁计划和预期副作用，并只问一次是否将每个已验证 action checkpoint 为 git commit（推荐），同时点名任何已有未提交修改的路径——绝不暂存这些路径。仅在存在实质范围选择、非空 divergence 表（执行前须与用户确认各行），或需要用户执行的 STOP-line action 时暂停。
5. 为计划中间文件创建 `tasks/<plan-name>/`。从匹配语言的模板创建 `wkdrs/<run>/EXEC_PLAN.md`，并在同目录初始化 `EXEC_LOG.md`。把子计划 frontmatter 更新为 `exec_status: in_progress`，并将本 run **追加**到 `exec_runs`，不能替换最后一项——这段历史使 `$star-expt-analyst aggregate` 能看到该 leaf 的每次运行。仍使用单个 `exec_run:` 的计划先迁移为 `exec_runs: [<that run>]`。此时把已确认的 divergence 行同步进子计划：原地更新受影响的 §2–§5 段落，追加 `## Revision History` 条目，更新 `updated`，并把每行标为 `synced`。

### Step 4：执行与验证

对每个未完成 action：

1. 选择本地执行或选择性委派。委派时遵循 `references/agent_dispatch_spec_zh.md`，保持文件所有权不重叠。
2. 只做该 action 必需的修改，并通过项目环境运行其窄范围有界检查。
3. 在主循环中重新运行或独立检查有界检查。通过后，checkpoint 证据和工件路径；若已批准 checkpoint，则提交该 action 的文件。失败后，若有具体修复可做，诊断并最多重试两次；否则把 action 标为 `blocked` 并停止。
4. action 跨越 STOP line 时，准备准确命令（还可选写入 `execs/scpts/<run>.sh`），记录到 `Awaiting user`，不运行并停止。
5. 若重试或 blocker 在子计划粒度改变了方法（新增/删除/替换步骤，交付物路径或完成判据变化），在 EXEC_LOG 的 `Pending amendments` 下记录 delta 行并继续——这些在 finalize 时同步，而不是运行中同步。

### Step 5：完成

1. 运行子计划 §5 完成判据，并把证据记录到 `EXEC_LOG.md`。
2. 满足时，把 run 与子计划 `exec_status` 设为 `done`，然后只提议一次删除该计划的 `tasks/<plan-name>/` scratch——先把仍值得保留的内容提升到 `wkdrs/<run>/`，并在 `EXEC_LOG.md` 记录选择；保留也完全可以。未满足时，按 §6 本地 fallback 处理，或报告已验证缺口。
3. 若 EXEC_LOG 的 `Pending amendments` 非空，一次展示整批（全部同步 / 选择部分 / 跳过），按 `references/plan_sync_rules_zh.md` 把确认行写回（原地更新 §2–§5 + 添加 `## Revision History` + 更新 `updated`，然后勾掉各行）。仅限战术层：任何触碰 §1/§6、父计划或 kill-criterion 的内容都通过第 5 点的 strategy signal 转交，绝不回同步。
4. 检查 `references/exec_rubric_zh.md`，报告前修复范围内的失败；最多列出五个剩余失败及具体补救方法。
5. 若结果命中根计划 kill-criterion 或使廉价 MVP 假设失效，在日志中记录 **Strategy signal**，并推荐 `$star-plan-reviser <slug>`（审计证据并修订计划）、`$star-plan-coach <slug>` 或 `$star-plan-decomposer <slug>`。不要编辑父计划的策略章节。

### Step 6：报告

以结果开头。说明验证了什么及其证据，`tasks/<plan-name>/` 中间工作区和 `wkdrs/<run>/` 记录/工件的位置，哪些命令等待用户执行，哪些 amendment 已同步进子计划，以及剩余风险。run 完成后，推荐 `$star-code-reviewer <leaf>` 在修订或进入下一项前，依据约定和子计划审计实现。若有 STOP line 命令等待用户，补充说明其输出产生后，`$star-expt-analyst <leaf>` 会根据 §5 完成判据给结果评分并解释其含义。报告控制在约 400 词以内。

## 状态规则

- 把 `wkdrs/<run>/EXEC_LOG.md` 视为执行事实来源。再次调用时跳过 `done` action，从第一个未完成项恢复。回同步必须幂等：标为 `synced` 或已勾选的行绝不重复应用；未同步 pending 行在 finalize 时重新提出。
- `tasks/<plan-name>/` 是该计划的可丢弃 scratch，本 skill 拥有其生命周期：Step 3 创建，§5 满足后在 finalize 时只提议一次删除。持久证据绝不放在那里；未经询问绝不删除，也绝不触碰其他计划的 `tasks/` 目录。
- 可以自由编辑子计划 frontmatter 的 `exec_status`、`exec_runs`、`updated`；只有通过用户确认的回同步协议（`references/plan_sync_rules_zh.md`）才能编辑其 §2–§5，且始终原地更新并配对一个 `## Revision History` 条目。绝不重写 §1 或 §6，绝不触碰父计划——objective 或 strategy 级偏差转交 `$star-plan-reviser` / `$star-plan-coach` / `$star-plan-decomposer`。
- Git：每个已验证 action 一个 commit，只暂存该 action 触碰的文件，且仅在 checkpoint 获批时（约定 §1）。
- 合法 action status：`pending` / `in_progress` / `done` / `blocked` / `skipped`。
- 匹配用户的对话语言，同时保留计划正文 frontmatter 的 `language`；中文计划中的技术术语保留英文。
