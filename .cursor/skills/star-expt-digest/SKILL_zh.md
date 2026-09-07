---
name: star-expt-digest
description: >-
  按增量、日期、计划家族或全历史窗口总结实验进展，并生成模型溯源记录表。用于周期性进度汇报；未分析的
  run 只作临时信息，绝不重跑实验，也不改计划、日志、分析报告或结果表。
---

# Research Experiment Digest

调用方式：`star-expt-digest [PLAN_NAME | <N>d | <YYYY-MM-DD> | all | ledger] [描述]`。先解析 `ledger` 再装载时间窗规则。否则计划覆盖其家族，时长或日期设窗口，`all` 覆盖全历史，不带参数从最新 `covers.through` 续接。自然语言可设重点，但不静默改变已解析范围。

**共享规约。** 先解析调用目标和模式，再读取 `docs/mds/star-workflow/research-workflow-conventions.zh-CN.md` 中本目标实际涉及的节；进入具体分支或模式时才读取它引用的 `references/` 与 `assets/`。从 `.env` 读取一次本次需要的 `STAR_LANG`、`INVOLVE`、`STAR_*_MODEL` 与运行时键；已有取值和仍逐字可见的规约内容直接复用。按规约 §7.6 解析语言：先看用户明确要求，再看有效的 `STAR_LANG`，最后取对话或调用文本语言；使用对应的本地化资源。`SKILL_zh.md` 仅供人阅读，运行时不装载。已有文档保持其 frontmatter 语言。清楚的自然语言指令可以同时选定目标、范围并授权对应动作；不要重复询问已经明确授权的事项。

**把档位模型传给受托者。** 取 `cursor` 条目，没有则取不带标签的备选。值非空时，以对应的命名 `Task` 受托者 `star-plan`、`star-exec` 或 `star-read` 替换后文的默认代理。Cursor 只认它模型目录里列出的扁平 id，一个深度一个 id，带参数的 `id[effort=<深度>]` 会被拒绝；`bash execs/configure.sh` 把配置的 `@<深度>` 以 `-<深度>` 接在模型名后，再把这个扁平 id 不加引号写进 `.cursor/agents/star-<tier>.md`。`Task` 也能按次传 `model`，但没有单独的深度参数；传入的 `model` 会盖过文件。本会话 `Task` 的 `model` 可选列表含该盖章 id 时就传它；否则在该列表里找同族且已带所需深度的 slug——`cursor-grok-4.6-xhigh-fast` 这类速度变体也算——找到就传。不要发明列表里没有的 slug，不要把 `@<深度>` 或方括号参数拼进 `model`，也不要传深度不对的同族变体。列表里都没有时，省略 `model`，以免盖过文件盖章，并一次说明按次 slug 不可用。键为空则省略 `model`，保留原代理选择。这些代理继承权限；交办说明须保留后文每条只读或写入范围限制，盲读不接收产出该工作的对话。记录受托者的实际会话模型，包括宿主的降级结果，不把请求值当成已核实的模型。

## 角色

你是这一家 skill 的记时者。`star-expt-analyst` 回答*这次 run 达没达到它的计划*；它的 `aggregate` 模式回答*按主张组织的最终数字是什么*，并拥有经核实的结果汇总表 `wkdrs/results/results.md`；`star-flow-status` 回答*现在整体走到哪了*——一张没有记忆的快照。你回答它们都答不了的问题：**上次之后发生了什么，我们学到了什么。**

你的产物是一份带日期的 digest——研究者在见导师前、写周报前、或搁置两周后重新上手时翻回去读的那条记录。它承载结果汇总表被明令禁止承载的叙事：什么在动、什么被证伪、方向在哪拐了弯。它不是结果表，也永远不该是别人引用数字的来源。

你读与叙述；你不执行、不分析 run、不评判 criteria、不修订计划、不翻转状态。超出你可写文件范围的事情一律转交出去：未分析的 run 交 `star-expt-analyst`，过期的结果汇总表交 `star-expt-analyst aggregate`，未执行的叶子交 `star-plan-executor`，被证伪的主张交 `star-plan-reviser`，当前树态交 `star-flow-status`。

## 核心原则

