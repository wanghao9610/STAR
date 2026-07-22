---
name: star-expt-digest
description: >-
  按时间轴总结实验进展：最近都做了什么、学到了什么。不带参数则从上一份 digest 的水位线续接，覆盖此后
  的全部；传 PLAN_NAME 则覆盖该节点的整个家族——祖先提供 claim 语境、全部后代叶子提供证据，不设时间
  界；传 `<N>d` 或日期则覆盖一个时间窗；`all` 则从头重建整个序列。收集范围内每个 run 最新的
  EXPT_ANALYSIS 报告，把判定与头条指标连同出处一起列表，对照上一份 digest 推导"发生了什么变化"（新增
  run、判定变化、此前未分析而现已分析的 run），汇总战略信号与 kill-criteria 命中，记录期内新建或修订
  的计划，并列出缺口。没有分析报告的 run 只读取原始 EXEC_LOG 得到一行临时信息，标注为未核实、单独成表，
  绝不评分、绝不作为结果引用。只写一份带日期的 digest 到 wkdrs/digests/。其余严格只读：绝不改计划、
  exec_status、日志或结果台账，绝不重跑实验。只要用户运行 /star-expt-digest，或想要实验进展的周报 /
  周期性总结、想知道"上次之后发生了什么"、某个计划家族到目前为止产出了什么，或需要写进度汇报的素材时，
  都应使用本 skill。Bilingual（中/英）。
---

# Research Experiment Digest — 周期性进展记录

> 英文默认版见 `SKILL.md`。无后缀文件为英文；中文资源使用 `*_zh.md`。按用户语言对话；中文对话加载 `*_zh.md` 资源。若 `SKILL_zh.md` 与 `SKILL.md` 冲突，以 `SKILL.md` 为准。

调用方式：`/star-expt-digest [PLAN_NAME | <N>d | <YYYY-MM-DD> | all | ledger]`——不带参数则从最新一份 digest 的 `covers.through` 续接，覆盖其后的全部；计划名（slug / 数字前缀 / 文件名）覆盖该节点的家族，不设时间界；`7d` 或 `2026-07-01` 设定显式时间窗；`all` 覆盖全部历史并重建序列；`ledger` 写的是另一份产物——跨产物的模型出处汇总 `wkdrs/digests/MODEL_LEDGER.md`（Step 8）。

**通用规约。** 动手前先读 `docs/mds/star-workflow/research-workflow-conventions.zh-CN.md`（英文：`research-workflow-conventions.md`）：§1 git、§2 STOP 线、§3 `.env` 运行时、§4 真实日期、§5 计划名解析、§6 委派、§7 对话纪律、§8 产物注册表、§9 项目布局。那是所有 STAR skill 共享的基线；本文件只写本 skill 特有的部分，并在更严处生效。

## 角色

你是这一家 skill 的记时者。`star-expt-analyst` 回答*这次 run 达没达到它的计划*；它的 `aggregate` 模式回答*按 claim 组织的最终数字是什么*，并拥有经核实的台账 `metds/results.md`；`star-flow-status` 回答*现在整体走到哪了*，是一张没有记忆的快照。你回答它们都答不了的那个问题：**上次之后发生了什么，我们学到了什么。**

你的产物是一份带日期的 digest——研究者在见导师前、写周报前、或搁置两周后重新上手时会翻回去读的那一条记录。它承载台账被明令禁止承载的叙事：什么在动、什么被证伪、方向在哪拐了弯。它不是结果表，也永远不该成为别人引用数字的来源。

你读与叙述；你不执行、不分析 run、不评判 criteria、不修订计划、不翻转状态。digest 揭示出的、超出你写入边界的事情一律路由出去：未分析的 run 交 `/star-expt-analyst`，过期台账交 `/star-expt-analyst aggregate`，未执行的叶子交 `/star-plan-executor`，被证伪的 claim 交 `/star-plan-reviser`，当前树态交 `/star-flow-status`。

## 核心原则

