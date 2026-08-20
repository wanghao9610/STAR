---
name: star-plan-executor
description: >-
  对项目代码执行 metds/plans/ 中的一份 leaf 研究子计划。使用 .env 定位代码库，把 子计划转成具体、带检查的执行计划，以外科手术式修改实现，运行轻量验证，把中间工作 文件保存在计划专属
  tasks 目录，在 run 专属 wkdrs 目录记录进度，并在 长时间或高成本实验前停止，把准确命令交给用户。将用户确认的偏差和执行中确定的值 回同步到子计划，并追加一条
  Revision History 条目，使计划文件忠实反映实际执行。当用户调用 star-plan-executor、一次运行点名它是下一步动作，或要求 agent
  执行、实现、落实或运行某份研究子计划时使用。 支持跨会话恢复和中英文双语工作。
---

# Research Plan Executor

> 本文件是 `SKILL.md` 的中文对照版，随英文版同步维护，供人阅读；运行时不装载它——指令以 `SKILL.md` 为准，中文对话按规约 §7.6 用中文回复，并把开场装载与各步骤点名的资源换成 `_zh` / `.zh-CN` 版本（中文措辞以规约 §0 词汇表为准）。若两版冲突，以 `SKILL.md` 为准。

调用方式：`star-plan-executor PLAN_NAME [描述]`，其中 `PLAN_NAME` 是 slug（`open-vocab-det-seg`）、数字前缀（`00`）或文件名（`00_mvp-three-tier_plan.md`）。计划名之后的一切都是描述（规约 §7.12）：用你自己的话说明这次要做什么——它是本次运行可以采纳、也可以写进产物的线索，替代不了任何一个确认点。它定不了计划名本身：解析不到计划的文本只是描述，目标照样要问。可选的 `involve=low|medium|high` 这个写法可与 `PLAN_NAME` 一同给出（如 `… involve=low`）：它设定本次运行的参与度档位（规约 §7.7），既不属于 `PLAN_NAME` 也不属于描述，两者解析之前先剥离。

**通用规约。** `docs/mds/star-workflow/research-workflow-conventions.zh-CN.md`（英文：`research-workflow-conventions.md`）是所有 STAR skill 共享的基线；本文件只写本 skill 特有的部分，并在更严处生效。读它就是本 skill 的全部开场装载——一条消息，动手前完成：规约文件经它自己的文件读取调用读入，绝不 `cat` 进 shell 命令——shell 结果一旦超过 30 KB 左右就会被存成文件，要再读一次才拿得回来，而规约文件单独就超过这个上限——同一条消息里再附一次 shell 调用，以项目根目录为工作目录，带两行：

```bash
grep -sE '^(STAR_LANG|INVOLVE)=' .env || echo 'STAR_LANG / INVOLVE: unset'   # reply language, question level (§7.6, §7.7)
bash <本 skill 所在目录>/scripts/scan.sh --slim
```

执行器会提交、会运行、还会把偏差写回子计划，所以每一节都用得上（§1 git、§2 红线、§3 `.env` 运行时、§4 真实日期、§5 计划名解析、§6 委派、§7 对话纪律、§8 产物登记表、§9 项目布局、§11 执行分支），Step 0 之前不需要装载任何别的。本 skill 点名的各 `references/*.md` 属于步骤内材料——哪一步引用，就在哪一步装载，不要提前。那条 `grep` 只做 §7.6/§7.7 的查询——`STAR_LANG` 定回复语言、`INVOLVE` 定提问档位——折进开场那条消息，两者就都不必各占一趟往返；完整的 `.env` 运行时（§3）仍在它自己的步骤（Step 2）解析。第二行是共享采集脚本，它的摘要就是步骤 0 和步骤 1 用来解析的依据：每个计划的 frontmatter——`children:` 用于判定是否叶子、`depends_on` 与兄弟叶子的 `exec_status` 用于依赖检查、`exec_runs` 用于续跑——外加每份运行日志的 frontmatter。目标子计划仍在 Step 0 整篇读入；摘要替掉的是逐个打开它的兄弟计划。脚本只收集，从不判断：不建树、不给就绪结论、不排序。把它打印的内容当作原始文件内容来读，就像你自己逐个打开过每份计划一样。`--slim` 是在有历史的项目上把结果压在大小上限以内的手段；万一仍然被存成文件，把这一行单独重跑一次。若脚本缺失或执行失败，退回直接读 `metds/plans/*_plan.md`，并在回复里说明这次走了退路。若本宿主没有独立的文件读取工具，就把 `cat docs/mds/star-workflow/research-workflow-conventions.zh-CN.md`（以及上面点名的其他文件）放回那次 shell 调用，并接受结果被存成文件的代价。

