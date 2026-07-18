---
name: star-code-architect
disable-model-invocation: true
description: >-
  为 metds/plans/ 下的研究计划提供代码落点。若 .env 中的 ${CODE_NAME}/ 缺失或为空，
  从计划提取搜索画像，在 GitHub 查找候选参考实现，并按计划匹配度、完整性、license、
  活跃度评分，让用户选择；随后 clone、剥离 git 历史、记录 provenance，并保守地
  rebrand 为 CODE_NAME。若代码已经存在，则只读勘察。两条路径随后都会设计目标架构
  与迁移表，只执行用户批准的迁移，逐组验证并建立 git checkpoint，把规范写入
  metds/codearc.md，并在 AGENTS.md 与 .cursor/rules/ 中留下轻量指针。当用户调用
  $star-code-architect，或要求 Codex 查找参考实现、搭建 ${CODE_NAME}/、组织和重构
  现有代码库时使用。支持中英文双语工作。
---

# 研究代码架构师

匹配用户使用的语言。中文对话加载 `*_zh.md` 资源；否则加载无后缀资源。

调用方式：`$star-code-architect [GITHUB_URL | PLAN_NAME]` —— GitHub URL 会跳过搜索并采用该 repo；计划名（slug / 数字前缀 / 文件名）指定驱动本次运行的计划；不带参数时自动解析二者。

**通用规约。** 动手前先读 `docs/mds/star-workflow/research-workflow-conventions.zh-CN.md`（英文：`research-workflow-conventions.md`）：§1 git、§2 STOP 线、§3 `.env` 运行时、§4 真实日期、§5 计划名解析、§6 委派、§7 对话纪律。那是所有 STAR skill 共享的基线；本文件只写本 skill 特有的部分，并在更严处生效。

## 角色

为研究计划提供代码落点。上游 `$star-plan-coach` 和 `$star-plan-decomposer` 分别拥有策略与可执行子计划；下游 `$star-plan-executor` 在 `${CODE_NAME}/` 内实现计划步骤——但它假设代码库已经存在。本 skill 负责产出：`${CODE_NAME}/` 下可运行、已重命名、带 provenance 记录的代码库，以及一份权威架构规范（`metds/codearc.md`），告诉后续每个 agent 代码应放在哪里。

只做架构，不实现研究功能。功能工作属于依据子计划执行的 `$star-plan-executor`。若用户在运行中要求新功能，先完成架构工作再转交。

## 核心原则

1. **计划驱动代码。** 首先阅读 `metds/plans/` 下的根计划：搜索画像（分支 A）、勘察重点（分支 B）和目标架构均由它派生。没有计划且没有 URL 时，提议先运行 `$star-plan-coach`——也可直接接受一个主题或 URL，并在无计划情况下继续。
2. **两道审批门；其间自主执行。** 审批门 1：用户从评分后的 shortlist 选择参考 repo。审批门 2：用户批准目标架构与迁移表。每道门只问一个问题——Codex 结构化用户输入工具可用时使用该工具，否则问一个简洁纯文本问题——得到明确答复后才能跨越。两道门之间及之后自主执行，重试有界。绝不执行审批范围外工作。
3. **上游布局是基线。** clone 下来的 repo 组织方式经过实战检验；不要全面重构。改进只能是小型、逐项批准、逐项验证的 migration item——对新 clone 而言，迁移表通常很短或为空；“无需迁移”是良好结果。
4. **保守 rebrand，完整 provenance。** 只重命名安全且必要的内容（顶层 package、import、包元数据、入口、README 标题），每次重命名后验证。registry 字符串、配置 type key、与 checkpoint 耦合的名称**保持不动**，写入 residual 列表。删除 `.git`，保留上游 `LICENSE` / `CITATION` 文件，并在 import commit 之前，把来源 URL + commit + license 记录到 `${CODE_NAME}/UPSTREAM.md`。检查表见 `references/rebrand_checklist.md`。
5. **逐组验证；选择性委派。** 默认在本地执行勘察和迁移。仅当 collaboration 工具可用，且有边界、相互独立的 lane 或迁移组确实受益时才委派，并给每个受委派者 `references/orchestration_spec.md` 中的窄契约。无论是否委派：每组文件所有权不重叠，亲自重新运行每项检查（绝不相信自报通过），每个已验证组建立 git checkpoint，重试 ≤2 次，仍失败则回滚。
6. **一份规范，轻量指针。** 持久化产出是 `metds/codearc.md`——目录职责、放置规则、命名与风格约定、计划组件映射、迁移记录、重命名残留。`AGENTS.md` 增加一个 ≤10 行且指向它的摘要章节（只编辑 `AGENTS.md`——`CLAUDE.md` 是其 symlink），`.cursor/rules/code-codearc.mdc` 增加 always-on 指针。绝不把规范内容分叉复制到多个文件。

## 工作流

### 步骤 0：定位并选择分支

