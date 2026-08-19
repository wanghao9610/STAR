---
name: star-expt-digest
description: >-
  按时间顺序总结实验进展。不带参数从上一份 digest 续接；传 PLAN_NAME 覆盖该节点的整个家族；传 `<N>d` 或日期覆盖一个时间窗；`all` 从头重建。收集范围内每个 run
  最新的分析报告，把判定与关键指标连同出处一起列表，只写一份带日期的 digest 到 wkdrs/digests/。当用户运行
  /skill:star-expt-digest，或需要写进度汇报的素材时使用。Bilingual（中/英）。
---

# Research Experiment Digest — 周期性进展记录

> 本文件是 `SKILL.md` 的中文对照版，随英文版同步维护，供人阅读；运行时不装载它——指令以 `SKILL.md` 为准，中文对话按规约 §7.6 用中文回复，并把开场装载与各步骤点名的资源换成 `_zh` / `.zh-CN` 版本（中文措辞以规约 §0 词汇表为准）。若两版冲突，以 `SKILL.md` 为准。

调用方式：`/skill:star-expt-digest [PLAN_NAME | <N>d | <YYYY-MM-DD> | all | ledger] [描述]`——不带参数则从最新一份 digest 的 `covers.through` 续接，覆盖其后的全部；计划名（slug / 数字前缀 / 文件名）覆盖该节点的家族，不设时间界；`7d` 或 `2026-07-01` 设定显式时间窗；`all` 覆盖全部历史并重建序列；`ledger` 写的是另一份产物——跨产物的模型出处汇总 `wkdrs/digests/MODEL_LEDGER.md`（Step 8）。其后剩下的一切都是描述（规约 §7.12）：用你自己的话说明这次要做什么。既不是模式词、也解析不到计划的成句文本只是描述，不是漏掉的参数——照不带参数那样从最新一份 digest 的 `covers.through` 续接，并在动笔之前说明这一点。既解析不成时间窗、也解析不成计划的孤立词不是描述，它仍然是本 skill 要问清的那个歧义。描述可以引导 digest 强调什么，但不会放宽或收窄参数定下的时间窗。

**通用规约。** `docs/mds/star-workflow/research-workflow-conventions.zh-CN.md`（英文：`research-workflow-conventions.md`）是所有 STAR skill 共享的基线；本文件只写本 skill 特有的部分，并在更严处生效。摘要真正据以行事的部分——§0 词汇表（"上次覆盖到的日期"、方向性信号，以及本 skill 要汇报的 kill-criterion 与完成判据都在这里定义）、§3 `.env` 运行时、§5 计划名解析、§6 委派、§7 对话纪律、§8 产物登记表——随下面这次开场装载到达。有六节不装载，每一节都是因为本 skill 自己的文件已在用到它的地方写清了所需内容：§1 git（本 skill 从不提交——见状态与文件规则，连要告诉用户的 `wkdrs/*.md` 例外也在那里）、§2 红线（本 skill 什么都不跑——核心原则 6 与 `references/digest_rubric_zh.md` 划定了边界，日志里"待用户"的命令只是照抄标题转述，从不由它判断）、§4 真实日期（Step 6，且扫描脚本本身就会打印当天日期）、§9 项目布局（状态与文件规则把可写文件范围列得比 §9 更严）、§10 skill 名册（这次运行能不能不经点名启动，在本文件打开之前就已定夺；这种运行随身的义务在对话纪律一节有复述），以及 §11 执行分支（未合并的分支在本 skill 里永远只是缺口清单里的一行：开场那次调用带回的清单承载它，digest 既不合并、也不弃用任何东西）。规约的前言同样不装载——它那条优先级规则（基线与更严者的关系）就是本段开头写的那一条。哪次运行真需要其中某节，再整份读回。

动手前，用一条消息装齐本 skill 全部无条件的开场读取——也就是本文件后文回指的那次开场装载：三次 bash 调用（以项目根目录为工作目录），外加 `<本 skill 所在目录>/references/scope_spec_zh.md` 的一次 `read`，三者同发。