**复用上一次装载。** 上面那份装载里，凡是文本此刻仍能在本轮对话中逐字看到的部分就跳过不读——同一份规约文件、同一种语言、至少覆盖本文件点名的那些节，同样的参考文件，以及那次 `.env` 探测取到的 `STAR_LANG` / `INVOLVE` 取值。看不到的部分照旧读，仍用上面那一条消息发出。两种情况不算看得到：上下文压缩后只剩摘要而正文已经不在；以及只记得自己读过。拿不准就重读一遍。唯独采集脚本的摘要不能这样复用（上面装载了它的话）：每次都重新跑一次扫描。若整份装载都已在手，开场那条消息就整个省掉；若只剩扫描一项，就让它单独发出。

## 角色

通过修改代码和运行轻量验证，推动一份 **leaf 执行子计划**达到完成判据。上游 `star-plan-decomposer` 拥有子计划的策略和任务拆解；本 skill 拥有实现结果：`${CODE_NAME}/` 下的代码、`tasks/<plan-name>/` 下的中间工作文件，以及 `wkdrs/<run>/` 下的生成产物与验证证据。从所选计划文件名去掉 `_plan.md` 得到 `<plan-name>`（例如 `00_demo_plan.md` → `tasks/00_demo/`）。

只执行；不要重新制定策略或静默重新分解。若 §3 或 §5 模糊到无法执行，报告具体缺口并转回 `star-plan-decomposer`。

## 核心原则

1. **先读后写。** 规划修改前，检查 `.env`、写明的输入、相关代码和实际运行界面。列出当前状态与所需状态的差距。遵循 `references/orient_checklist_zh.md`。
2. **让计划可见，然后在范围内推进。** 把子计划转成 `EXEC_PLAN`，其中每个 action 都写明文件、命令、产物和范围受限检查。用你的计划工具跟踪它——一个 action 一个步骤，同时只保持一个 `in_progress`——并在 commentary 中总结计划。调用 executor 即授权普通的范围内实现与轻量验证；只有决定会实质改变范围或需要新授权时，才请求新方向。
3. **该委派的就委派。** 怎么切分由主 agent 自己定。协作工具可用、且有边界、相互独立的工作确实能从委派中受益时就委派——这是常态，不是例外。满足条件时，调用你的子代理工具：实现工作使用可写子代理，只读勘察使用只读子代理。绝不为每个琐碎顺序步骤创建一个 subagent。给每个受委派者 `references/agent_dispatch_spec_zh.md` 中那份范围很窄的交办说明；主 agent 始终负责集成和重新运行检查。那份文件里的树状态纪律——动作开始前它名下的文件在 git 里是干净的、重试前先恢复、以 `blocked` 收场的动作其改动去留要有明确决定——同样约束本地执行：两条路径上被放弃的改动是同一批改动。
4. **在重型或不可逆工作前停止。** 长时间或多 GPU 训练、全数据集评估、高成本 API 调用、无边界任务、覆盖有价值产物都会跨越 STOP line。准备可复现命令并交给用户；不要启动。遵循 `references/stop_line_rules_zh.md`。
5. **记录已验证状态——并保持子计划真实。** 把 `EXEC_PLAN.md` 和 `EXEC_LOG.md` 存在 `wkdrs/<run>/`。每次范围受限检查后更新日志。子计划 frontmatter 只维护 `exec_status`、`exec_runs`、`updated`；此外，仅当执行确实偏离子计划，或确定了计划留空而 method 文档会引用的值时，才对受影响 §2–§5 做一次**用户确认的回同步**并添加 `## Revision History`（`references/plan_sync_rules_zh.md`），使用户日后重读的计划与实际执行一致。
6. **使用项目运行时和布局。** 从 `.env` 读取 `CONDA_HOME`、`PYTHON_HOME`、`CODE_NAME`；绝不猜本地路径或使用系统 Python。若项目入口是 `execs/run.sh`，就使用它。创建 `tasks/<plan-name>/` 存放执行该计划时所需中间文件；可复用运行脚本放 `execs/scpts/`；生成输出和持久执行记录放 `wkdrs/<run>/`；数据放 `datas/`；权重放 `inits/`；代码放 `${CODE_NAME}/`。遵循 `AGENTS.md`。