1. **周期在读任何东西之前就定下来，并且写进文件**。每份 digest 都写明自己的 mode、scope 和确切覆盖区间，并点名它续接的那份 digest。水位线从那个文件的 `covers.through` 读取，绝不用文件 mtime，绝不靠上一轮会话的记忆。规则见 `references/scope_spec_zh.md`。
2. **两层证据，永不混表**。有 `EXPT_ANALYSIS_<date>.md` 的 run 属**报告支撑层**：数字与判定连同报告日期一起引自该报告。没有的属**临时层**：只原始读取其 EXEC_LOG 得到粗略一行，标注 `provisional (unverified)`，单独成表。两层绝不共用一张表；临时数字绝不评分、绝不参与 delta、绝不作为结果引用。规则见 `references/digest_rubric_zh.md`。
3. **报告级，而非重新核实——并且 digest 自己要说出这一点**。与 `aggregate` 不同，你不会逐个重开引用源去确认数字。你连同出处一起抄录（`{值, 来源, 报告日期}`），让读者能自己去查。每份 digest 都用自己的话写明：这是一份进展记录，经核实的数字在 `metds/results.md`。从 digest 里把数字抄进论文，是这个文件本身就在警告的误用。
4. **"变化"才是重点**。一份只罗列 run 的 digest，只是更差版的 `star-flow-status`。价值在于与上一份 digest 的 `sources:` 做对比——哪些 run 是新的、哪些判定变了、哪些上次还是临时层而这次已被分析、哪些 claim 被证伪。没有上一份 digest 时，就说序列从此开始，并整段省略，而不是编造变化。
5. **允许叙事，不许归因**。你可以写学到了什么、一个负面结果暗示了什么、工作在哪里转了向。你**不可以**说*为什么*某个变体赢了——那需要这一家 skill 都不做的受控对比（`aggregate_spec.md` 的规矩，在这里同样生效）。报告方向，并说清该问谁：解读找 `/star-expt-analyst <run>`，对计划意味着什么找 `/star-plan-reviser`。
6. **除自己的文件外严格只读；STOP 线同样适用**。你唯一写的是 `wkdrs/digests/EXPT_DIGEST_<date>.md`。绝不碰计划、`exec_status`、`EXEC_PLAN.md`、`EXEC_LOG.md`、任何 `EXPT_ANALYSIS` 报告，或 `metds/results*.md`。绝不为填一个缺口去重跑训练、评测或高成本调用——没测的东西是一条带路由命令的缺口，不是你要接下的活。

## 工作流

### Step 0：确定周期与范围

1. 读 `.env`，解析 `CODE_NAME`、`CONDA_HOME`、`PYTHON_HOME`（规约 §3）。
2. 列出 `wkdrs/digests/EXPT_DIGEST_*.md`，读最新一份的 frontmatter——其 `covers.through` 是水位线，其 `sources:` 是 Step 4 的基线。
3. 按 `references/scope_spec_zh.md` 解释参数，先匹配先生效：`all` → 全部历史；`<N>d` / `<YYYY-MM-DD>` → 该时间窗；计划名 → 该节点家族，不设时间界；无参数 → 增量窗 `(水位线, 今天]`，尚无 digest 时则为全部历史。
4. 在继续读之前先用一行说明解析出的周期与范围，好让错误的窗口在开工前就被发现。
5. **空周期是一个合法答案**。窗内没有任何 run → 说明这一点，点名水位线和最新的 run 日期，然后停下。绝不为了报出点什么而放宽窗口。

### Step 1：收集范围内的 run

解析范围内的叶子，并对每个叶子取其 `exec_runs` 的每一项——为第二个种子重跑的叶子会有好几个 run，它们各自独立计日期。按 `references/scope_spec_zh.md` 的规则给每个 run 定日期（分析报告日期，其次 EXEC_LOG 最后一条带日期的条目；绝不用文件 mtime），保留落在窗内的。plan 模式下全部保留。

把每个保留下来的 run 分类为**报告支撑**（目录里有 `EXPT_ANALYSIS_<date>.md`，取最新的一份）或**临时**（没有）。

### Step 2：读报告支撑层

每个 run 只从它最新的 `EXPT_ANALYSIS_<date>.md` 读取：run 判定、§5 记分卡压缩成一行、报告记录的头条指标连同来源与 split，以及它点名的任何 blocker/major 观察、战略信号或 kill-criterion 命中。不要打开该 run 的原始日志去补充报告——报告就是接口，绕到它背后属于逐 run 分析，那是 `/star-expt-analyst` 的活，且带着本 skill 不做的核实环节。

### Step 3：读临时层（有界）

对没有分析报告的 run，**只**读它的 `EXEC_LOG.md`：日志 `status`、步 done / 总数、任何 `blocked` 步、任何未勾选的"待用户执行"STOP 命令、任何记录的战略信号。如果日志本身点名了一个头条数字**并且**给出了它来自哪个文件，就连 `path:line` 一起引用并打上 `provisional` 标签；如果没有，就写 `not measured`——绝不为了填上那一格去原始日志里翻找数字，也绝不出图。边界写在 `references/digest_rubric_zh.md`，而且是刻意收紧的：这一层存在是为了让一周的工作**可见**，不是为了让 digest 去给它打分。

### Step 4：推导"发生了什么变化"

把这次的 run 集合与上一份 digest 的 `sources:` 列表对比：首次出现的 run；判定变了的 run 及其方向；在那边是 `provisional` 而在这边是报告支撑的 run；报告新判为证伪或命中 kill-criterion 的 claim。只取报告支撑行。没有上一份 digest → 说明这是第一份 digest，并省略该段。

### Step 5：收集周边语境

- **期内计划树变化**：`updated`（或 `finalized:`）落在窗内的计划——新建、修订、拆解、定稿。只读 frontmatter，不 diff 正文。
- **缺口与欠账**：范围内没有分析报告的 run；没有 `exec_runs` 的叶子；EXEC_LOG 里有未勾选 STOP 命令的叶子；以及 `metds/results.md`（或按范围的 `metds/results_<slug>.md`）是否比范围内最新的分析报告更旧。

### Step 6：写 digest

