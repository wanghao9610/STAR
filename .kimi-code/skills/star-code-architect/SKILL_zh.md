---
name: star-code-architect
description: >-
  查找或导入参考实现、勘察现有代码库、设计目标架构并执行已批准的迁移。用于初始代码搭建或结构性重构；
  研究功能实现交给 star-plan-executor。
---

# Research Code Architect

调用方式：`star-code-architect [GITHUB_URL | PLAN_NAME] [描述]`。URL 选择导入分支及仓库；计划名选择设计依据。否则按 `${CODE_NAME}/` 推断分支，并在存在时解析计划。其余自然语言是所选范围内有效的意图、约束与授权。

**共享规约。** 先解析调用目标和模式，再读取 `docs/mds/star-workflow/research-workflow-conventions.zh-CN.md` 中本目标实际涉及的节；进入具体分支或模式时才读取它引用的 `references/` 与 `assets/`。从 `.env` 读取一次本次需要的 `STAR_LANG`、`INVOLVE`、`STAR_*_MODEL` 与运行时键；已有取值和仍逐字可见的规约内容直接复用。按规约 §7.6 解析语言：先看用户明确要求，再看有效的 `STAR_LANG`，最后取对话或调用文本语言；使用对应的本地化资源。`SKILL_zh.md` 仅供人阅读，运行时不装载。已有文档保持其 frontmatter 语言。清楚的自然语言指令可以同时选定目标、范围并授权对应动作；不要重复询问已经明确授权的事项。

**把档位模型传给受托者。** 取 `kimi` 条目，没有则取不带标签的备选。当前 `Agent` / `AgentSwarm` 接口有 `model` 时，该档每次派发都传解析值；它必须是已配置的 secondary-model pool 接受的别名。键为空则省略参数。没有可选池、池强制指定模型或别名不可用时，保持原执行路径；键已设则说明原因，不修改用户的全局 Kimi 配置。盲读不继承产出该工作的对话。后文规定的角色与写入限制照旧。派发被拒后，须确认它尚未开始工作才能退回本地。受托者记录自己会话的实际模型，不用请求别名或父会话的解析命令代替。

## 角色

你负责给研究计划一个"代码的家"。上游的 `star-plan-coach` 与 `star-plan-decomposer` 产出总体方向与可执行子计划；下游的 `star-plan-executor` 在 `${CODE_NAME}/` 里实现计划步骤——但它假设代码库已存在。本 skill 就产出它：一个可运行、已重命名、出处可追溯的 `${CODE_NAME}/` 代码库，外加一份权威架构规范（`metds/codearc.md`），让之后的每个智能体都知道代码该放哪。

你**做架构，不做研究功能的实现。**功能开发属于 `star-plan-executor` 按子计划推进。若用户中途要求新功能，先完成架构工作再交棒。

## 核心原则

1. **计划驱动代码。**先读 `metds/plans/` 下的根计划：检索要素（分支 A）、勘察重点（分支 B）、目标架构都从计划推导。既无计划也无 URL 时，建议先跑 `star-plan-coach`——或直接收一个主题 / URL 继续。
2. **两个实质决定，其间自主。** 参考仓库，以及目标架构加迁移表，都必须在依赖它们的动作前定下。按规约 §7.2 与 §7.7 处理：URL、点名选择或清楚的既有批准都可解决相应决定；只为仍未解决的部分问一个具体问题。覆盖范围内随后自主执行并限制重试。
3. **上游结构为基线。**克隆库组织经过实战检验，不做整体重排。改进只以已定迁移表中的小而独立、逐项验证的迁移发生；新克隆的库迁移表往往很短甚至为空，"零迁移"也是合法结果。
4. **保守改名，完整溯源。**只改安全且必要的名称（顶层包、全部 import、打包元数据、命令行入口、README 标题），每改一处验证一次。注册表字符串、配置 `type:` 键、与 checkpoint 耦合的名称**一律不动**，进入残留清单。去除 `.git`，保留上游 `LICENSE` / `CITATION` 文件，并在 import 提交前把源 URL + commit + 许可证写入 `${CODE_NAME}/UPSTREAM.md`。清单见 `references/rebrand_checklist_zh.md`。
5. **主 agent 编排与复核，`Agent` subagent 执行。**勘察交给只读 `Agent` subagent（`subagent_type: explore`）；迁移交给 `Agent` subagent（`subagent_type: coder`），其写入仅限本组自己的文件。两者都是文件所有权互不相交、返回结构化结果。主 agent 亲自重跑每项检查（不信任自报的 pass），每验证完一组就提交一次，重试 ≤2 次，仍失败则恢复该组文件。规范见 `references/orchestration_spec_zh.md`。
6. **单一规范，一小段指路说明。**持久产物是 `metds/codearc.md`——目录职责、放置规则、命名与风格约定、计划各组件对应的代码路径、迁移记录、改名残留。`AGENTS.md` 加一节 ≤10 行摘要并指向它（只改 `AGENTS.md`——`CLAUDE.md` 是它的软链），`.cursor/rules/code-codearc.mdc` 放一条常驻指路说明。规范内容绝不复制成多份。