## 工作流

### Step 0：解析目标

1. 按 slug、数字前缀或完整文件名，把 `PLAN_NAME` 与开场装载的摘要列出的计划匹配；它就是那份清单，不必再列一次目录。
2. 只有 leaf 可执行。若目标的 `children:` 非空，列出其 leaf 并询问执行哪一个（推荐第一个就绪的 leaf），或提议按依赖顺序逐个处理。
3. 目标不存在或有歧义时，列出简洁候选，只问一个直接问题。
4. 完整读取所选子计划。

### Step 1：检查就绪状态

1. 要求具体的 §3 任务分解与 §5 完成判据。若大部分是 `[TBD]` / `【待定】`，报告缺失决定，询问是返回 `star-plan-decomposer`（推荐），还是在明确记录剩余不确定性的前提下继续。
2. 验证写明的数据集、权重、代码模块和每个 `depends_on` 兄弟叶子——从已带着每个兄弟 frontmatter 的摘要读它们的状态，不要逐个打开。若硬依赖缺失或上游兄弟叶子未达到 `exec_status: done`，停止并报告准确 blocker。缺失数据集或权重是分解缺口，不能绕过：指明应负责它的 data-readiness leaf，或转回 `star-plan-decomposer <parent>` 添加一个。
3. 拒绝执行带着 `dropped:` 的叶子、或祖先被丢弃的叶子：点名丢弃写在哪个节点上，然后停下。要重新启用它，先用 `star-plan-reviser` 清掉那个字段——照跑一个用户已经否掉的方向，只会把算力花在没有任何东西会去统计的工作上。
4. 检查 leaf 的尺寸是否合适。能执行的 leaf 未必是合适的工作单元，而拆完之后没有任何环节再看一眼。把 decomposer 用在自己草稿上的那条尺寸判据——一块可独立检验的工作（它的 `references/subplan_rubric_zh.md` 第 8 条）——拿来对着计划当下的样子再判一次；所有信号都在 Step 0 已经读进来的正文里，这一检查不额外花任何一次调用。**强信号，任一条成立即触发**：§5 写了不止一个彼此独立的检查；§3 越过 STOP line 不止一次，每一次把命令交回用户都是天然的 leaf 切口；§3 把取数据、建代码、跑实验混在同一个单元里，而数据集本该自成一个 leaf。**弱信号，两条同时成立算一条强信号**：§3 步骤数超过 12；§4 的产物横跨互不相关的产物族，或不止一个 run 目录。只有一条弱信号时，在报告里写一句话，不要发问——打断一个尺寸本来就合适的 leaf，代价比漏掉一个过大的 leaf 更高。检查命中时，先展示拆分预览再提问：2–5 个单元，每个给 slug、一句话目标、以及它会拥有的那条完成判据，再用一行写出执行顺序。要说明它是预览——不写文件、不分配前缀、不画 `depends_on`，`star-plan-decomposer` 仍然自己选轴、自己确认列表；预览的切口就是命中的那几条信号（一条完成判据一个单元、一次越过 STOP line 一个单元、一类活一个单元），不是重新做一次轴分析。需要超过 5 个单元，这本身就是结论——用一行说掉，不要列出来。然后提问：先拆分（有强信号命中时标为推荐），它会在写下任何东西之前结束本次运行，并交回 `star-plan-decomposer <leaf> <一句话的预览>`，描述那一段把草图作为线索带过去（规约 §7.12），执行则在 `star-plan-executor <它产出的 leaf>` 继续；或照原样执行，代价是每一次越过 STOP line 都要整个 run 停下再恢复，一个 `blocked` action 会挡住它后面的全部工作，失败则整个 leaf 重跑。不提供"只执行 leaf 的一部分"——收窄范围是一个没有人做过的决定（规约 §10.4）。`exec_runs` 非空的 leaf、或有运行正在某个分支或 worktree 上进行的 leaf，直接跳过这一检查：运行途中拆分，会把那次 run 的 `wkdrs/<run>/` 挂在一个再没有执行器会光顾的节点上——正是 `star-plan-decomposer` 会停下来警告的事。若第 1 条已经在往 decomposer 送，两件事合并成一个问题问。判定结论和命中的信号，在 Step 3 建起 `EXEC_LOG.md` 时记进它的 `Notes / decisions`（规约 §7.8），这样恢复运行不会再问一遍。

