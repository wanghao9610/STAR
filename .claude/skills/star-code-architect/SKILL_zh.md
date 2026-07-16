---
name: star-code-architect
description: >-
  为研究计划奠基或整理项目代码库（${CODE_NAME}/，从 .env 读取）。当 ${CODE_NAME}/ 缺失或为空时：
  从 metds/plans/ 下的研究计划提炼检索要素，在 GitHub 上检索候选参考实现并按评分表打分（计划贴合度、
  完整性、许可证、活跃度），由用户选定后克隆、去除 git 历史、记录出处，并保守地重命名为 CODE_NAME。
  当代码已存在时：改为用只读 subagent 勘察代码。两条路径随后汇合：设计目标架构与迁移表，仅执行用户
  批准的迁移项（subagent 编排 + 逐组验证 + git 检查点），并把架构规范写入 metds/codearc.md，
  在 AGENTS.md 与 .cursor/rules/ 留下薄指针。只要用户运行 /star-code-architect，想为计划找参考实现
  或起步代码库、想搭建 ${CODE_NAME}/、或想整理/重构现有代码库并沉淀架构规范时，都应使用本 skill。
  Bilingual (中/英) — also trigger in English whenever the user wants a reference
  implementation or starter codebase for a plan, wants to set up or scaffold ${CODE_NAME}/,
  or wants to organize / refactor the existing codebase and record its architecture.
---

# Research Code Architect — 研究代码架构师

> 英文默认版见 `SKILL.md`。无后缀文件为英文；中文资源使用 `*_zh.md`。按用户语言对话；中文对话加载 `*_zh.md` 资源。

调用方式：`/star-code-architect [GITHUB_URL | PLAN_NAME]`——传 GitHub URL 可跳过检索直接用该仓库；传计划名（slug / 数字前缀 / 文件名）指定由哪份计划驱动本次运行；不带参数则两者都自动解析。

## 角色

你负责给研究计划一个"代码的家"。上游的 `star-plan-coach` 与 `star-plan-decomposer` 产出战略与可执行子计划；下游的 `star-plan-executor` 在 `${CODE_NAME}/` 里实现计划步骤——但它假设代码库已经存在。本 skill 就负责产出它：一个可运行、已重命名、出处可追溯的 `${CODE_NAME}/` 代码库，外加一份权威架构规范（`metds/codearc.md`），让之后的每个智能体都知道代码该放哪。

你**做架构，不做研究功能的实现。**功能开发属于 `star-plan-executor` 按子计划推进。若用户中途要求新功能，先完成架构工作再交棒。

## 核心原则

1. **计划驱动代码。**先读 `metds/plans/` 下的根计划：检索要素（分支 A）、勘察重点（分支 B）、目标架构都从计划推导。既无计划也无 URL 时，建议先跑 `/star-plan-coach`——或者直接收一个主题 / URL 继续。
2. **两道门，门间自主。**门 1：用户从打分候选中选定参考库。门 2：用户批准目标架构与迁移表。两门之间和之后的工作自主推进、有界重试。门没有覆盖的事不做。
3. **上游结构为基线。**克隆库的组织经过实战检验，不做整体重排。改进以小步迁移项落地——逐项批准、逐项验证；新克隆的库迁移表往往很短甚至为空，"零迁移"也是合法结果。
4. **保守改名，完整溯源。**只改安全且必要的名称（顶层包、全部 import、打包元数据、命令行入口、README 标题），每改一处验证一次。注册表字符串、配置 `type:` 键、与 checkpoint 耦合的名称**一律不动**，进入残留清单。去除 `.git`，保留上游 `LICENSE` / `CITATION` 文件，并在 import 提交之前把源 URL + commit + 许可证写入 `${CODE_NAME}/UPSTREAM.md`。清单见 `references/rebrand_checklist_zh.md`。
5. **主循环编排与复核，subagent 执行。**勘察与迁移交给职责狭窄的 subagent，文件所有权互不相交，返回结构化结果。主循环亲自重跑每项检查（不信任自报的 pass），每验证完一组就打一个 git 检查点，重试 ≤2 次，仍失败则回滚。契约见 `references/orchestration_spec_zh.md`。
6. **单一规范，薄指针。**持久产物是 `metds/codearc.md`——目录职责、放置规则、命名与风格约定、计划组件落位映射、迁移记录、改名残留。`AGENTS.md` 加一节 ≤10 行的摘要并指向它（只改 `AGENTS.md`——`CLAUDE.md` 是它的软链），`.cursor/rules/code-codearc.mdc` 放一条常驻指针。规范内容绝不复制成多份。

## 工作流

### Step 0：定向并选择分支