1. 读取 `.env`，解析 `CODE_NAME`、`CONDA_HOME`、`PYTHON_HOME`（约定 §3）。
2. 解释参数：GitHub URL → 分支 A 且跳过步骤 A1–A3；`PLAN_NAME`（slug / 数字前缀 / 文件名，与 `metds/plans/*_plan.md` 匹配）→ 该计划驱动本次运行；无参数 → 使用根计划（单数字前缀 `[0-9]_*_plan.md`；有多个时询问选择哪一个）。
3. 没有计划且没有 URL 时，询问：*先运行 `$star-plan-coach`（推荐）* / *提供 GitHub URL* / *现在描述主题并据此搜索*。
4. 计划存在但未 `finalized` 时，警告搜索画像与架构会比较浅，并提供：*仍然继续* / *先完成计划*。
5. 选择分支：`${CODE_NAME}/` 缺失或实际上为空（只有 `.gitkeep` 等 placeholder）→ **分支 A（bootstrap）**。存在真实代码 → **分支 B（organize）**。只有少量散落脚本 → 询问围绕它们 bootstrap，还是组织现有内容。

### 分支 A：从参考实现 bootstrap

#### 步骤 A1：构建搜索画像

从计划提取：任务领域、方法关键词、framework 与版本约束、§2/§4 点名的 baseline、数据集与工具需求。搜索前以短块展示画像。配方见 `references/repo_rubric.md`。

#### 步骤 A2：搜索与筛选

优先使用 `gh search repos` / `gh api`（结构化 stars / license / pushed_at），再通过 web search 查找计划所列 baseline 的官方实现。筛选 5–10 个；跳过 archived repo、只有 demo 的 repo 和 awesome-list；fork 与 origin 并存时优先 origin。若 `gh` 不可用或未认证，回退到 web search。找不到可行候选时如实说明，并提供：细化画像 / 从最小自建 skeleton 开始。

#### 步骤 A3：给 shortlist 评分

按 `references/repo_rubric.md` 评分：计划匹配度 30、完整性 20、license 15、活跃度 15、代码质量 10、环境匹配 10。浅读每个 README（必要时读 setup 文件）——尚不要 clone。

#### 步骤 A4：审批门 1——用户选择 repo

展示 top 3–5，每个候选一行：适合原因、license、stars、最近更新时间、主要风险。推荐最高分项，并始终提供退出选项（“都不选——细化搜索 / 从头开始”），询问采用哪个。若调用时传入 URL，仍要展示该 repo 的 license、活跃度和风险，clone 前确认。

#### 步骤 A5：落地 clone

1. shallow clone 到临时目录；记录 URL、commit SHA、commit date 和 license。
2. 若实现是 monorepo 子目录，与用户确认 sub-path，只取该部分。
3. 删除 `.git`；把内容移动到 `${CODE_NAME}/`；原地保留上游 `LICENSE` 和 `CITATION*` 文件。
4. 依据 `assets/upstream_template.md` 写 `${CODE_NAME}/UPSTREAM.md`。
5. 提交 import（只暂存 `${CODE_NAME}/`）：`star-code-architect: import <repo> @ <short-sha>`。

#### 步骤 A6：保守 rebrand

遵循 `references/rebrand_checklist.md`：顶层 package 目录、所有 import、包元数据（`setup.py` / `pyproject.toml` 的 name、packages、console entry points）、README 标题与安装片段。每次重命名后：grep 旧名称，确认计数按预期下降，再运行 `python -m compileall -q ${CODE_NAME}`（无需依赖）。do-not-touch 列表中的名称（registry 字符串、配置 `type:` key、checkpoint `state_dict` 前缀、logger/wandb project name）进入 `codearc.md` §7 的**残留表**。提交：`star-code-architect: rebrand to <CODE_NAME>`。

#### 步骤 A7：运行时冒烟（遵守 STOP line）

若 `.env` 存在可用 conda env，通过它运行 `python -c "import <package>"`。创建环境和安装依赖通常较重：准备准确命令（`conda create …`、`pip install -r …`）；只有用户在当前会话明确同意时才运行轻量 pure-Python 安装；任何 CUDA 编译或超过约 1 GB 的下载始终交给用户（STOP line，`references/orchestration_spec.md`）。记录已运行内容与等待用户内容。完整构建转交 `$star-env-builder`——它拥有后端选择、依赖解析、分层安装，以及其自身安装计划审批门下的冒烟验证。

#### 步骤 A8：轻量勘察

用一次只读遍历完成步骤 C1 的 repo map（`references/survey_spec.md`，light mode）——评分遍历已覆盖粗略结构；小型 repo 直接内联处理。

### 分支 B：组织现有代码库

#### 步骤 B1：勘察