### Step 2：定位

遵循 `references/orient_checklist_zh.md`：

1. 读取 `.env`，解析 `CODE_NAME`、`CONDA_HOME`、`PYTHON_HOME`（规约 §3）。若这些路径指定的环境缺失或无法运行 Python，推荐执行前先用 `star-env-builder` 构建。
2. 映射 `${CODE_NAME}/`；若其中没有实现则声明 空代码库（从零起步），或先用 `star-code-architect` 引入参考代码库。
3. 把每个 §3 步骤追踪到真实文件，并分类为 exists / modify / create。
4. 确认实际 run 入口和测试入口。

### Step 3：构建并写出 EXEC_PLAN

1. 把 §3 和缺口清单细化成有序 action。每个 action 必须绑定 `{files / command through project env / artifact / check}`；最后一个 action 绑定 §5 完成判据。
2. 明确标出 STOP line；已知时估算运行时间/成本。画完的计划是对 leaf 尺寸的第二次读数：若计划落成后 action 数超过 12、或越过 STOP line 不止一次，而 Step 1 的尺寸检查没有命中，把这件事带到第 5 条那次暂停里，多给一个选项——先回去拆分，它会在写下任何东西之前结束本次运行——而不是单开一个问题。
3. 把 EXEC_PLAN 相对子计划 §2–§5 的实质性出入，以变更项形式（ADDED / MODIFIED / REMOVED / ENRICHED——`references/plan_sync_rules_zh.md`）记入 EXEC_PLAN 的“与子计划的偏差”表。与子计划自身粒度相矛盾算偏差；“更具体”不算——除非那是计划未写明、而某份方法文档会引用的值，那要记为一条 ENRICHED 行并写明该章节。
4. **定下分支与 worktree 两行**（规约 §11）：EXEC_PLAN 里只要有 action 要修改 `${CODE_NAME}/` 下已存在的被跟踪文件，计划就带上 `branch: <run>` 并推荐在它上面执行；只新增文件、或只写 `tasks/<plan-name>/` 与 `wkdrs/<run>/` 的计划带 `branch: none`。把 checkout 当前所在分支记为 `base:`，无论它叫什么。worktree 这一行答的是另一个问题——当前 checkout 此刻腾不腾得出来（§11.7）：任一忙碌信号命中（HEAD 停在别的 run 的执行分支上；未提交改动的路径归属别的 run 的记录；有命令交回了用户、结果还没回收——可能有任务在跑，只问不测；或用户明说要并行）→ `worktree: ../<根目录名>--wt/<run>`，并连带把 `branch: none` 改成 `branch: <run>`——树里的提交要有自己的归宿（§11.8）；无信号 → `worktree: none`。信号与操作细节：`references/branch_rules_zh.md`。
5. 在 commentary 中展示简洁计划和它会做出的改动，并只问一次是否给每个已验证 action 单独提交一次（推荐），同时列出任何已有未提交修改的路径——绝不暂存这些路径。并说明不做的代价：没有逐 action 提交，每个已验证 action 都停在未提交状态，后面要恢复时，唯一能依据的就是本次运行自己记下的每个 action 起点（`references/agent_dispatch_spec_zh.md`）。若第 4 条定了 `branch: <run>`，分支问题也在同一次暂停里问（规约 §11）：点明它从哪个基础分支分出，说明选它就同时选了逐 action 提交——只有提交才会被合并——以及唯一前置条件：当前 checkout 上没有正在运行的任务；不选则照旧在基础分支上执行。若第 4 条定了 `worktree: <path>`，树的问题也搭在同一次暂停里（§11.7）：点明推荐它的那个忙碌信号、路径、要补的链（`.env`、`datas/`、`inits/`），以及整个 run——提交、记录、后续 skill——从此都住在那棵树里，当前 checkout 原地不动；不选则在这里执行，等 checkout 忙完。仅在存在实质范围选择、非空的偏差表（执行前须与用户确认各行），或需要用户执行的 STOP-line action 时暂停。
6. 先建获批的分支：从记下的基础分支 `git switch -c <run>`，让下面的一切都生在它上面——获批的是 worktree 时改为 `git worktree add <path> -b <run> <base>`：任何 checkout 都不切换，补上符号链接并对树里的 `.env` 重验一次解析，树的绝对路径以 `worktree:` 记进两份记录，下面的一切都发生在树里（`references/branch_rules_zh.md`）。`<plan-name>` 取所选文件名去掉 `_plan.md`，为计划中间文件创建 `tasks/<plan-name>/`。**run 名为 `<prefix>_<slug>`**；重跑时追加用户给的后缀（`_v2`、某个日期）以示区分，该目录已存在但不是此 leaf 可恢复的 run 时，问一个后缀——绝不自行编造。从匹配语言的模板创建 `wkdrs/<run>/EXEC_PLAN.md`，并在同目录初始化 `EXEC_LOG.md`。把子计划 frontmatter 更新为 `exec_status: in_progress`，并将本 run **追加**到 `exec_runs`，不能替换最后一项——这段历史使 `star-expt-analyst aggregate` 能看到该 leaf 的每次运行。仍使用单个 `exec_run:` 的计划先迁移为 `exec_runs: [<that run>]`。此时把已确认的偏差行同步进子计划：原地更新受影响的 §2–§5 段落，追加 `## Revision History` 条目，更新 `updated`，并把每行标为 `synced`。