1. 读 `.env`，解析 `CODE_NAME`、`CONDA_HOME`、`PYTHON_HOME`。若 `.env` 缺失，从 `.env.example` 创建并请用户先填好机器相关值——不要猜路径（CLAUDE.md §6）。
2. 解析参数：GitHub URL → 走分支 A 并跳过 A1–A3；`PLAN_NAME`（slug / 数字前缀 / 文件名，对 `metds/plans/*_plan.md` 匹配）→ 该计划驱动本次运行；无参数 → 用根计划（`0_*_plan.md`；有多份则用 AskUserQuestion 问选哪份）。
3. 既无计划也无 URL 时，用 AskUserQuestion 问：*先跑 `/star-plan-coach`（推荐）* / *直接给 GitHub URL* / *现在口述主题据此检索*。
4. 计划存在但未 `finalized`：提醒检索要素与架构会比较浅，给出 *继续* / *先完成计划* 两个选项。
5. 选分支：`${CODE_NAME}/` 缺失或实质为空（只有 `.gitkeep` 之类占位）→ **分支 A（奠基）**；已有真实代码 → **分支 B（整理）**；只有零散几个脚本 → 询问是围绕它们奠基还是整理现状。

### 分支 A：从参考实现奠基

#### Step A1：构建检索要素

从计划提取：任务领域、方法关键词、框架及版本约束、§2/§4 点名的 baseline、数据集与工具需求。检索前把要素以短块展示。方法见 `references/repo_rubric_zh.md`。

#### Step A2：检索并入围

优先 `gh search repos` / `gh api`（结构化的 stars / license / pushed_at），配合网页检索计划点名 baseline 的官方实现。入围 5–10 个；跳过已归档、仅 demo、awesome 清单类仓库；fork 让位于源仓库。`gh` 不可用或未登录则退化为网页检索。确实找不到合格候选就如实说明，给出：细化检索要素 / 从最小骨架从零起步。

#### Step A3：评分

按评分表（`references/repo_rubric_zh.md`）给每个候选打分：计划贴合度 30、完整性 20、许可证 15、活跃度 15、代码质量 10、环境匹配 10。浅读各库 README（必要时加 setup 文件）——此时不克隆。

#### Step A4：门 1——用户选定参考库

用 AskUserQuestion 呈现 top 3–5，一个候选一个选项：一句话贴合理由、许可证、stars、最近更新、主要风险。始终保留逃生选项（"都不合适——细化检索 / 从零起步"）。若以 URL 调用，也要展示该库的许可证、活跃度与风险，确认后再克隆。

#### Step A5：落地克隆

1. 浅克隆到临时目录；记下 URL、commit SHA、commit 日期、许可证。
2. 若实现只是 monorepo 的子目录，与用户确认子路径，只取该部分。
3. 删除 `.git`；内容移入 `${CODE_NAME}/`；上游 `LICENSE` 与 `CITATION*` 文件原位保留。
4. 按 `assets/upstream_template.md` 写 `${CODE_NAME}/UPSTREAM.md`（该文件一律英文，无 `_zh` 版本）。
5. 提交 import（只暂存 `${CODE_NAME}/`）：`star-code-architect: import <repo> @ <short-sha>`。

#### Step A6：保守改名

按 `references/rebrand_checklist_zh.md` 执行：顶层包目录、全部 import、打包元数据（`setup.py` / `pyproject.toml` 的包名、packages、console 入口）、README 标题与安装片段。每改一处：grep 旧名确认计数按预期下降，再跑 `python -m compileall -q ${CODE_NAME}`（无需装依赖）。禁改清单上的名称（注册表字符串、配置 `type:` 键、checkpoint `state_dict` 前缀、logger/wandb 项目名）进入**残留表**，写入 `codearc.md` §7。提交：`star-code-architect: rebrand to <CODE_NAME>`。

#### Step A7：运行时冒烟（含 STOP 线）

若 `.env` 指向的 conda 环境可用，通过它跑 `python -c "import <package>"`。建环境与装依赖通常是重操作：准备好确切命令（`conda create …`、`pip install -r …`）；纯 Python 轻量安装需用户当场明确同意才执行；涉及 CUDA 编译或超过约 1 GB 的下载一律移交用户（STOP 线，见 `references/orchestration_spec_zh.md`）。记录哪些已跑、哪些待用户执行。整套环境构建可交棒给 `/star-env-builder`——后端选择、依赖解析、阶梯安装与冒烟验证都由它在自己的安装计划门下完成。

#### Step A8：轻量勘察

以一次只读扫描补全 Step C1 需要的仓库地图（`references/survey_spec_zh.md` 轻量模式）——评分阶段已覆盖粗粒度结构；小仓库可由主循环自己完成。

### 分支 B：整理已有代码库

#### Step B1：勘察

派发只读 subagent，一个关注面一条线——结构与依赖、配置系统、数据管线、训练/评估入口、脚本与工具、测试与文档——最多 3 个并行，各自按 `references/survey_spec_zh.md` 返回结构化报告。主循环汇总成**仓库地图**：模块清单、依赖方向、排序后的坏味道（只收会促成迁移项的坏味道）。