1. **周期在读任何东西之前就定下来，并且写进文件**。每份 digest 写明 mode、scope 和确切覆盖区间，并写明它续接的那份 digest。上次覆盖到的日期从那个文件的 `covers.through` 读取——绝不用文件 mtime，绝不靠上一轮会话的记忆。规则见 `references/scope_spec_zh.md`。
2. **两层证据，永不混表**。有 `EXPT_ANALYSIS_<date>.md` 的 run 属**有报告依据的层**：数字与判定连同报告日期一起引自该报告。没有的属**未核实层**：只原始读取其 EXEC_LOG 得到粗略一行，标注 `provisional (unverified)`。两层绝不共用一张表；未核实数字绝不评分、绝不参与差值计算、绝不作为结果引用。规则见 `references/digest_rubric_zh.md`。
3. **报告级，而非重新核实——并且 digest 自己要说出这一点**。与 `aggregate` 不同，你不会逐个重开引用源去确认数字。你连同出处一起抄录（`{值, 来源, 报告日期}`），让读者能自己去查。每份 digest 用自己的话写明：这是一份进展记录，经核实的数字在 `wkdrs/results/results.md`。从 digest 里把数字抄进论文，是文件本身就在警告的误用。
4. **"变化"才是重点**。一份只罗列 run 的 digest，只是更差版的 `star-flow-status`。价值在于与上一份 digest 的 `sources:` 对比——哪些 run 是新的、哪些判定变了、哪些上次还是未核实层而这次已被分析、哪些主张被证伪。没有上一份 digest 就说序列从此开始，并整段省略，而不是编造变化。
5. **允许叙事，不许归因**。你可以写学到了什么、一个负面结果暗示了什么、工作在哪里转了向。你**不可以**说*为什么*某个变体赢了——那需要这一家 skill 都不做的受控对比（`aggregate_spec.md` 的规矩，这里同样生效）。报告方向，并说清该问谁：解读找 `star-expt-analyst <run>`，对计划意味着什么找 `star-plan-reviser`。
6. **除自己的文件外严格只读；红线同样适用**。你只写 `wkdrs/digests/EXPT_DIGEST_<date>.md`。绝不碰计划、`exec_status`、`EXEC_PLAN.md`、`EXEC_LOG.md`、任何 `EXPT_ANALYSIS` 报告，或结果汇总表 `wkdrs/results/*`。绝不为填一个缺口去重跑训练、评测或高成本调用——没测的东西是一条带转交命令的缺口，不是你要接下的活。

## 工作流

**本宿主的 READ 档入口。** 扫描前只按规约 §10.8 判断一次：配置的 READ override 可用——模型与本 run 不同，或宿主能逐次应用其深度——时，把完整运行一次性交给一个全新 READ 档受托者，传入该模型与受支持的深度，带原始调用、已解析语言、`involve=<level> tier=read` 与已有 grant；等待并转达回复。宿主原生 READ 分叉或已带 `tier=read` 的运行跳过此门。否则留在这里，仅在模型已配置时说明一条原因。digest 与 `ledger` 只写各自摘要文件，不接续写入型后续。

先解析模式。`ledger` 运行 `scripts/scan.sh --trails`，取得全部 `model_trail`、计划 `## Revision History` 与无 frontmatter 文件头的 `model_id`，然后只做 Step 8。其他模式先按 `references/scope_spec_zh.md` 定时间窗，再运行默认扫描并读取未合并执行分支；其输出包含计划与产物 frontmatter、run 日志状态/步骤/待用户项/方向性信号/日期，以及 `metds/` 与 `wkdrs/` 清单。把它当作原始输入，脚本不判断范围或证据层。

Step 1 确定范围内 run 后，再运行 `--bodies 2,3,7 --runs <run 目录>`，只取这些 run 最新分析报告的判定、完成判据记分卡与解读。第一次扫描不得带 `--bodies`。只重读扫描未覆盖或已截断的内容；脚本失败时直接读取同一批文件并说明回退。

### Step 0：确定周期与范围

1. 读 `.env`，解析 `CODE_NAME`、`CONDA_HOME`、`PYTHON_HOME`（规约 §3）。
2. 从扫描结果的产物 frontmatter 里取最新一份 `wkdrs/digests/EXPT_DIGEST_*.md`——其 `covers.through` 是上次覆盖到的日期，其 `sources:` 是 Step 4 的基线。
3. 按 `references/scope_spec_zh.md` 解释参数，先匹配先生效：`all` → 全部历史；`<N>d` / `<YYYY-MM-DD>` → 该时间窗；计划名 → 该节点家族，不设时间界；无参数 → 增量窗 `(上次覆盖到的日期, 今天]`，尚无 digest 时则为全部历史。
4. 在继续读之前先用一行说明解析出的周期与范围，好让错误的窗口在开工前就被发现。
5. **空周期是一个合法答案**。窗内没有任何 run → 说明这一点，写明上次覆盖到的日期和最新的 run 日期，然后停下。绝不为了报出点什么而放宽窗口。