**发起确认之前先跑设计检查。** 把 `references/design_check.md` 交出去做一次"不知情"的复核：派一个只读子代理，交办材料正好三个文件——刚写出的 EXEC_PLAN、叶子子计划、根计划（计划 frontmatter 写着 `language: zh` 时改点名检查表的 `_zh` 那份；受托者绝不自己选）——范围逐字写明："只看这三个文件。不排序、不决定、不运行任何东西。"它按条返回 `item`、`verdict: pass | fail | unclear`、`evidence`、`fix`。主 agent 对每一条打算上报的 `fail` 都回去打开被引用的那一行——判"缺失"的 `fail` 引不出行，那就重读该条目所属的整节——然后把至多五条发现摆在确认调用**上方**，一条一行；确认不了的 `fail` 丢掉。检查只报告；做决定的是这个确认点，这里不叫停任何 run。没有受托者可用时，检查表由主 agent 自己跑（规约 §6.1）。
### Step 4：执行与验证

对每个未完成 action：

1. 决定本地执行还是委派。委派时调用你的子代理工具，实现工作使用可写子代理（只读勘察用只读子代理），遵循 `references/agent_dispatch_spec_zh.md`，并保持文件所有权不重叠。
2. 只做该 action 必需的修改，并通过项目环境运行其窄范围范围受限检查。
3. 在主 agent 中重跑或独立验证范围受限检查。通过后，记录证据和产物路径；若逐 action 提交已获批准，则提交该 action 的文件——在执行分支上，这次提交连同本 action 更新过的运行记录一起暂存，因为只有提交才会被合并（规约 §11.2）。失败后，主 agent 自己那次重跑就是证据：读失败点名的 `file:line`；只有在要判 `blocked`、或失败看起来是子计划粒度的问题时，才展开受托者的完整 diff。重试之前先恢复这个动作名下的文件；若有具体修复可做，诊断并最多重试两次；否则把 action 标为 `blocked`，按 `agent_dispatch_spec_zh.md` 定下它那些改动的去留，然后停止。
4. action 跨越 STOP line 时，准备准确命令（还可选写入 `execs/scpts/<run>.sh`），记录到 `Awaiting user`，并在 `开销` 一节记一行预计开销（GPU 数 × 小时，或调用次数与费用），不运行并停止。用户带结果回来时把实际开销补进那一行——根计划 §4 算力预算唯一的对账处；拿不到实际值就写 `未记`，绝不留空。
5. 若重试或 blocker 在子计划粒度改变了方法（新增/删除/替换步骤，交付物路径或完成判据变化），在 EXEC_LOG 的 `Pending amendments` 下记录变更项行并继续——这些在 finalize 时同步，而不是运行中同步。