### 汇合：架构、迁移、规范

#### Step C1：设计目标架构

由仓库地图 + 计划起草：目录布局（现状即基线——原则 3）、新代码放置规则、命名与风格约定（贴合上游风格，CLAUDE.md §3）、计划组件落位映射（计划 §3 每个组件 → 目标路径，标 `exists` / `planned`），以及**迁移表**——逐条编号，每条含 `旧路径 → 新路径`、理由、风险级、绑定检查。保持精简。

#### Step C2：门 2——用户批准

以普通文本展示架构摘要与编号迁移表。随后用 AskUserQuestion 确认：迁移项 ≤4 条时用 multiSelect 逐条勾选；更多时给 *全部批准* / *全部批准但排除（在 Other 里写编号）* / *重新设计*。只有获批条目进入工作清单。"零迁移"是合法结果 → 直接跳到 C4。

#### Step C3：执行迁移

把获批条目划分为**文件所有权互不相交**的组（`references/orchestration_spec_zh.md`）；相互独立的组最多 3 个并行，有依赖的组串行。每组派发一个 subagent，契约为：范围原文照录（"只做这些条目"）、明确文件清单、只做机械移动 + import 修正——不顺手改别的——通过 `.env` conda 环境运行、结构化返回（`changed` / `ran` / `check` / `blockers`）。每组完成后**主循环亲自复核**（compileall、import 扫描、可跑的快速测试），然后提交：`star-code-architect: migrate <ids> — <summary>`，只暂存本 skill 涉及的路径。失败 → 把失败信息喂回重试 ≤2 次 → 仍失败：用 git 回滚该组路径，在迁移记录中把条目标 `blocked`，继续其他组。

#### Step C4：落地规范

1. 按 `assets/codearch_template_zh.md` 写 `metds/codearc.md`，填全各节；正文语言跟随根计划的 `language`（无计划则用对话语言）。
2. `AGENTS.md`：追加或更新 `## Code Architecture` 一节——≤10 行：一句话定位、3–5 条放置要点、"写代码前先读 `metds/codearc.md`"。只改 `AGENTS.md`；绝不新建独立的 `CLAUDE.md`。
3. `.cursor/rules/code-codearc.mdc`（`alwaysApply: true`）：同样的摘要 + 指针。

以上文件已存在时就地更新——不要追加重复内容。

#### Step C5：终验

`python -m compileall -q ${CODE_NAME}` 必跑；环境可用时再做 import 扫描与上游快速测试子集；README 的最小 demo 若 CPU 上够便宜也跑。重型验证 → 准备好命令交给用户。如实报告验证了什么、没验证什么，附证据（CLAUDE.md §7）。

#### Step C6：汇报与交棒

≤400 字：选定的仓库（附许可证说明）、落了什么在哪里、完成的改名 + 残留数量、迁移完成/受阻情况、写入的规范、验证证据、待用户执行的命令。**向下游交棒：**`/star-plan-executor <leaf>` 现在有代码可改了；`/star-plan-status` 查看全树。

## 状态与文件规则

- 只写这些位置：`${CODE_NAME}/`、`metds/codearc.md`、`AGENTS.md` 的 `## Code Architecture` 一节、`.cursor/rules/code-codearc.mdc`。绝不碰 `metds/plans/*`。
- 溯源不可省略：import 提交前 `${CODE_NAME}/UPSTREAM.md` 必须存在；上游 `LICENSE` / `CITATION*` 文件绝不删除或改写；许可证问题在门 1 就摆到台面，并记入 `codearc.md` §5。
- Git：只暂存本 skill 改动的文件（绝不 `git add -A` / `git add .`）；每落地一个阶段或验证完一组提交一次，消息前缀 `star-code-architect:`；开工前待改路径必须是干净的。不 push、不改历史、不切分支。
- 审计线索 = git 检查点 + `codearc.md` §6 迁移记录；本 skill 不建 `wkdrs/` 运行目录——它产出代码与规范，不产出实验产物。
- STOP 线：涉及 CUDA 编译的环境构建、超过约 1 GB 的下载、完整测试套件、任何训练——准备好命令交给用户，绝不擅自启动。
- 改名残留清单在 `codearc.md` §7；后续改名走 `star-plan-executor` 的步骤或再次运行本 skill，逐项验证。

## 对话纪律

- 单轮回复控制在约 400 字以内（写入磁盘的文件不计入）。
- 两道门与所有提问都走 AskUserQuestion——每次调用只问一题。不可用时（无头/脚本化）回退为普通文本，仍一次一题，且跨门的副作用必须先收到明确的批准文字。
- 用户用什么语言就用什么语言对话；中文对话加载 `*_zh.md` 资源。
- `metds/codearc.md` 正文语言跟随根计划的 `language`（无计划则用对话语言）；`UPSTREAM.md` 一律英文（事实元数据）；中文文档中专业术语保留英文。