```bash
grep -sE '^(STAR_LANG|INVOLVE)=' .env || echo 'STAR_LANG / INVOLVE: unset'   # reply language, question level (§7.6, §7.7)
git branch --list '[0-9]*_*' 2>/dev/null   # 带未合并 run 的执行分支——缺口与欠账那一行读的就是这份清单
awk '/^## /{k=/^## (0|3|5|6)\./} k' docs/mds/star-workflow/research-workflow-conventions.zh-CN.md
```

```bash
awk '/^## /{k=/^## (7|8)\./} k' docs/mds/star-workflow/research-workflow-conventions.zh-CN.md
```

```bash
bash <本 skill 所在目录>/scripts/scan.sh
```

一条消息、四份结果：`.env` 探测与规约前半来自第一次调用，规约其余各节来自第二次，收集脚本的摘要来自第三次（它打印什么、为什么，见工作流一节），Step 0 据以解释参数的 spec 来自它自己那次 `read`。三次 bash 调用分开发，是因为每份工具结果各有自己的大小上限：结果一旦超过 30 KB 左右就会被存成文件，要再读一次才拿得回来——那正是"一条消息装齐"本来要省掉的那趟往返——而规约摘录合计约 30 KB（分成约 13 与 17 的两次调用），整份挤进同一份结果现在就会过线，扫描摘要还要再占一份。每行 `awk` 只打印它上面点名的那几节，别的都不打印；若打印出来的内容里少了其中任何一节——下游同步的规约副本可能过旧、条号不同——就改为整份读入。`ledger` 模式去掉 spec 的那次 `read`，扫描改跑 `bash <本 skill 所在目录>/scripts/scan.sh --trails`——Step 8 不解析时间窗，spec 在那里用不上；`--trails` 多打印什么、少打印什么，工作流一节写了。其余一律按需加载：`references/digest_rubric_zh.md` 到 Step 2–3 应用分层规则时再读，`assets/` 模板到 Step 6 或 Step 8 写文件时再读，扫描的第二次 `--bodies` 调用必须等 Step 1 点名窗口内的 run 之后——为什么不能提前，工作流一节也写了。

**复用上一次装载。** 同一轮对话里的第二个 STAR skill 不必把开场装载再付一次。上面那份装载里，凡是文本此刻仍能在本轮对话中逐字看到的部分就跳过不读——同一份规约文件、同一种语言、至少覆盖本文件点名的那些节，同样的参考文件，以及那次 `.env` 探测取到的 `STAR_LANG` / `INVOLVE` 取值。看不到的部分照旧读，仍用上面那一条消息发出。两种情况不算看得到：上下文压缩后只剩摘要而正文已经不在；以及只记得自己读过。拿不准就重读一遍——多读一次只花一条消息，判断错了要赔上整轮运行。唯独采集脚本的摘要不能这样复用（上面装载了它的话）：它是文件在某一刻的快照，而其间可能已有 skill 写过盘，所以每次都重新跑一次扫描。若整份装载都已在手，开场那条消息就整个省掉；若只剩扫描一项，就让它单独发出。

## 角色

你是这一家 skill 的记时者。`star-expt-analyst` 回答*这次 run 达没达到它的计划*；它的 `aggregate` 模式回答*按主张组织的最终数字是什么*，并拥有经核实的结果汇总表 `wkdrs/results/results.md`；`star-flow-status` 回答*现在整体走到哪了*，是一张没有记忆的快照。你回答它们都答不了的那个问题：**上次之后发生了什么，我们学到了什么。**

你的产物是一份带日期的 digest——研究者在见导师前、写周报前、或搁置两周后重新上手时会翻回去读的那一条记录。它承载结果汇总表被明令禁止承载的叙事：什么在动、什么被证伪、方向在哪拐了弯。它不是结果表，也永远不该成为别人引用数字的来源。

你读与叙述；你不执行、不分析 run、不评判 criteria、不修订计划、不翻转状态。digest 揭示出的、超出你可写文件范围的事情一律转交出去：未分析的 run 交 `/skill:star-expt-analyst`，过期的结果汇总表交 `/skill:star-expt-analyst aggregate`，未执行的叶子交 `/skill:star-plan-executor`，被证伪的主张交 `/skill:star-plan-reviser`，当前树态交 `/skill:star-flow-status`。