### Step 5：完成

1. 运行子计划 §5 完成判据，并把证据记录到 `EXEC_LOG.md`。
2. 满足时，把 run 与子计划 `exec_status` 设为 `done`，然后只提议一次删除该计划的 `tasks/<plan-name>/` **草稿文件**——先把值得留的内容挪进 `wkdrs/<run>/`，并在 `EXEC_LOG.md` 记录选择；保留也完全可以。**该提议绝不覆盖该计划自有的工具脚本**（规约 §9）：把它们按名字列为保留项，只有用户指明才删。未满足时，按 §6 的本地备选方案处理，或报告已验证缺口。
3. 若 EXEC_LOG 的 `Pending amendments` 非空，先把整批落到正文——每条修正一行并编号，写明改哪一节、从什么改成什么、为什么——再一次提问（全部同步 / 除我点名的以外全部同步 / 先解答我点名的几行 / 跳过，标出你推荐的一项——规约 §7.13），按 `references/plan_sync_rules_zh.md` 把确认行写回（原地更新 §2–§5 + 添加 `## Revision History` + 更新 `updated`，然后勾掉各行）。仅限战术层：任何触碰 §1/§6、父计划或 kill-criterion 的内容都通过第 5 点的方向性信号转交，绝不回同步。
4. 检查 `references/exec_rubric_zh.md`，报告前修复范围内的失败；最多列出五个剩余失败及具体补救方法。
5. 若结果命中根计划 kill-criterion 或使低开销 MVP 假设失效，在日志中记录 **方向性信号**，并推荐 `star-plan-reviser <slug>`（审计证据并修订计划）、`star-plan-coach <slug>` 或 `star-plan-decomposer <slug>`。不要编辑父计划的策略章节。

### Step 6：报告

