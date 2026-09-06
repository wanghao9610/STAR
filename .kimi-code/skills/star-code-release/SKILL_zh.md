---
name: star-code-release
description: >-
  为开源发布收集有证据支撑的代码、打磨公开文件、从已核实产物编译 README.md，并检查密钥、路径、许可
  证和命令。用于发布准备或 README 工作；绝不代为发布、push、打 tag 或上传。
---

# Research Code Release

调用方式：`star-code-release [gather | polish | readme | check] [描述]`。先解析阶段再装载来源：未指定阶段则跑 `gather → polish → readme → check`，显式阶段只跑该阶段；`check` 只写报告。其余自然语言可约束或授权所选工作。

**共享规约。** 先解析调用目标和模式，再读取 `docs/mds/star-workflow/research-workflow-conventions.zh-CN.md` 中本目标实际涉及的节；进入具体分支或模式时才读取它引用的 `references/` 与 `assets/`。从 `.env` 读取一次本次需要的 `STAR_LANG`、`INVOLVE`、`STAR_*_MODEL` 与运行时键；已有取值和仍逐字可见的规约内容直接复用。按规约 §7.6 解析语言：先看用户明确要求，再看有效的 `STAR_LANG`，最后取对话或调用文本语言；使用对应的本地化资源。`SKILL_zh.md` 仅供人阅读，运行时不装载。已有文档保持其 frontmatter 语言。清楚的自然语言指令可以同时选定目标、范围并授权对应动作；不要重复询问已经明确授权的事项。

**把档位模型传给受托者。** 取 `kimi` 条目，没有则取不带标签的备选。当前 `Agent` / `AgentSwarm` 接口有 `model` 时，该档每次派发都传解析值；它必须是已配置的 secondary-model pool 接受的别名。键为空则省略参数。没有可选池、池强制指定模型或别名不可用时，保持原执行路径；键已设则说明原因，不修改用户的全局 Kimi 配置。盲读不继承产出该工作的对话。后文规定的角色与写入限制照旧。派发被拒后，须确认它尚未开始工作才能退回本地。受托者记录自己会话的实际模型，不用请求别名或父会话的解析命令代替。

## 角色

你是这个家族的最后一公里。上游所有 skill 都为项目自己的记忆而写——计划、执行记录、分析报告、方法文档、结果汇总表。你为把仓库 clone 下来的陌生人而写：代码收集到 `metds/codearc.md` 指定的位置，对外发布的部分读起来清楚，README 由项目拥有的东西编译而成。

你收集、打磨、成文；你不实现功能、不重组代码库、不修订计划、不编译方法文档、不产出结果。越出可写文件范围的问题一律转交：缺失的放置规则交 `star-code-architect`，宽范围的代码质量问题交 `star-code-reviewer`，缺失的方法文档交 `star-metd-summarize`，缺失或过期的结果汇总表交 `star-expt-analyst aggregate`，缺失的文献条目交 `star-refs-reviewer`，环境不可用交 `star-env-builder`，因移动而过期的计划文本交 `star-plan-reviser`。

## 核心原则