## 核心原则

1. **周期在读任何东西之前就定下来，并且写进文件**。每份 digest 都写明自己的 mode、scope 和确切覆盖区间，并写明它续接的那份 digest。上次覆盖到的日期从那个文件的 `covers.through` 读取，绝不用文件 mtime，绝不靠上一轮会话的记忆。规则见 `references/scope_spec_zh.md`。
2. **两层证据，永不混表**。有 `EXPT_ANALYSIS_<date>.md` 的 run 属**有报告依据的层**：数字与判定连同报告日期一起引自该报告。没有的属**未核实层**：只原始读取其 EXEC_LOG 得到粗略一行，标注 `provisional (unverified)`，单独成表。两层绝不共用一张表；未核实数字绝不评分、绝不参与差值计算、绝不作为结果引用。规则见 `references/digest_rubric_zh.md`。
3. **报告级，而非重新核实——并且 digest 自己要说出这一点**。与 `aggregate` 不同，你不会逐个重开引用源去确认数字。你连同出处一起抄录（`{值, 来源, 报告日期}`），让读者能自己去查。每份 digest 都用自己的话写明：这是一份进展记录，经核实的数字在 `wkdrs/results/results.md`。从 digest 里把数字抄进论文，是这个文件本身就在警告的误用。
4. **"变化"才是重点**。一份只罗列 run 的 digest，只是更差版的 `star-flow-status`。价值在于与上一份 digest 的 `sources:` 做对比——哪些 run 是新的、哪些判定变了、哪些上次还是未核实层而这次已被分析、哪些主张被证伪。没有上一份 digest 时，就说序列从此开始，并整段省略，而不是编造变化。
5. **允许叙事，不许归因**。你可以写学到了什么、一个负面结果暗示了什么、工作在哪里转了向。你**不可以**说*为什么*某个变体赢了——那需要这一家 skill 都不做的受控对比（`aggregate_spec.md` 的规矩，在这里同样生效）。报告方向，并说清该问谁：解读找 `/skill:star-expt-analyst <run>`，对计划意味着什么找 `/skill:star-plan-reviser`。
6. **除自己的文件外严格只读；红线同样适用**。你唯一写的是 `wkdrs/digests/EXPT_DIGEST_<date>.md`。绝不碰计划、`exec_status`、`EXEC_PLAN.md`、`EXEC_LOG.md`、任何 `EXPT_ANALYSIS` 报告，或结果汇总表 `wkdrs/results/*`。绝不为填一个缺口去重跑训练、评测或高成本调用——没测的东西是一条带转交命令的缺口，不是你要接下的活。

## 工作流

**先扫一次，再扫窗口。** 收集脚本 `scripts/scan.sh` 随开场装载（通用规约段）一起运行——不要再单独跑一遍。它一次调用就打印出 Step 0、1、3、5 本来要逐个文件打开的内容——每份计划与每个已登记产物的 frontmatter，每份 run 日志的 frontmatter 及其步骤表、待用户勾选项、方向性信号与其中出现的日期，以及 `metds/` 与 `wkdrs/` 深度 1 的文件清单（文件名里的日期也在其中）。ledger 模式下开场装载改用 `scripts/scan.sh --trails`：Step 8 需要每一条 `model_trail`、每份计划的 `## Revision History`，以及没有 frontmatter 的文件其头部行里的 `model_id`——这些默认模式都不打印。该模式同时丢掉一次溯源阅读用不上的东西——子计划索引、占位符计数、逐 run 的日期行和 DIRS——但它从不给 trail 本身封顶：一份有缺口的记录表比一份长记录表更糟。

脚本只收集，从不判断——它不认识时间窗、上次覆盖到的日期、分层，也不知道产物登记表期待哪些文件名，所有规则都留在本文件和 `references/scope_spec_zh.md`（已随开场装载到达）里。把它打印的内容当作原始文件内容来读，不要再去打开它已覆盖的文件。只有两种情况值得再读一次：必须逐字引用而不是计数的段落；以及扫描列出存在、但没有打印内容的文件——没有 frontmatter 的产物只被列出、从不被打印，因此从来不算被覆盖。

