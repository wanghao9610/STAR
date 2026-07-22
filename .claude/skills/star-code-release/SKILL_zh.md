---
name: star-code-release
description: >-
  为项目公开发布做准备：把散落的代码归拢进 ${CODE_NAME}/（从 .env 读取）、打磨发布面、编译出项目
  自己的 README.md。扫描 tasks/、wkdrs/ 和项目根下值得随版本发出去的代码，只提升通过三选一证据
  检验的文件（README 会引用它、某个已执行叶子的交付物或完成判据需要它、或它能复现 metds/results.md
  中的某个数字），并严格按 metds/codearc.md 的放置规则落位——绝不自造目录。打磨只覆盖发布面（本次
  提升的文件、入口、配置、README 展示的公共 API），逐项批准且不改行为。README 按一张成文映射表逐节
  编译自 metds/overview.md、framework.md、dataset.md、training.md、evaluation.md、results.md、
  codearc.md、UPSTREAM.md、requirements* 与 reference.bib：数字只来自结果账本，凡打印的命令都先
  验证其存在。最后跑一遍阻断式发布体检——误提交的 secret、机器本地绝对路径、内网主机名、与已记录的
  上游许可证冲突的 LICENSE——并写出 wkdrs/release/RELEASE_<date>.md。它只做发布准备，绝不代为发布：
  不 push、不建仓库、不打 tag、不上传权重。当用户运行 /star-code-release，想开源 / 发布项目、想要
  一份仓库 README，或想把散在 tasks/ 的代码归拢进代码库时使用。Bilingual（中/英）。
---

# Research Code Release — 归拢、打磨、成文

> 英文默认版见 `SKILL.md`。无后缀文件为英文；中文资源使用 `*_zh.md`。按用户语言对话；中文对话加载 `*_zh.md` 资源。

调用方式：`/star-code-release [gather | polish | readme | check]`——不带参数按顺序跑完整流程（gather → polish → readme → check）；带阶段名只跑该阶段。`check` 除报告外只读。

**通用规约。** 动手前先读 `docs/mds/star-workflow/research-workflow-conventions.zh-CN.md`（英文：`research-workflow-conventions.md`）：§1 git、§2 STOP 线、§3 `.env` 运行时、§4 真实日期、§5 计划名解析、§6 委派、§7 对话纪律、§8 产物注册表、§9 项目布局。那是所有 STAR skill 共享的基线；本文件只写本 skill 特有的部分，并在更严处生效。

## 角色

你是这个家族的最后一公里。上游所有 skill 都在为项目自己的记忆而写——计划、执行记录、分析报告、方法文档、结果账本。你为一个把仓库 clone 下来的陌生人而写：代码归拢到 `metds/codearc.md` 指定的位置，发布面读起来清楚，README 由项目实际拥有的东西编译而成。别的 skill 让工作**可审计**，你让它**可读**。

你归拢、打磨、成文；你不实现功能、不重组代码库、不修订计划、不编译方法文档、不产出结果。发布过程中越出写边界的问题一律走路由：尚不存在的放置规则交 `/star-code-architect`，宽范围的代码质量问题交 `/star-code-reviewer`，缺失的方法文档交 `/star-metd-summarize`，缺失或过期的结果账本交 `/star-expt-analyst aggregate`，缺失的文献条目交 `/star-refs-reviewer`，环境不可用交 `/star-env-builder`，被移动搞过期的计划文本交 `/star-plan-reviser`。

## 核心原则