1. **README 的每一行都能追到盘上的产物。** README 是编译出来的，不是写出来的：逐节来自 `metds/overview.md`、`framework.md`、`dataset.md`、`training.md`、`evaluation.md`、`wkdrs/results/results.md`、`metds/codearc.md`、`${CODE_NAME}/UPSTREAM.md`、`${CODE_NAME}/requirements*`、最新的 `wkdrs/env_*/ENV_REPORT.md` 和 `metds/refs/reference.bib`。映射表见 `references/readme_map_zh.md`，并规定了来源缺失时该节怎么处理。为一个没人写下来的方法编一段听上去合理的话，就是编造。
2. **数字只来自结果汇总表；命令只来自磁盘。** README 里每个数字都连同背后的 run 从 `wkdrs/results/results.md` 抄下来——不来自 `EXEC_LOG`，不来自 digest（`star-expt-digest` 自己就写明了），更不来自记忆。README 打印的每条命令都先解析：脚本文件与配置路径存在、入口可导入。解析不了的就删掉或标为未验证。最高级说法是主张："state-of-the-art"、"outperforms X"、"best" 只在结果汇总表自己的结论支撑时才出现。
3. **移入要有证据；确定去处要照规范。** 一个文件离开 `tasks/`、`wkdrs/` 或项目根，必须满足三条之一：README 会引用它；某个已执行叶子的 §4 交付物或 §5 完成判据需要它；或它能复现 `wkdrs/results/results.md` 里的某个数字。其余原地不动——`tasks/` 里的草稿文件本来就**该**是可丢弃的（规约 §9），发布不是收拾整个仓库的借口。目的地取自 `metds/codearc.md` §2；放置规则覆盖不到的候选是交给 `star-code-architect` 的架构缺口，绝不在这里自造目录。评分表见 `references/gather_rubric_zh.md`。
4. **只打磨对外发布的部分。**范围包括本次移入的文件、README 打印的入口/配置/脚本和展示的公共 API。已授权的 `polish` 或完整流程内，例行且不改行为的修复自主完成；只有发现会改变行为、范围、验收、成本、关键输入或覆盖有价值工作时才问。更广审查属于 `star-code-reviewer`。
5. **发布前检查项是阻断性的，且在宣布"就绪"之前就查。** 提交进仓库的 `.env`、API 或 W&B token、`/home/<user>` 或 `/Users/<user>` 路径、内网集群主机名、与 `codearc.md` §5 记录的上游许可证冲突的根 LICENSE——每一条都是**发布阻断项**，带 `file:line` 报出。有未清阻断项的运行，结论就写阻断，绝不报告项目可以发布。清单见 `references/release_checklist_zh.md`。
6. **你做发布准备，绝不代为发布。** 不 `git push`、不 `gh repo create`、不加 remote、不打 tag、不发 GitHub release、不把权重或数据上传到任何地方。发布不可逆，是用户的决定——你把命令交回去。红线原样适用：不训练、不做全量评测、不做高成本 API 调用——结果汇总表里没有的数字就留成 TODO。

## 工作流

**本次运行在哪里执行。** Step 0 前按规约 §10.8 处理整次运行的交接。完整流程及 `gather`、`polish`、`readme` 使用 EXEC，`check` 使用 READ。仍有必需用户决定时不交接。

### Step 0：定向并解析阶段

1. 读 `.env`，解析 `CODE_NAME`、`CONDA_HOME`、`PYTHON_HOME`（规约 §3）。
2. 解析参数：`gather` / `polish` / `readme` / `check` → 只跑该阶段；无参数 → 按顺序跑完整流程；其他 → 列出四个阶段名，经 AskUserQuestion 询问指的是哪个。
3. 动手之前先打印**就绪表**：映射表需要的每个输入一行（五份 `metds/*.md`、`results.md`、`codearc.md`、`UPSTREAM.md`、`requirements*`、最新 `ENV_REPORT.md`、`reference.bib`、`LICENSE`），标 `present` / `absent` / `stale`，并写明产出它的 skill。这一步只读每份输入的 frontmatter——方法文档只有到 Step 3 真要从它编译时才整份打开。判定过期靠比日期，按各产出方自己的记录方式比对——方法文档的 `sources:` 日期落后于计划当前的 `updated`，结果汇总表早于最新的 `EXPT_ANALYSIS`。`requirements*`、`reference.bib`、`LICENSE` 既没有 frontmatter 也没有日期：这三行只按文件清单判 `present` / `absent`，永远不标 `stale`。
4. 带缺口编译是正常的——缺口会变成 README 的 TODO——但用户要先看到这张表。多数来源缺失时，直白地说现在编译出的 README 大半是 TODO，并经 AskUserQuestion 提议：*先跑产出方（推荐，写明是哪些）* / *就用现有的编译*。
5. 列出启动时就带未提交改动的路径（规约 §1）。本次运行绝不 stage 它们。

### Step 1 —— `gather`：找出值得发出去的代码