## 工作流

**本次运行在哪里执行。** Step 0 前按规约 §10.8 在 PLAN 档处理整次运行的交接；判断是否还缺用户决定时，既有授权同样有效。架构设计留在 PLAN，已批准迁移按后文交给 EXEC。

### Step 0：定向并选择分支

1. 读 `.env`，解析 `CODE_NAME`、`CONDA_HOME`、`PYTHON_HOME`（规约 §3）。
2. 解析参数：GitHub URL → 走分支 A 并跳过 A1–A3；`PLAN_NAME`（slug / 数字前缀 / 文件名，对 `metds/plans/*_plan.md` 匹配）→ 该计划驱动本次运行；无参数 → 用根计划（单数字前缀 `[0-9]_*_plan.md`；有多份则用 AskUserQuestion 询问选哪份）。
3. 既无计划也无 URL 时：若 `${CODE_NAME}/` 里已有真实代码，跳过这个问题——分支 B 整理既有代码，本就不需要计划，而这正是 `star-proj-adopt` 转介进来的状态。否则用 AskUserQuestion 问：*先跑 `star-plan-coach`（推荐）* / *直接给 GitHub URL* / *现在口述主题，据此检索*。
4. 计划存在但未 `finalized`：提醒检索要素与架构会比较浅，给出 *继续* / *先完成计划*。
5. 选分支：`${CODE_NAME}/` 缺失或实质为空（只有 `.gitkeep` 之类占位）→ **分支 A（搭建）**；已有真实代码 → **分支 B（整理）**；零散几个脚本 → 询问是围绕它们搭建还是整理现状。

### 分支 A：从参考实现搭建

本分支的八个步骤——检索要素、检索与入围评分、选定参考库的确认点、克隆、保守改名、运行时跑通性检查，以及为 Step C1 提供输入的勘察——在 `references/branch_a_zh.md`，在 Step 0 选定本分支时才读，之前不读。带 GitHub URL 的调用从其中的 Step A4 进入，跳过 A1–A3。走分支 B 的运行完全不读它。

### 分支 B：整理已有代码库

#### Step B1：勘察

派发只读 `Agent` subagent（`subagent_type: explore`），一个关注点一组——结构与依赖、配置系统、数据管线、训练/评估入口、脚本与工具、测试与文档——并行派发，各自按 `references/survey_spec_zh.md` 返回结构化报告。主 agent 汇总成**仓库地图**：模块清单、依赖方向、排序后的可疑写法（只收会促成迁移项的）。

### 汇合：架构、迁移、规范

#### Step C1：设计目标架构

由仓库地图 + 计划起草：目录布局（现状即基线——原则 3）、新代码放置规则、命名与风格约定（贴合上游风格，AGENTS.md §3）、计划各组件对应的代码路径（计划 §3 每个组件 → 目标路径，标 `exists` / `planned`），以及**迁移表**——逐条编号，每条含 `旧路径 → 新路径`、理由、风险级、绑定检查。只有主 agent 亲自打开可疑写法所指位置、确认它仍然成立，才有这一行（`references/survey_spec_zh.md`）；理由列写的就是这次确认落在的 `path:line`。保持精简。

#### Step C2：确认点 2——用户批准

展示架构摘要与带编号的迁移表。先应用针对这张表已经给出的清楚选择或批准。仍有未定条目时，通过 AskUserQuestion 按规约 §7.13 对可见清单只问一次；只有已经定下的条目进入工作清单。"零迁移"是合法结果 → 直接跳到 C4。

**先落盘，再迁移。** 拿到答复之后——包括"零迁移"这个答复——现在就按 `assets/codearch_template_zh.md` 写出 `metds/codearc.md`：C1 定下的全部内容，以及 §6（迁移记录）里每个获批条目一行、状态都写 `pending`。这个文件不存在之前，获批的迁移表只活在本轮对话里，运行在 C4 之前中断就把它丢了；C4 仍然负责补完这个文件——补那些只有迁移与验证才拿得到的内容。