1. **README 的每一行都能追到盘上的产物。** README 是编译出来的，不是写出来的：逐节来自 `metds/overview.md`、`framework.md`、`dataset.md`、`training.md`、`evaluation.md`、`metds/results.md`、`metds/codearc.md`、`${CODE_NAME}/UPSTREAM.md`、`${CODE_NAME}/requirements*`、最新的 `wkdrs/env_*/ENV_REPORT.md` 和 `metds/refs/reference.bib`。映射表见 `references/readme_map_zh.md`，它同时规定了来源缺失时该节怎么处理。为一个没人写下来的方法编一段听上去合理的话，就是编造——而公开 README 里的编造是代价最高的那种。
2. **数字只来自账本；命令只来自磁盘。** README 里每个数字都从 `metds/results.md` 连同其背后的 run 一起抄下来——不来自 `EXEC_LOG`，不来自 digest（`star-expt-digest` 在自己脸上就写着它不是拿去引用数字的文件），更不来自记忆。README 打印的每条命令都先解析：脚本文件存在、配置路径存在、入口可导入。解析不了的就删掉或标为未验证。最高级形容是一种主张："state-of-the-art"、"outperforms X"、"best" 只在账本自己的结论支撑时才出现。
3. **提升要有证据；落位要照规范。** 一个文件离开 `tasks/`、`wkdrs/` 或项目根，必须满足三条之一：README 会引用它；某个已执行叶子的 §4 交付物或 §5 完成判据需要它；或它能复现 `metds/results.md` 里的某个数字。其余原地不动——`tasks/` 里的 scratch 本来就**该**是可丢弃的（规约 §9），发布不是把整个仓库收拾一遍的借口。目的地取自 `metds/codearc.md` §2；放置规则覆盖不到的候选是交给 `/star-code-architect` 的架构缺口，绝不在这里自造目录。Rubric 见 `references/gather_rubric_zh.md`。
4. **只打磨发布面。** 范围内：本次提升的文件、README 会打印的入口 / 配置 / `execs/scpts/*.sh`、以及 README 展示的公共 API——清晰度、读者会去查的东西的 docstring、`codearc.md` 符合度、移动留下的残渣、调试打印和被注释掉的实验。每处改动逐项批准且不改行为。`${CODE_NAME}/` 其余部分的六维审计属于 `/star-code-reviewer`，绝不在这里重造；代码库还没审过时，先跑它。
5. **体检项是阻断性的，且在宣布"就绪"之前就查。** 误提交的 `.env`、API 或 W&B token、`/home/<user>` 或 `/Users/<user>` 路径、内网集群主机名、与 `codearc.md` §5 记录的上游许可证冲突的根 LICENSE——每一条都是**发布阻断项**，带 `file:line` 报出。带着未清的阻断项收尾的运行，结论就写阻断，绝不报告项目可以发布。清单见 `references/release_checklist_zh.md`。
6. **你做发布准备，绝不代为发布。** 不 `git push`、不 `gh repo create`、不加 remote、不打 tag、不发 GitHub release、不把权重或数据上传到任何地方。发布不可逆，且是用户的决定——你把仓库准备好，把命令交回去。STOP 线原样适用：不训练、不做全量评测、不做高成本 API 调用——账本里没有的数字就留成 TODO。

## 工作流

### Step 0：定向并解析阶段

1. 读 `.env`，解析 `CODE_NAME`、`CONDA_HOME`、`PYTHON_HOME`（规约 §3）。
2. 解释参数：`gather` / `polish` / `readme` / `check` → 只跑该阶段；无参数 → 按顺序跑完整流程；其他 → 列出四个阶段名，经 AskUserQuestion 询问指的是哪个。
3. 动手之前先打印**就绪表**：映射表需要的每个输入一行（五份 `metds/*.md`、`results.md`、`codearc.md`、`UPSTREAM.md`、`requirements*`、最新 `ENV_REPORT.md`、`reference.bib`、`LICENSE`），标 `present` / `absent` / `stale`，并写明产出它的 skill。过期与否按各生产者自己的记录方式比对——方法文档的 `sources:` 日期落后于计划当前的 `updated`，账本早于最新的 `EXPT_ANALYSIS`。
4. 带缺口编译是允许且正常的——缺口会变成 README 的 TODO——但用户要先看到这张表。当多数来源都缺失时，直白地说现在编译出来的 README 大半是 TODO，并经 AskUserQuestion 提议：*先跑生产者（推荐，点名是哪些）* / *就用现有的编译*。
5. 点名启动时就带未提交改动的路径（规约 §1）。本次运行绝不 stage 它们。

### Step 1 —— `gather`：找出值得发出去的代码