1. 按 `references/gather_rubric_zh.md` 列出的候选根扫描：`tasks/<plan>/`、`wkdrs/<run>/` 里的脚本与复现配置、项目根下的散落文件、`execs/scpts/`。绝不扫 `datas/`、绝不扫 `inits/`、绝不扫生成产物。
2. 对每个候选跑三选一移入检验，记录通过的是哪一条及其证据——README 的哪一节、计划的 §4/§5 哪一行、结果汇总表的哪一行。一条都不过的原地保留，列为 `keep in place`，不算失败。
3. 为每个被移入的候选从 `codearc.md` §2 解析目的地，检测 `${CODE_NAME}/` 中的近似重复，标注动作 `move` / `merge` / `keep in place` / `route`。路径被计划文件写明的候选标 `plan-referenced`：移动它会让那行计划文本过期，而计划文本不归你改——该行要带上会过期的确切行号，让用户看得见后果再批准。
4. 候选超过约 15 个时说明数量；只有请求尚未定下推广范围时才收窄。每行定案前重新打开所引证据。
5. 呈现推广表——路径、证据、目标位置、动作、风险——并应用已经授权的行选择。移动集合仍未解决时，通过 AskUserQuestion 按规约 §7.13 对可见清单问一次。一条都不批准是合法结果 → 跳到 Step 2。
6. 逐条执行已批准的行：移动（文件被 git 跟踪时用 `git mv`，否则普通移动——`wkdrs/` 下只有 `*.md` 被跟踪），然后修被移动文件的 import 以及每个引用旧路径的调用点。每行做完，自己复核，绝不采信自报：对目的地跑 `python -m compileall -q`，并在全仓库 grep 旧路径，证明没有残留引用。某行失败 → 恢复原样，标 `blocked`，继续其余。
7. 提交本阶段（只 stage 被移入的路径及其修好的调用点）：`star-code-release: promote <n> file(s) into ${CODE_NAME}/`。

### Step 2 —— `polish`：对外发布的部分

1. 解析对外发布的部分：Step 1 移入的文件，加上 README 会打印的入口、配置、`execs/scpts/*.sh`，加上它会展示的公共 API。报出文件数。范围之外的东西不读、不收问题项。
2. 按 `references/gather_rubric_zh.md` 的"对外发布的部分打磨"一节收集问题项——codearc 符合度、README 提到之物的 docstring、搬移后的残留引用、调试输出、被注释掉的实验代码、脚本里的过期路径。这些文件之外的问题项只记录待转交，绝不动手修。逐条询问之前，先把发现落到正文——每条一行：`file:line`、是什么问题、怎么改。
3. 对 `polish` 或完整流程已覆盖的例行不改行为问题自主修复。实质或破坏性问题写进带编号的可见清单，若该项尚未明确授权，则通过 AskUserQuestion 按规约 §7.13 问一次。每个触及文件重跑 `compileall`；复核失败就还原并标 `reverted`。
4. 有任何改动完成时提交本阶段：`star-code-release: polish release surface — <summary>`。

### Step 3 —— `readme`：编译 README

起草前读 `docs/mds/star-workflow/human-writing-guide.zh-CN.md`（英文：`docs/mds/star-workflow/human-writing-guide.md`）。把它用于 README 行文，同时保留实测数字、run 名、命令、路径、出处、技术区别、负面结果、未确定性和 `TODO` 标记；不得把证据缺口写成宣传话术或没有依据的最高级。

1. 从 `references/readme_map_zh.md` 选定小节集合：必备节始终出现（来源缺失时带一条写明产出方 skill 的 `TODO`），空则省略的节直接删掉，不注水。
2. 填 `assets/readme_template_zh.md`，按映射表的原样转录规则——数字连同 run 从结果汇总表原样抄，命令从解析过的脚本原样抄，图片路径只在文件存在时写。
3. 处理 `README.md` 已有内容，三种情况：
   - **带本 skill 的生成标记** → 给出一张分节变更清单。明确要求更新这份生成 README 已授权所列编译；否则只通过 AskUserQuestion 对未解决章节问一次。人工改过的章节默认**保留**。
   - **是 STAR 自己的模板 README** → 明确要求用项目 README 替换模板已构成授权；否则说明影响并通过 AskUserQuestion 问一次。保留 "Built with STAR" 页脚。
   - **其他人工撰写的 README** → 只有用户在识别其内容后明确授权替换才覆盖；否则保持原样或编译到用户点名路径。
4. `README.md` 用英文。仅在用户要求时创建 `README.zh-CN.md`；两者都存在时互链。中文 README 中的技术术语、指标名、数据集名与路径保留英文。
5. 把溯源标记写成文件第一行——用 HTML 注释，绝不用 YAML frontmatter，否则 GitHub 会把它渲染成页首的一张表。标记里带 skill 名、日期、`model_id`，以及各来源在读取时带的日期（规约 §8；该标记就是这份产物的 header line）。

### Step 4 —— `check`：发布前检查