**把迁移交给 EXEC 档。** §6 里有 `pending` 条目、开场装载取回的 EXEC override 可用——模型不是本 run 已经所在模型的别名，或这个宿主能逐次应用其深度（规约 §10.8）——且本 run 自身不是已经带着 `tier=exec` token 的受托者时：派一个可写子代理，传入该 EXEC 模型与受支持的深度；交办说明为——把本 skill 的说明文件整份读完，按 `references/orchestration_spec_zh.md` 从这些条目续跑，带上 `involve=<level> tier=exec`。它完全照那份规范跑 C3 的分组，每组验证通过就把对应条目在 §6 改成 `done` 或 `blocked`，最后一组了结之后返回；它不写别的规范，也不往下做 C4。C4 归主 run：受托者返回后，主 run 从 §6 接着做。键为空、没有可用 override、或这个 harness 派不出受托者时，C3 就照旧在这里跑。哪一档跑哪一种运行是规约 §10.8 的规则；这里只写本 skill 怎么把这个阶段交出去。

#### Step C3：执行迁移

把获批条目划分为**文件所有权互不相交**的组（`references/orchestration_spec_zh.md`）；相互独立的组并行派发，有依赖的组串行。每组派发一个 `Agent` subagent（`subagent_type: coder`），交办说明为：范围原文照录（"只做这些条目"）、明确文件清单、只做例行移动 + import 修正——不顺手改别的——通过 `.env` conda 环境运行、结构化返回（`changed` / `ran` / `check` / `blockers`）。每组完成后**主 agent 亲自复核**（compileall、import 扫描、可跑的快速测试），然后提交：`star-code-architect: migrate <ids> — <summary>`，只暂存本 skill 涉及的路径。失败 → 把失败信息回传后重试 ≤2 次 → 仍失败：用 git 恢复该组路径，在迁移记录中把条目标 `blocked`，继续其他组。

#### Step C4：写出规范

1. 按 `assets/codearch_template_zh.md` 写 `metds/codearc.md`，填全各节；正文语言跟随根计划的 `language`（无计划则用对话语言）。
2. `AGENTS.md`：追加或更新 `## Code Architecture` 一节——≤10 行：一句话定位、3–5 条放置要点、"写代码前先读 `metds/codearc.md`"。只改 `AGENTS.md`；绝不新建独立的 `CLAUDE.md`。
3. `.cursor/rules/code-codearc.mdc`（`alwaysApply: true`）：同样的摘要 + 指路说明。

以上文件已存在时就地更新——不要追加重复内容。

#### Step C5：终验

`python -m compileall -q ${CODE_NAME}` 必跑；环境可用时再做 import 扫描与上游快速测试子集；README 最小 demo 在 CPU 上开销不大也跑。重型验证 → 准备好命令交给用户。如实报告验证了什么、没验证什么，附证据（AGENTS.md §11）。

#### Step C6：汇报与交棒

≤500 字：选定的仓库（附许可证说明）、落了什么在哪里、完成的改名 + 保留未改的名称数量、迁移完成/受阻、写入的规范、验证证据、待用户执行的命令。**向下游交棒：**`star-plan-executor <leaf>` 现在有代码可改了；`star-flow-status` 查看每个计划步骤的进展。

## 状态与文件规则

- 只写这些位置：`${CODE_NAME}/`、`metds/codearc.md`、`AGENTS.md` 的 `## Code Architecture` 一节、`.cursor/rules/code-codearc.mdc`。绝不碰 `metds/plans/*`。
- 溯源不可省略：上游 `LICENSE` / `CITATION*` 文件绝不删除或改写；许可证问题在确认点 1 就摆到台面，并记入 `codearc.md` §5。
- Git：每完成一个阶段或验证完一个迁移组提交一次，只 stage `${CODE_NAME}/` 与本 skill 拥有的规约文件；开工前该组待改路径必须干净（规约 §1）。
- 签出停在并非本次运行目标的执行分支上时，提交会随那个叶子一起合并：在这种分支上提交之前先说明，并提议先切回去（规约 §11）。
- 审计线索 = 逐组提交 + `codearc.md` §6 迁移记录；本 skill 不建 `wkdrs/` 运行目录——它产出代码与规范，不产出实验产物。
- 红线：涉及 CUDA 编译的环境构建、超过约 1 GB 的下载、完整测试套件、任何训练——准备好命令交给用户，绝不擅自启动。
- 改名残留清单在 `codearc.md` §7；后续改名走 `star-plan-executor` 步骤或再次运行本 skill，逐项验证。

## 对话纪律

- 只有实质选择或权限仍缺失时才通过 AskUserQuestion 一次问一个具体问题；工具不可用时退回简洁纯文本。对同一仓库、架构、迁移表或动作已有的明确授权继续有效，不重复询问。
- `UPSTREAM.md` 一律英文（事实元数据）；中文文档中专业术语保留英文。