以结果开头。说明验证了什么及其证据，`tasks/<plan-name>/` 中间工作区和 `wkdrs/<run>/` 记录/产物的位置，哪些命令等待用户执行，哪些 amendment 已同步进子计划，以及剩余风险。点出 Step 7 即将启动的那次审查；有 STOP line 命令等待用户时，把它写在待跑命令之上。确认的 blocker/major 经 `star-plan-executor <leaf>` 回来，它重开受影响的 action、改完并验证，才把命令再交回——在执行分支上，干净的审查也从这里走：再次调用本 skill 就抵达合并确认点（规约 §11）。只要存在分支，就点出这次 run 的分支名及其未合并状态；run 住在 worktree 里时，一并点出树的路径——后续 skill 都在那棵树里工作。若有 STOP line 命令等待用户，补充说明其输出产生后，`star-expt-analyst <leaf>` 会根据 §5 完成判据给结果评分并解释其含义。报告控制在约 500 词以内。

### Step 7：启动审查

**报告不是这一轮的结尾。** 报告文字发出后，在同一轮里就把 `star-code-reviewer` 对着这个 leaf 启动——它的清单允许被隐式调用，目标就是这个 leaf——依据规约和子计划审计实现。它属于那八个 agent 可以自己启动的 skill、目标已经定下，所以它是一次运行，而不是一行文字：把 `star-code-reviewer <leaf>` 打印给 agent 自己，等于转交给了没有人（规约 §10.6）。两种收尾里它都是本次 run 的最后一个动作——run 完成后，在修订或进入下一项之前；有 STOP line 命令等待用户时，在用户跑那条命令之前。

1. **等待用户的那条命令不改变这一点。** 它照旧打印出来、归用户（规约 §2）；紧挨着一条只有用户能清掉的命令，并不会让审查也变成那样一条。一次收尾同时有两条时，把审查启动起来，才让报告里写的先后真正成立；审查发现连同那条命令一并交回。
2. **只有一个很窄的例外，问一次。** 探索性叶子、等待中的命令本身很便宜时，可以跳过审查直接跑那条命令——把它作为备选说出来而不是替用户决定，推荐项标在审查这一侧，并且在审查启动之前就问。这一步别的都不是问题：审查的代价，比它可能省下的任何一次运行都小。

## 状态与文件规则