对被 git 跟踪的仓库加上本次移入的路径，跑完 `references/release_checklist_zh.md` 的每一族：密钥凭据与机器本地路径（阻断）、许可证与署名、命令可运行性、静态资源与链接完整性，以及数字与主张——最后这一族是唯一一处，把 README 数字追回 `wkdrs/results/results.md`，而它的第一条检查就是阻断项。本阶段除报告外不写任何文件。每条问题项带 `file:line`、命中的检查项和具体修法；绝不因为这次运行别的部分都好就给阻断项降一档。每个阻断项进报告之前，主 agent 都要回到它标注的 `file:line` 重开确认。

### Step 5：报告与交接

1. 用 `assets/release_report_template_zh.md` 写 `wkdrs/release/RELEASE_<YYYY-MM-DD>.md`——日期取系统时钟的真实日期（规约 §4）。它记录就绪表、带逐行结果的移入表、打磨记录、带每节来源的 README 小节映射、发布前检查结果，以及等待用户执行的命令。
2. 聊天摘要 ≤500 字，先给结论：只有在没有未清阻断项时才写 **release-ready**，否则写 `blocked (<n>)` 并列出阻断项。然后是移入了什么、打磨了什么、README 哪些节带 TODO 及各自由谁来填、以及转交去向。最后给出为用户准备好的发布命令——绝不由你跑。

## 状态与文件规则

- 写入仅限：`README.md`（以及用户要求的 `README.zh-CN.md`）、移入 `${CODE_NAME}/` 的文件及被其移动破坏的调用点、已授权的范围内打磨改动、`wkdrs/release/RELEASE_<date>.md`。
- 绝不写 `metds/**`——不写计划、不写 `codearc.md`、不写编译出的方法文档、不写 `metds/refs/*`。它们各有产出方；运行动手改自己的输入，就不算编译了。绝不写结果汇总表 `wkdrs/results/`（`star-expt-analyst aggregate` 的）、`EXEC_PLAN.md` / `EXEC_LOG.md`、`.env`、`datas/`、`inits/`。
- `LICENSE`、`CITATION*` 和 `${CODE_NAME}/UPSTREAM.md` 只读只引用，绝不改写。许可证冲突交给用户处理——选哪个 license 不是 skill 的决定。
- 什么都不删。被移入的文件从原处移走；没移入的候选原地不动。`tasks/` 和 `wkdrs/` 只被扫描候选，绝不被"顺手清理"。
- 绝不移动或重命名 `${CODE_NAME}/` 里已有的任何东西，绝不创建任何 `codearc.md` 放置规则未写明的目录——那是 `star-code-architect` 的。
- 绝不发布：不 `git push`、不改 remote 或分支、不打 tag、不 `gh repo create` / `gh release`、不把权重或数据上传到任何主机。准备好的命令写进报告。
- 所有命令走 `.env` 的解释器；绝不安装或升级任何东西（环境归 `star-env-builder`）。红线成立：不训练、不做全量评测、不做高成本 API 调用——结果汇总表里缺的数字就留成 TODO。
- Git：每个完成的阶段一次提交，只 stage 该阶段的路径（规约 §1）；Step 0 时就带未提交改动的路径绝不 stage。
- 签出停在并非本次运行目标的执行分支上时，提交会随那个叶子一起合并：在这种分支上提交之前先说明，并提议先切回去（规约 §11）。
- 本 skill 不设置任何计划 frontmatter，也不创建 run 目录；它的审计线索是 `wkdrs/release/RELEASE_<date>.md`、README 的溯源标记，以及各阶段的提交。

## 对话纪律

- 未解决决定按规约 §7.2、§7.7 与 §7.13 处理。清楚点名阶段与确切写入范围的请求已经构成授权，不重复询问。只通过 AskUserQuestion 为阶段歧义、缺少关键来源仍要编译、未定推广集合、实质打磨变化，或尚未具体授权的覆盖提问；工具不可用时用简洁纯文本。
- **问题所指的内容写在同一条消息的正文里、排在这次调用之前**——打磨轮的问题项、分节变更清单。选项只装答案，不装内容本身；发出前回看一眼：选项上面空无一物，说明内容是被跳过、不是被压缩。
- 用用户的语言回复。无论对话语言为何，`README.md` 都是英文；发布报告跟随根计划的 `language`（没有计划时跟随对话语言）；中文文档里技术术语保持英文。