**Step 2 要的报告正文来自第二次调用，在 Step 1 点名了窗口内的 run 之后**：`--bodies 2,3,7 --runs <那些 run 目录>` 只为这些 run 补上每份报告的判定、完成判据记分卡和解读三节。第一次调用不要带 `--bodies`。时间窗到 Step 0 才确定、到 Step 1 才落到具体 run 上，所以在那之前加 `--bodies`，打印的是项目全部历史里的每一份报告——不论在不在窗口内，每个 run 约 180 行。所有 run 都落在窗口里的项目上这不花什么代价；而 `/skill:star-expt-digest 7d` 打在一年的工作上，就是为了报一周而读完一年。分成两次调用，正是先确定窗口再读正文的代价，比上面两种错法都便宜。这三个编号是本 skill 的规则、写在 `references/digest_rubric_zh.md` 里，不是脚本的规则——脚本只打印交给它的那些编号小节，对里面是什么一无所知，所以报告改了编号，改的是评分表里的一行，脚本一个字都不用动。若脚本缺失或执行失败，退回逐文件读取，并在报告里说明这次走了退路。若无法解析出本 skill 自己的目录，仓库里任一份拷贝都可以——每份 `scripts/scan.sh` 逐字节相同，CI 会强制这一点：`bash "$(find . -path '*/skills/*/scripts/scan.sh' | head -1)"`。

### Step 0：确定周期与范围

1. 读 `.env`，解析 `CODE_NAME`、`CONDA_HOME`、`PYTHON_HOME`（规约 §3）。
2. 从扫描结果的产物 frontmatter 里取最新一份 `wkdrs/digests/EXPT_DIGEST_*.md`——其 `covers.through` 是上次覆盖到的日期，其 `sources:` 是 Step 4 的基线。
3. 按 `references/scope_spec_zh.md` 解释参数，先匹配先生效：`all` → 全部历史；`<N>d` / `<YYYY-MM-DD>` → 该时间窗；计划名 → 该节点家族，不设时间界；无参数 → 增量窗 `(上次覆盖到的日期, 今天]`，尚无 digest 时则为全部历史。
4. 在继续读之前先用一行说明解析出的周期与范围，好让错误的窗口在开工前就被发现。
5. **空周期是一个合法答案**。窗内没有任何 run → 说明这一点，写明上次覆盖到的日期和最新的 run 日期，然后停下。绝不为了报出点什么而放宽窗口。

### Step 1：收集范围内的 run

从扫描结果的计划 frontmatter 解析范围内的叶子，并对每个叶子取其 `exec_runs` 的每一项——为第二个种子重跑的叶子会有好几个 run，它们各自独立计日期。按 `references/scope_spec_zh.md` 的规则给每个 run 判定日期（分析报告日期，其次 EXEC_LOG 最后一条带日期的条目；绝不用文件 mtime），保留落在窗内的：报告日期在扫描清单的文件名里，日志日期在每份日志的 `[dates seen]` 行里。plan 模式下全部保留。

把每个保留下来的 run 分类为**有报告依据的**（目录里有 `EXPT_ANALYSIS_<date>.md`，取最新的一份）或**临时**（没有）。

### Step 2：读有报告依据的层

每个 run 只从它最新的 `EXPT_ANALYSIS_<date>.md` 读取，取第二次扫描打印的 `[bodies: sections 2,3,7]` 那一段：run 判定、§5 记分卡压缩成一行、报告记录的关键指标连同来源与 split，以及它写明的任何 blocker/major 观察、方向性信号或 kill-criterion 命中。不要打开该 run 的原始日志去补充报告——报告就是你要读的东西，绕到它背后属于逐 run 分析，那是 `/skill:star-expt-analyst` 的活，且带着本 skill 不做的核实环节。扫描对每一节封顶 60 行；某段以截断提示收尾时，才有理由直接打开那一份报告——也只打开那一份。

### Step 3：读未核实层（范围受限）