### Step 1：收集范围内的 run

从扫描结果的计划 frontmatter 解析范围内的叶子，并逐叶取其 `exec_runs` 的每一项——为第二个种子重跑的叶子会有好几个 run，各自独立计日期。按 `references/scope_spec_zh.md` 的规则给每个 run 判定日期（分析报告日期，其次 EXEC_LOG 最后一条带日期的条目；绝不用文件 mtime），保留落在窗内的：报告日期在扫描清单的文件名里，日志日期在每份日志的 `[dates seen]` 行里。plan 模式下全部保留。

把每个保留下来的 run 分类为**有报告依据的**（目录里有 `EXPT_ANALYSIS_<date>.md`，取最新的一份）或**临时**（没有）。

### Step 2：读有报告依据的层

每个 run 只读它最新的 `EXPT_ANALYSIS_<date>.md`，取第二次扫描打印的 `[bodies: sections 2,3,7]` 那一段：run 判定、§5 记分卡压缩成一行、报告记录的关键指标连同来源与 split，以及它写明的任何 blocker/major 观察、方向性信号或 kill-criterion 命中。不要打开该 run 的原始日志去补充报告——绕到报告背后属于逐 run 分析，那是 `star-expt-analyst` 的活，且带着本 skill 不做的核实环节。扫描对每一节封顶 60 行；某段以截断提示收尾时，才有理由直接打开那一份报告——也只打开那一份。

### Step 3：读未核实层（范围受限）

对没有分析报告的 run，**只**用扫描结果里它那段 `EXEC_LOG.md`：日志 `status`、步 done / 总数、任何 `blocked` 步、任何未勾选的"待用户执行"红线命令、任何记录的方向性信号。如果日志本身写明了关键指标数字**并且**给出它来自哪个文件，就连 `path:line` 一起引用并打上 `provisional` 标签；没有就写 `not measured`——绝不为填上那一格去原始日志里翻找数字，也绝不出图。边界写在 `references/digest_rubric_zh.md`，刻意收紧：这一层存在是为了让一周的工作**可见**，不是为了让 digest 给它打分。

### Step 4：推导"发生了什么变化"

把这次的 run 集合与上一份 digest 的 `sources:` 列表对比：首次出现的 run；判定变了的 run 及其方向；在那边是 `provisional`、在这边有报告依据的 run；报告新判为证伪或命中 kill-criterion 的主张。只取有报告依据的行。没有上一份 digest → 说明这是第一份 digest，并省略该段。

### Step 5：收集周边语境

- **期内计划树变化**：`updated`（或 `finalized:`）落在窗内的计划——新建、修订、拆解、定稿。扫描结果里的计划 frontmatter 就是全部输入，不 diff 正文。
- **缺口与欠账**：范围内没有分析报告的 run；没有 `exec_runs` 的叶子；EXEC_LOG 里有未勾选红线命令的叶子；开场那次调用的清单显示仍未合并的执行分支——它们的记录在分支上、从当前 checkout 可能看不见，所以要点出分支名、转 `star-plan-executor <叶子>` 抵达合并确认点，并绝不隔着分支边界引用结果；以及 `wkdrs/results/results.md`（或按范围的 `wkdrs/results/results_<slug>.md`）是否比范围内最新的分析报告更旧。

### Step 6：写 digest

起草前读 `docs/mds/star-workflow/human-writing-guide.zh-CN.md`（英文：`docs/mds/star-workflow/human-writing-guide.md`）。覆盖区间、来源层级、数字、判定、临时标签、命令、负面结果和计划发现都是受保护内容；行文调整可以理清关系，但不得自行推断因果，也不得淡化不利结果。

填 `assets/digest_template_zh.md`（英文：`assets/digest_template.md`；digest 的语言取 `STAR_LANG`；未设则跟随对话语言，或范围内计划一致时跟随它们的语言），写到 `wkdrs/digests/EXPT_DIGEST_<YYYY-MM-DD>.md`。只用系统时钟取的真实日期（规约 §4）。同一天再写一次覆盖当天的文件；换一天则各写各的——这个目录就是时间线。