- 把 `wkdrs/<run>/EXEC_LOG.md` 视为执行事实来源。再次调用时——`exec_runs` 非空的 leaf 就属于这种情况——读取该列表最后一项对应的 run，从第一个未完成项恢复。回同步只生效一次：标为 `synced` 或已勾选的行绝不重复应用；未同步 pending 行在 finalize 时重新提出。
- **先找分支，再找 run 目录。** 存在与该 leaf 匹配的 `<prefix>_<slug>*` 分支，就说明有一次 run 正在它上面进行——即便基础 checkout 显示该 leaf 未执行：基础分支是准据（规约 §11.3）。先确认工作区没有无关的未提交改动（有则列出并等用户处理），`git switch` 过去，按上一条从它的 `EXEC_LOG.md` 续跑。记录在案的 `branch:` 已不存在时，这是要上报的 blocker，绝不无声重建。
- **记录里带 `worktree:` 的 run 住在那棵树里。** 先确认树还在（`git worktree list`），在树里续跑，绝不切换当前 checkout。记录在案的树从磁盘上消失，和分支消失是同一种 blocker：`git worktree prune` 清掉过期元数据，绝不无声重建。
- run 目录里的 `CODE_REVIEW_<date>.md`，若其 blocker/major 发现没有在日志里记为已处理，就排在一切之前重开工作：把每个受影响的 action 退回 `in_progress` 并在备注写上该发现的编号，一条发现跨多个 action 时改为在 `EXEC_PLAN.md` 追加一个补救 action；整批确认一次，执行并验证，之后才把待跑的 STOP line 命令交回。用户明确不处理的发现，连同这个决定记为已处理，下次调用不再重开它。
- **在执行分支上，这轮工作终于合并确认点。** 每个 action 都 `done`、§5 完成判据成立、最新审查的 blocker/major 都已处理时，剩下的唯一动作就是合并（规约 §11.4）——任何参与度档位都要问。操作细节在 `references/branch_rules_zh.md`：默认 squash，基础分支前进过就先把它 merge 进来，合并后在基础分支上重跑该 leaf 的轻量检查，分支删不删另问一道——还有弃用路径：先把 `wkdrs/<run>/*.md` 与子计划里这次 run 的条目带回基础分支，才谈得上删除。进了 worktree 的 run，squash 不用切换——主 checkout 本来就站在基础分支上——合并后再了结那棵树：先把非 md 产物挪回来，再 `git worktree remove` 且不带 `--force`，各问一道（§11.9）。
- `tasks/<plan-name>/` 存放该计划自有的工具脚本（持久）与可丢弃草稿文件，后者的生命周期归本 skill：Step 3 创建，§5 满足后在 finalize 时只提议删除它，绝不删脚本（规约 §9）。生成产物与持久证据绝不放在那里；未经询问绝不删除，也绝不触碰其他计划的 `tasks/` 目录。
- 可以自由编辑子计划 frontmatter 的 `exec_status`、`exec_runs`、`updated`；只有通过用户确认的回同步协议（`references/plan_sync_rules_zh.md`）才能编辑其 §2–§5，且始终原地更新并配对一个 `## Revision History` 条目。绝不重写 §1 或 §6，绝不触碰父计划——objective 或 strategy 级偏差转交 `star-plan-reviser` / `star-plan-coach` / `star-plan-decomposer`。
- Git：每个已验证 action 一个 commit，只暂存该 action 触碰的文件——在执行分支上，连同本 action 更新过的运行记录——且仅在逐 action 提交获批时（规约 §1）。分支的创建、合并、弃用只发生在 §11 各自的确认点上，worktree 的创建与移除同理（`references/branch_rules_zh.md`）；绝不 rebase 执行分支，记录未先带回基础分支的分支绝不删除，非 md 产物未挪出的树绝不 `git worktree remove`——也绝不带 `--force`。
- 允许的 action status：`pending` / `in_progress` / `done` / `blocked` / `skipped`。

## 对话纪律

- 在非交互运行中（你的提问工具不可用），回退：把 EXEC_PLAN 以纯文本呈现，并在写任何文件、跑任何命令之前要求一次明确的纯文本批准——仍然重实验前停，在任何同步回写子计划前仍需纯文本确认。
- **问题所指的内容写在同一条消息的正文里、排在这次调用之前**——待同步修正整批、交付批准的 EXEC_PLAN。选项只装答案，不装内容本身；发出前回看一眼：选项上面空无一物，说明内容是被跳过了、不是被压缩了。
- 匹配用户的对话语言，同时保留计划正文 frontmatter 的 `language`；中文计划中的技术术语保留英文。
- 参与度档位（规约 §7.7）。本 skill 中不受档位影响：STOP line（Step 4）、Step 3 的逐 action 提交、执行分支与 worktree 三问及偏差行确认（它回写计划 §2–§5）、合并确认点与分支或 worktree 的弃用、移除或删除（规约 §11）、Step 5 的 Pending amendments 整批同步、删草稿文件的提议（它把关一次删除），以及 blocked action 那些改动的去留（它同样把关一次删除——`references/agent_dispatch_spec_zh.md`）。`low` 档不再问：Step 0 的选 leaf（按依赖序取第一个就绪的 leaf；目标缺失或有歧义仍要问，规约 §5.2）、Step 1 的就绪回退与尺寸检查（取推荐项：送回 decomposer 并停下）、以及 Step 7 那个探索性叶子命令便宜时的跳过备选（取推荐项：启动审查）。启动审查本身在任何档位都不是一个问题——理由写在 Step 7。`high` 档：Step 4 每个 action 执行前先确认。生效档位及其来源在 `EXEC_LOG.md` 里记一次。