对没有分析报告的 run，**只**用扫描结果里它那段 `EXEC_LOG.md`：日志 `status`、步 done / 总数、任何 `blocked` 步、任何未勾选的"待用户执行"红线命令、任何记录的方向性信号。如果日志本身写明了一个关键指标数字**并且**给出了它来自哪个文件，就连 `path:line` 一起引用并打上 `provisional` 标签；如果没有，就写 `not measured`——绝不为了填上那一格去原始日志里翻找数字，也绝不出图。边界写在 `references/digest_rubric_zh.md`，而且是刻意收紧的：这一层存在是为了让一周的工作**可见**，不是为了让 digest 去给它打分。

### Step 4：推导"发生了什么变化"

把这次的 run 集合与上一份 digest 的 `sources:` 列表对比：首次出现的 run；判定变了的 run 及其方向；在那边是 `provisional` 而在这边是有报告依据的的 run；报告新判为证伪或命中 kill-criterion 的主张。只取有报告依据的行。没有上一份 digest → 说明这是第一份 digest，并省略该段。

### Step 5：收集周边语境

- **期内计划树变化**：`updated`（或 `finalized:`）落在窗内的计划——新建、修订、拆解、定稿。扫描结果里的计划 frontmatter 就是全部输入，不 diff 正文。
- **缺口与欠账**：范围内没有分析报告的 run；没有 `exec_runs` 的叶子；EXEC_LOG 里有未勾选红线命令的叶子；开场那次调用的清单显示仍未合并的执行分支——它们的记录在分支上、从当前 checkout 可能看不见，所以要点出分支名、转 `/skill:star-plan-executor <叶子>` 抵达它的合并确认点，并且绝不隔着分支边界引用结果；以及 `wkdrs/results/results.md`（或按范围的 `wkdrs/results/results_<slug>.md`）是否比范围内最新的分析报告更旧。

### Step 6：写 digest

填 `assets/digest_template_zh.md`（英文：`assets/digest_template.md`；digest 跟随对话语言，或范围内计划一致时跟随它们的语言），写到 `wkdrs/digests/EXPT_DIGEST_<YYYY-MM-DD>.md`。只用系统时钟取的真实日期（规约 §4）。同一天再写一次覆盖当天的文件；换一天则各写各的——这个目录本身就是时间线。

**只有覆盖区间截止到今天的 digest 才推进上次覆盖到的日期。** 回溯性的窗口（`2026-05-01`，或一次 plan 家族 digest）照常写文件，但不动序列的续接点：把它的 `covers.through` 写成它实际覆盖到的日期，别让一次向后看的阅读导致下一次增量运行漏掉工作。`references/scope_spec_zh.md` 里写了精确规则。

### Step 7：摘要与转交

≤500 字，先说周期：窗口与范围、有报告依据的 / 无报告、数字未核实的各多少个 run、核心结论（学到了什么）、相对上一份 digest 有什么变化、以及最主要的缺口。然后是转交：未分析的 run → `/skill:star-expt-analyst <run dir>`；过期的结果汇总表 → `/skill:star-expt-analyst aggregate`；未执行或待用户的叶子 → `/skill:star-plan-executor <slug>`；被证伪的主张或 kill-criterion 命中 → `/skill:star-plan-reviser <slug>`；当前树态 → `/skill:star-flow-status`。以 digest 路径收尾，并用一行说明：这是一份进展记录，其中的数字引自报告，并未在此核实。

### Step 8：模型记录表（仅 ledger 模式）

把每份产物的 `model_trail` 汇总成一张表——**谁写了什么**的跨产物视图，这是任何单份产物都给不出的。它是例行汇总，不是解读：读、分组、计数、写出。