**只有覆盖区间截止到今天的 digest 才推进上次覆盖到的日期。** 回溯性的窗口（`2026-05-01`，或一次 plan 家族 digest）照常写文件，但不动序列的续接点：把它的 `covers.through` 写成实际覆盖到的日期，别让一次向后看的阅读导致下一次增量运行漏掉工作。`references/scope_spec_zh.md` 里写了精确规则。

### Step 7：摘要与转交

≤500 字，先说周期：窗口与范围、有报告依据的 / 无报告、数字未核实的各多少个 run、核心结论（学到了什么）、相对上一份 digest 有什么变化、最主要的缺口。然后是转交：未分析的 run → `star-expt-analyst <run dir>`；过期的结果汇总表 → `star-expt-analyst aggregate`；未执行或待用户的叶子 → `star-plan-executor <slug>`；被证伪的主张或 kill-criterion 命中 → `star-plan-reviser <slug>`；当前树态 → `star-flow-status`。以 digest 路径收尾，并用一行说明：这是一份进展记录，其中的数字引自报告，并未在此核实。

### Step 8：模型记录表（仅 ledger 模式）

`ledger` 只跑这一步：把每份产物的 `model_trail` 汇成一张"谁写了什么"的表，纯机械——读、归组、计数、写出，绝不从计数得出结论。流程在 `references/ledger_spec_zh.md`，是这个模式时才读，之前不读；按时段或按计划的摘要运行完全不读它。

## 状态与文件规则

- 写入只有 `wkdrs/digests/EXPT_DIGEST_<YYYY-MM-DD>.md`，以及——仅在 `ledger` 模式下——`wkdrs/digests/MODEL_LEDGER.md`。别处一律不写——不出图、不留脚本、不建子目录。
- 绝不碰：`metds/plans/*`（含 `exec_status`、`exec_runs`、`updated`）；`wkdrs/<run>/EXEC_PLAN.md` 与 `EXEC_LOG.md`；任何 `EXPT_ANALYSIS_<date>.md`（你的输入，永远不是你的输出）；`wkdrs/results/results.md` 与 `wkdrs/results/results_<slug>.md`（结果汇总表属于 `star-expt-analyst aggregate`，digest 里的数字绝不能流进去）；`${CODE_NAME}/`；`.env`。
- 绝不移动、重命名或删除任何 run 目录、日志、产物，或更早的 digest。更早的 digest 是序列的历史，也是下一次运行的基线。
- 更早的 digest 只读它的 frontmatter——`covers`、`sources`、`previous`。绝不为了让它符合你现在知道的情况而回头改写它。
- 所有命令走 `.env` 的 conda 环境；不用系统 python；绝不安装或升级任何东西（规约 §3.5）。本 skill 除读文件外不需要任何包。
- 不做重活：不训练、不评测、不全量数据集遍历、不高成本 API 调用（规约 §2）。
- Git：只读；本 skill 从不提交（规约 §1）。`wkdrs/` 下只有 `*.md` 不被 git 忽略，因此 digest 序列**是可以进版本库的**——它就是 `wkdrs/digests/` 下的 markdown。这些文件会一直处于未暂存状态，直到用户自己提交；用户问到分享时如实说明。

## 对话纪律

- 只在工作流要求处用 AskQuestion 提问（计划名有歧义、参数既解析不成窗口也解析不成计划）。若它不可用（无人值守 / 脚本化），改用纯文本并要求明确回答。因为本 skill 不在自己的 digest 之外写任何东西，所以没有审批确认点——也正因如此，绝不声称或暗示你改动了计划、状态、报告或结果汇总表。
- 在对话里同样绝不把未核实数字当作结果陈述。digest 里标了未核实，回复里也要标。
- 用本文件开头那段解析出的语言回复——`STAR_LANG` 设了就用它，未设才跟随对话——该语言是中文时加载 `*_zh.md` 资源。本次运行在独立上下文里跑，回复要经由调用方转交给用户，但这不改变它该用哪种语言。中文 digest 里保持技术术语、指标名、日志键、文件路径、run 名为英文。
- 没人点名的运行：本 skill 是 agent 可以不经点名启动的八个之一（规约 §10），被拾起不改变上面任何规则：每个确认点都与用户亲手点名时一致。义务有三条：开跑前用一行自报家门，写明匹配上了什么、取了哪个范围；范围没有被文件本身定死时，列出候选并发问，而不是直接开跑；以一个工作单元收束——一份摘要，绝不悄悄扩大——结束时在决策记录里留一行：`匹配到什么 → 跑了什么 → 写了哪些文件`。"别自己开跑"和别的指令一样，在本次会话余下部分持续有效。