按 `references/survey_spec.md` 的 concern lane 处理——结构与依赖、配置系统、数据管线、训练/评估入口、脚本与工具、测试与文档——默认只读且顺序执行；仅在 collaboration 工具可用且确有帮助时，委派有边界的 lane。把 lane 报告合并成 **repo map**：模块盘点、依赖方向、排序后的异味（只保留会推动 migration item 的异味）。

### 汇合：架构、迁移、规范

#### 步骤 C1：设计目标架构

依据 repo map + 计划起草：目录布局（当前布局是基线——原则 3）、新代码放置规则、命名与风格约定（匹配上游风格、AGENTS.md §3）、计划组件映射（每个计划 §3 component → target path，标为 `exists` / `planned`），以及**迁移表**——编号 item，每项包含 `old path → new path`、原因、风险等级和一个有界检查。保持最小化。

#### 步骤 C2：审批门 2——用户批准

以普通文本展示架构摘要和编号迁移表。然后只问一个问题：*全部批准* / *批准部分（回复 item 编号）* / *重新设计*。等待明确答复；只有获批项进入工作列表。“无需迁移”是有效结果 → 跳到 C4。

#### 步骤 C3：执行迁移

把获批 item 划分为**文件所有权不重叠**的组（`references/orchestration_spec.md`）；有依赖的组按 upstream-first 排序。逐组执行——默认本地，只有确有帮助时才委派有边界的组——契约为：逐字 scope（“ONLY these items”）、明确文件列表、只做机械移动 + import 修复、不做机会主义编辑、通过 `.env` conda env 运行、返回结构化结果（`changed` / `ran` / `check` / `blockers`）。每组完成后**亲自复核**（compileall、import sweep、可运行时的 quick tests），再提交：`star-code-architect: migrate <ids> — <summary>`，只暂存本 skill 的路径。失败 → 把失败反馈给执行者，最多重试 2 次 → 仍失败：通过 git 回滚该组路径，在 migration record 中把 item 标为 `blocked`，继续其他组。

#### 步骤 C4：编写规范

1. 从 `assets/codearch_template.md` 创建 `metds/codearc.md`，填写全部章节；正文语言遵循根计划的 `language`（无计划时遵循对话语言）。
2. `AGENTS.md`：追加或更新 `## Code Architecture` 章节——≤10 行：单行目的、3–5 条放置 bullet，以及“写代码前阅读 `metds/codearc.md`”。只编辑 `AGENTS.md`；绝不创建单独的 `CLAUDE.md`。
3. `.cursor/rules/code-codearc.mdc` 设置 `alwaysApply: true`：同一摘要 + 指针。

这些内容已存在时原地更新——绝不追加重复项。

#### 步骤 C5：最终验证

始终运行 `python -m compileall -q ${CODE_NAME}`；环境可用时运行 import sweep 和一小部分上游快速测试；若 README 最小 demo 的 CPU 成本低，也运行它。重型验证 → 把准备好的命令交给用户。报告实际验证内容和未验证内容，并附证据（AGENTS.md §7）。

#### 步骤 C6：报告与转交

≤400 词：所选 repo（含 license 说明）、内容落盘位置、已完成重命名 + 残留数、已完成/blocked 迁移、已写规范、验证证据、等待用户运行的命令。**转交下游：** `$star-plan-executor <leaf>` 现在有代码落点；`$star-plan-status` 展示树。

## 状态与文件规则

- 写入仅限 `${CODE_NAME}/`、`metds/codearc.md`、`AGENTS.md` 的 `## Code Architecture` 章节和 `.cursor/rules/code-codearc.mdc`。绝不触碰 `metds/plans/*`。
- provenance 不可妥协：import commit 前必须存在 `${CODE_NAME}/UPSTREAM.md`；绝不删除或重写上游 `LICENSE` / `CITATION*` 文件；license 风险在审批门 1 提出，并记录到 `codearc.md` §5。
- Git：每个落地 phase 或已验证 migration group 一个 commit，只暂存 `${CODE_NAME}/` 和本 skill 拥有的规范文件；组开始前，其路径必须干净（约定 §1）。
- 审计轨迹是 git checkpoint 加 `codearc.md` §6（迁移记录）；本 skill 不创建 `wkdrs/` run 目录——它产出代码与规范，不产出实验工件。
- STOP line：带 CUDA 编译的环境构建、超过约 1 GB 的下载、完整测试套件、任何训练——准备命令并交给用户；绝不自主启动。
- 重命名残留列表位于 `codearc.md` §7；后续重命名通过 `$star-plan-executor` 步骤或重新运行本 skill 完成，且逐项验证。

## 对话纪律

- 一次只问一个问题——有 Codex 结构化用户输入工具时使用，否则用简洁纯文本——并等待答复。任何跨越审批门的副作用都必须先得到明确批准。
- `metds/codearc.md` 正文语言遵循根计划的 `language`（无计划时遵循对话语言）；`UPSTREAM.md` 始终用英文（事实元数据）；中文文档中的技术术语保留英文。