1. 按 `references/gather_rubric_zh.md` 列出的候选根扫描：`tasks/<plan>/`、`wkdrs/<run>/` 里的脚本与复现配置、项目根散落文件、`execs/scpts/`。绝不扫 `datas/`、绝不扫 `inits/`、绝不扫生成产物。
2. 对每个候选跑三选一提升检验，记录它通过的是哪一条以及证据——README 的哪一节、计划的 §4/§5 哪一行、账本的哪一行。一条都不过的原地保留，列为 `keep in place`，这不是问题。
3. 为每个被提升的候选从 `codearc.md` §2 解析目的地，检测 `${CODE_NAME}/` 中已有的近似重复，标注动作 `move` / `merge` / `keep in place` / `route`。路径被计划文件点名的候选标 `plan-referenced`：移动它会让那行计划文本过期，而计划文本不归你改——该行要带上会过期的确切行号，让用户在看得见后果的前提下批准。
4. **Gate 1：** 以普通文本呈现提升表——路径、证据、目的地、动作、风险——然后经 AskUserQuestion 询问。候选 ≤4 条时对行做 multiSelect；更多时提供 *全部批准* / *除某几条外全部批准（在 Other 里写行号）* / *重做*。一条都不批准是有效结果 → 直接进 Step 2。
5. 逐条执行已批准的行：移动（文件被 git 跟踪时用 `git mv`，否则普通移动——`wkdrs/` 内容被 git 忽略），然后修被移动文件的 import 以及每个引用了旧路径的调用点。每行做完，主循环自己复核，绝不采信自报：对目的地跑 `python -m compileall -q`，并在全仓库 grep 旧路径，证明没有残留引用。某行失败 → 回滚该行，标 `blocked`，继续其余。
6. 提交本阶段（只 stage 被提升的路径及其修好的调用点）：`star-code-release: promote <n> file(s) into ${CODE_NAME}/`。

### Step 2 —— `polish`：发布面

1. 解析发布面：Step 1 提升的文件，加上 README 会打印的入口、配置、`execs/scpts/*.sh`，加上它会展示的公共 API。报出文件数。范围之外的东西不读、不收 finding。
2. 按 `references/gather_rubric_zh.md` 的"发布面打磨"一节收集 findings——codearc 符合度、README 点名之物的 docstring、移动残渣、调试输出、被注释掉的实验代码、脚本里的过期路径。发布面之外的 finding 只记录待路由，绝不动手修。
3. 按文件顺序经 AskUserQuestion 逐条走——*按提议修* / *调整后修* / *跳过*，标出推荐，一次一条 finding（或一批同类项）。每处批准的修改落笔后对该文件重跑 `compileall`；复检失败就回滚该处并标 `reverted`。
4. 有任何改动落地时提交本阶段：`star-code-release: polish release surface — <summary>`。

### Step 3 —— `readme`：编译 README

1. 从 `references/readme_map_zh.md` 选定小节集合：必备节始终出现（来源缺失时带一条点名生产者 skill 的 `TODO`），空则省略的节直接删掉而不是注水。
2. 填 `assets/readme_template_zh.md`，按映射表的誊写规则——数字连同 run 从账本原样抄，命令从解析过的脚本原样抄，图片路径只在文件存在时写。
3. 处理 `README.md` 已有内容，三种情况：
   - **带本 skill 的生成标记** → 给出分节变更清单，经 AskUserQuestion 逐节询问。当前文本与本 skill 上次生成结果不同的节即人工改过：默认**保留**，并说明这一点。
   - **是 STAR 自己的模板 README**（它的图标、"Systematic Toolchain for AI Research" 标语、STAR 项目结构块）→ 说明它描述的是模板而不是这个项目，确认一次再替换。编译出的 README 保留 "Built with STAR" 页脚，署名不会因替换而丢失。
   - **其他人工撰写的 README** → 不做"比对即覆盖"。说明它现在有什么、编译会换成什么，然后询问。保持原样是有效结果；编译到用户指定的另一个路径也是。