1. 按 `--trails` 扫描列出的清单，遍历规约 §8 登记在册且磁盘上存在的产物。**只用 frontmatter**——`model_id`、`model_trail`，以及该文件自己的日期字段——外加扫描为没有 frontmatter 的产物打印的头部行 `model_id`。绝不为推断作者身份去读正文。
2. 每一行都抄自某条 trail 条目。没有 `model_trail` 的产物是**缺口**，连同"为什么没有"（写于该字段存在之前，或某个 skill 漏写）列进 §5——绝不假定它是单模型，也绝不靠猜来回填。
3. 某份产物若带有比 trail 更细的逐事件归属——计划的 `## Revision History`、`EXEC_LOG` 步骤表的 `model` 列、`refs_index` 的 `Model` 列——优先用它：它说的是某个模型写了哪一**步**或哪一**条**，而不只是哪一次会话。
4. 填 `assets/model_ledger_template_zh.md`（英文：`assets/model_ledger_template.md`）写入 `wkdrs/digests/MODEL_LEDGER.md`。日期规则与 digest 相同：同一天覆盖，跨天各写各的。

**计数不是判决。** 报出各模型的写入事件数，到此为止。写入事件多的模型只是写得多，不等于"做得好"——本模型记录表里没有任何质量信号，用这些数字去说质量，与把指标差值归因到某个原因是同一种错误。trail 是自报的（规约 §8），模型记录表因此继承同一限制，并在正面写明。
## 状态与文件规则

- 写入只有 `wkdrs/digests/EXPT_DIGEST_<YYYY-MM-DD>.md`，以及——仅在 `ledger` 模式下——`wkdrs/digests/MODEL_LEDGER.md`。别处一律不写——不出图、不留脚本、不建子目录。
- 绝不碰：`metds/plans/*`（含 `exec_status`、`exec_runs`、`updated`）；`wkdrs/<run>/EXEC_PLAN.md` 与 `EXEC_LOG.md`；任何 `EXPT_ANALYSIS_<date>.md`（它们是你的输入，永远不是你的输出）；`wkdrs/results/results.md` 与 `wkdrs/results/results_<slug>.md`（结果汇总表属于 `/skill:star-expt-analyst aggregate`，digest 里的数字绝不能流进去）；`${CODE_NAME}/`；`.env`。
- 绝不移动、重命名或删除任何 run 目录、日志、产物，或更早的 digest。更早的 digest 是序列的历史，也是下一次运行的基线。
- 更早的 digest 只读它的 frontmatter——`covers`、`sources`、`previous`。绝不为了让它符合你现在知道的情况而回头改写它。
- 所有命令走 `.env` 的 conda 环境；不用系统 python；绝不安装或升级任何东西（规约 §3.5）。本 skill 除读文件外不需要任何包。
- 不做重活：不训练、不评测、不全量数据集遍历、不高成本 API 调用（规约 §2）。
- Git：只读；本 skill 从不提交（规约 §1）。`wkdrs/` 下只有 `*.md` 不被 git 忽略，因此 digest 序列**是可以进版本库的**——它就是 `wkdrs/digests/` 下的 markdown。本 skill 从不提交，所以这些文件会一直处于未暂存状态，直到用户自己提交；用户问到分享时如实说明。

## 对话纪律

- 只在工作流要求处用 ask_user_question 提问（计划名有歧义、参数既解析不成窗口也解析不成计划）。若它不可用（非交互 `dsh --profile headless` 下，无人应答），改用纯文本并要求明确回答。因为本 skill 不在自己的 digest 之外写任何东西，所以没有审批确认点——也正因如此，绝不声称或暗示你改动了计划、状态、报告或结果汇总表。
- 在对话里同样绝不把未核实数字当作结果陈述。digest 里标了未核实，回复里也要标。
- 用用户的语言回复；中文对话加载 `*_zh.md` 资源。中文 digest 里保持技术术语、指标名、日志键、文件路径、run 名为英文。
- 没人点名的运行：本 skill 是 agent 可以不经点名启动的八个之一（规约 §10），被拾起不改变上面的任何规则——每个确认点都与用户亲手点名时一致。随之而来的义务有三条：开跑前用一行自报家门，写明匹配上了什么、取了哪个范围；范围没有被文件本身定死时，列出候选并发问，而不是直接开跑；以一个工作单元收束——一份摘要，绝不悄悄扩大——结束时在决策记录里留一行：`匹配到什么 → 跑了什么 → 写了哪些文件`。“别自己开跑”和别的指令一样，在本次会话余下部分持续有效。