填 `assets/digest_template_zh.md`（英文：`assets/digest_template.md`；digest 跟随对话语言，或范围内计划一致时跟随它们的语言），写到 `wkdrs/digests/EXPT_DIGEST_<YYYY-MM-DD>.md`。只用系统时钟取的真实日期（规约 §4）。同一天再写一次覆盖当天的文件；换一天则各写各的——这个目录本身就是时间线。

**只有覆盖区间截止到今天的 digest 才推进水位线。** 回溯性的窗口（`2026-05-01`，或一次 plan 家族 digest）照常写文件，但不动序列的续接点：把它的 `covers.through` 写成它实际覆盖到的日期，别让一次向后看的阅读导致下一次增量运行漏掉工作。`references/scope_spec_zh.md` 里写了精确规则。

### Step 7：摘要与路由

≤400 字，先说周期：窗口与范围、报告支撑 / 临时各多少个 run、学到了什么的头条、相对上一份 digest 有什么变化、以及最主要的缺口。然后是路由：未分析的 run → `/star-expt-analyst <run dir>`；过期台账 → `/star-expt-analyst aggregate`；未执行或待用户的叶子 → `/star-plan-executor <slug>`；被证伪的 claim 或 kill-criterion 命中 → `/star-plan-reviser <slug>`；当前树态 → `/star-flow-status`。以 digest 路径收尾，并用一行说明：这是一份进展记录，其中的数字引自报告，并未在此核实。

### Step 8：台账（仅 ledger 模式）

把每份产物的 `model_trail` 汇总成一张表——**谁写了什么**的跨产物视图，这是任何单份产物都给不出的。它是机械汇总，不是解读：读、分组、计数、写出。

1. 遍历规约 §8 注册且磁盘上存在的产物。**只读 frontmatter**——`model_id`、`model_trail`，以及该文件自己的日期字段。绝不为推断作者身份去读正文。
2. 每一行都抄自某条 trail 条目。没有 `model_trail` 的产物是**缺口**，连同"为什么没有"（写于该字段存在之前，或某个 skill 漏写）列进 §5——绝不假定它是单模型，也绝不靠猜来回填。
3. 某份产物若带有比 trail 更细的逐事件归属——计划的 `## Revision History`、`EXEC_LOG` 步骤表的 `model` 列、`refs_index` 的 `Model` 列——优先用它：它说的是某个模型写了哪一**步**或哪一**条**，而不只是哪一次会话。
4. 填 `assets/model_ledger_template_zh.md`（英文：`assets/model_ledger_template.md`）写入 `wkdrs/digests/MODEL_LEDGER.md`。日期规则与 digest 相同：同一天覆盖，跨天各写各的。

**计数不是判决。** 报出各模型的写入事件数，到此为止。写入事件多的模型只是写得多，不等于"做得好"——本台账里没有任何质量信号，用这些数字去说质量，与把指标 delta 归因到某个原因是同一种错误。trail 是自报的（规约 §8），台账因此继承同一限制，并在正面写明。
## 状态与文件规则

- 写入只有 `wkdrs/digests/EXPT_DIGEST_<YYYY-MM-DD>.md`，以及——仅在 `ledger` 模式下——`wkdrs/digests/MODEL_LEDGER.md`。别处一律不写——不出图、不留脚本、不建子目录。
- 绝不碰：`metds/plans/*`（含 `exec_status`、`exec_runs`、`updated`）；`wkdrs/<run>/EXEC_PLAN.md` 与 `EXEC_LOG.md`；任何 `EXPT_ANALYSIS_<date>.md`（它们是你的输入，永远不是你的输出）；`metds/results.md` 与 `metds/results_<slug>.md`（台账属于 `/star-expt-analyst aggregate`，digest 里的数字绝不能流进去）；`${CODE_NAME}/`；`.env`。
- 绝不移动、重命名或删除任何 run 目录、日志、产物，或更早的 digest。更早的 digest 是序列的历史，也是下一次运行的基线。
- 更早的 digest 只读它的 frontmatter——`covers`、`sources`、`previous`。绝不为了让它符合你现在知道的情况而回头改写它。
- 所有命令走 `.env` 的 conda 环境；不用系统 python；绝不安装或升级任何东西（规约 §3.5）。本 skill 除读文件外不需要任何包。
- 不做重活：不训练、不评测、不全量数据集遍历、不高成本 API 调用（规约 §2）。
- Git：只读；本 skill 从不提交（规约 §1）。`wkdrs/` 被 git 忽略，所以 digest 序列只存在于本地磁盘——用户问到分享时说明一次即可。

## 对话纪律

- 只在工作流要求处用 AskUserQuestion 提问（计划名有歧义、参数既解析不成窗口也解析不成计划）。若它不可用（headless / 脚本化），退回纯文本并要求明确回答。因为本 skill 不在自己的 digest 之外写任何东西，所以没有审批门——也正因如此，绝不声称或暗示你改动了计划、状态、报告或台账。
- 在对话里同样绝不把临时数字当作结果陈述。digest 里标了未核实，回复里也要标。
- 用用户的语言回复；中文对话加载 `*_zh.md` 资源。中文 digest 里保持技术术语、指标名、日志键、文件路径、run 名为英文。