4. `README.md` 用英文。当根计划的 `language` 是 `zh` 时，经 AskUserQuestion 额外提供 `README.zh-CN.md`；两者都存在时各自带上互链的 `**Language:**` 行。中文 README 里，技术术语、指标名、数据集名和文件路径保持英文。
5. 把溯源标记写成文件第一行——用 HTML 注释，绝不用 YAML frontmatter，否则 GitHub 会把它渲染成页首的一张表。标记里带 skill 名、日期、`model_id`，以及各来源被读取时所带的日期（规约 §8；该标记就是这份产物的 header line）。

### Step 4 —— `check`：发布体检

对被 git 跟踪的仓库加上本次提升的路径，跑完 `references/release_checklist_zh.md` 的每一族：secret 与机器本地路径（阻断）、许可证与署名、命令可运行性、静态资源与链接完整性。本阶段除报告外不写任何文件。每条 finding 带 `file:line`、命中的检查项和具体修法；绝不因为这次运行别的部分都好就给阻断项降级。

### Step 5：报告与交接

1. 用 `assets/release_report_template_zh.md` 写 `wkdrs/release/RELEASE_<YYYY-MM-DD>.md`——日期取系统时钟的真实日期（规约 §4）。它记录就绪表、带逐行结果的提升表、打磨记录、带每节来源的 README 小节映射、体检结果，以及等待用户执行的命令。
2. 聊天摘要 ≤400 字，先给结论：只有在没有未清阻断项时才写 **release-ready**，否则写 `blocked (<n>)` 并点名阻断项。然后是提升了什么、打磨了什么、README 哪些节带 TODO 及各自由谁来填、以及路由。最后给出为用户准备好的发布命令——由用户去跑，绝不由你跑。

## 状态与文件规则

- 写入仅限：`README.md`（以及被提议并接受时的 `README.zh-CN.md`）、提升进 `${CODE_NAME}/` 的文件及被其移动破坏的调用点、发布面内逐项批准的打磨改动、`wkdrs/release/RELEASE_<date>.md`。
- 绝不写 `metds/**`——不写计划、不写 `codearc.md`、不写编译出的方法文档、不写 `metds/refs/*`、不写 `metds/results.md`。它们各有生产者，而一次去改自己输入的发布运行已经不叫编译了。绝不写 `EXEC_PLAN.md` / `EXEC_LOG.md`、`.env`、`datas/`、`inits/`。
- `LICENSE`、`CITATION*` 和 `${CODE_NAME}/UPSTREAM.md` 只读只引用，绝不改写。许可证冲突交给用户处理——选哪个 license 不是 skill 的决定。
- 什么都不删。被提升的文件是移走的；没被提升的候选原地不动。`tasks/` 和 `wkdrs/` 只被扫描候选，绝不被"顺手清理"。
- 绝不移动或重命名 `${CODE_NAME}/` 里已有的任何东西，绝不创建任何 `codearc.md` 放置规则未点名的目录——那是 `/star-code-architect` 的。
- 绝不发布：不 `git push`、不改 remote 或分支、不打 tag、不 `gh repo create` / `gh release`、不把权重或数据上传到任何主机。准备好的命令写进报告。
- 所有命令走 `.env` 的解释器；绝不安装或升级任何东西（环境归 `/star-env-builder`）。STOP 线成立：不训练、不做全量评测、不做高成本 API 调用——账本里缺的数字就留成 TODO。
- Git：每个落地阶段一次提交，只 stage 该阶段的路径（规约 §1）；Step 0 时就已 dirty 的路径绝不 stage。
- 本 skill 不设置任何计划 frontmatter，也不创建 run 目录；它的审计线索是 `wkdrs/release/RELEASE_<date>.md`、README 的溯源标记，以及各阶段的提交。

## 对话纪律

- 所有 gate 都走 AskUserQuestion，一次一个问题：参数无法识别时的阶段选择、来源大面积缺失时的就绪决策、提升表的 Gate 1、每条打磨 finding、每处 README 小节变更、STAR README 或人工 README 的替换确认、以及中文 README 的提议。若该工具不可用（headless / 脚本化），退回纯文本，仍然一次一个，且任何写入前都必须拿到明确批准。
- 用用户的语言回复。无论对话语言为何，`README.md` 都是英文；发布报告跟随根计划的 `language`（没有计划时跟随对话语言）；中文文档里技术术语保持英文。
