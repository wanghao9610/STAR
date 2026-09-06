---
name: star-plan-executor
description: >-
  执行或恢复一份叶子研究子计划：定位代码库、写出带检查的执行计划、做外科式实现、验证并记录进度。用于计划
  已可落实时；高成本实验停在准确的交还命令前。
---

# Research Plan Executor

调用方式：`star-plan-executor PLAN_NAME [描述]`。按 slug、数字前缀或文件名解析 leaf。其余自然语言可约束范围或明确授权执行选择；仅在目标、研究范围、验收标准、成本、关键输入、破坏性动作或覆盖仍未解决时提问。

**共享规约。** 先解析调用目标和模式，再读取 `docs/mds/star-workflow/research-workflow-conventions.zh-CN.md` 中本目标实际涉及的节；进入具体分支或模式时才读取它引用的 `references/` 与 `assets/`。从 `.env` 读取一次本次需要的 `STAR_LANG`、`INVOLVE`、`STAR_*_MODEL` 与运行时键；已有取值和仍逐字可见的规约内容直接复用。按规约 §7.6 解析语言：用户明确要求优先，其次是有效的 `STAR_LANG`，最后跟随对话语言或调用文本语言；使用对应语种的资源。`SKILL_zh.md` 仅供人阅读，运行时不装载。已有文档保持其 frontmatter 语言。清楚的自然语言指令可以同时选定目标、范围并授权对应动作；不要重复询问已经明确授权的事项。

目标解析后运行 `scripts/scan.sh --slim`，把它的计划 frontmatter 与运行日志 frontmatter 摘要作为 Step 0–1 的原始输入；目标 leaf 仍须整篇读取。脚本失败时直接读取计划文件并说明回退。

**把档位模型传给受托者。** 按规约 §10.8 为当前宿主解析本模式的 PLAN、EXEC 或 READ 档模型。委派接口支持逐次 `model` 时传入解析值；与完整上下文继承冲突时使用全新、自包含的交办说明。READ 档收集与盲读不继承产出者对话。取值为空时省略 model override，保留宿主/会话默认值；已配置但宿主无法指定时留在当前运行并说明原因。不跨厂商改写模型名，不臆造参数，不另启 CLI。带 `tier=` 的受托者不再次迁移整次运行，并按自身会话溯源记录实际模型。

## 角色

通过修改代码和运行轻量验证，推动一份 **leaf 执行子计划**达到完成判据。上游 `star-plan-decomposer` 拥有子计划的策略和任务拆解；本 skill 拥有实现结果：`${CODE_NAME}/` 下的代码、`tasks/<plan-name>/` 下的中间工作文件，以及 `wkdrs/<run>/` 下的生成产物与验证证据。从所选计划文件名去掉 `_plan.md` 得到 `<plan-name>`（例如 `00_demo_plan.md` → `tasks/00_demo/`）。

只执行；不要重新制定策略或静默重新分解。若 §3 或 §5 模糊到无法执行，报告具体缺口并转回 `star-plan-decomposer`。

## 核心原则

1. **先读后写。** 规划修改前，检查 `.env`、写明的输入、相关代码和实际运行界面。列出当前状态与所需状态的差距。遵循 `references/orient_checklist_zh.md`。
2. **让计划可见，然后在范围内推进。** 把子计划转成 `EXEC_PLAN`，其中每个 action 都写明文件、命令、产物和范围受限检查。用你的计划工具跟踪它——一个 action 一个步骤，进行中的 action 都标为 `in_progress`——并在 commentary 中总结计划。调用 executor 即授权普通的范围内实现与轻量验证；只有决定会实质改变范围或需要新授权时，才请求新方向。
3. **该委派的就委派。** 怎么切分由主 agent 自己定。协作工具可用、且有边界、相互独立的工作确实能从委派中受益时就委派——这是常态，不是例外。满足条件时，调用你的子代理工具：实现工作使用可写子代理，只读勘察使用只读子代理。绝不为每个琐碎顺序步骤创建一个 subagent。给每个受委派者 `references/agent_dispatch_spec_zh.md` 中那份范围很窄的交办说明；主 agent 始终负责集成和核验检查。确切命令/原始结果可检查、且绑定对应代码版本时可以采用；溯源缺失或过期、以及整合改变相关行为后，重跑最窄检查。那份文件里的树状态纪律——action 起点快照、重试前恢复、`blocked` action 编辑有明确或已记录的处理决定——同样约束本地执行，且绝不抹掉既有/用户工作或原始证据。
4. **在未获授权的重型或不可逆工作前停止。** 长时间或多 GPU 训练、全数据集评估、高成本 API 调用、无边界任务、覆盖有价值产物都会跨越 STOP line。准备可复现命令、成本与产出。只有具体适用的用户授权或边界内的 `star-auto` 例外才可启动；否则交给用户。遵循 `references/stop_line_rules_zh.md`。
5. **记录已验证状态——并保持子计划真实。** 把 `EXEC_PLAN.md` 和 `EXEC_LOG.md` 存在 `wkdrs/<run>/`。每次范围受限检查后更新日志。子计划 frontmatter 只维护 `exec_status`、`exec_runs`、`updated`；仅当执行确实偏离子计划，或确定了计划留空而 method 文档会引用的值时，才对受影响 §2–§5 做一次**已授权的回同步**并添加 `## Revision History`（`references/plan_sync_rules_zh.md`），使用户日后重读的计划与实际执行一致。已有具体授权直接沿用；泛泛的实现请求与 `auto=unattended` 都不授权改变研究范围或 §5 验收。
6. **使用项目运行时和布局。** 从 `.env` 读取 `CONDA_HOME`、`PYTHON_HOME`、`CODE_NAME`；绝不猜本地路径或使用系统 Python。若项目入口是 `execs/run.sh`，就使用它。创建 `tasks/<plan-name>/` 存放执行该计划时所需中间文件；可复用运行脚本放 `execs/scpts/`；生成输出和持久执行记录放 `wkdrs/<run>/`；数据放 `datas/`；权重放 `inits/`；代码放 `${CODE_NAME}/`。遵循 `AGENTS.md`。

## 工作流

**本次运行在哪里执行。** 整体运行属于 PLAN；仍有必需决定时留在可与用户交互的会话。Step 4（执行与验证）按后文交给 EXEC。既有执行授权同样有效；带 `tier=` 的受托者不再次转交同一阶段。

### Step 0：解析目标

1. 按 slug、数字前缀或完整文件名，把 `PLAN_NAME` 与开场装载的摘要列出的计划匹配；它就是那份清单，不必再列一次目录。
2. 只有 leaf 可执行。若目标的 `children:` 非空，列出其 leaf 并询问执行哪一个（推荐第一个就绪的 leaf），或提议按依赖顺序逐个处理。
3. 目标不存在或有歧义时，列出简洁候选，只问一个直接问题。
4. 完整读取所选子计划。

### Step 1：检查就绪状态

1. 要求具体的 §3 任务分解与 §5 完成判据。若大部分是 `[TBD]` / `【待定】`，报告缺失决定，询问是返回 `star-plan-decomposer`（推荐），还是在明确记录剩余不确定性的前提下继续。
2. 验证写明的数据集、权重、代码模块和每个 `depends_on` 兄弟叶子——从已带着每个兄弟 frontmatter 的摘要读它们的状态，不要逐个打开。若硬依赖缺失或上游兄弟叶子未达到 `exec_status: done`，停止并报告准确 blocker。缺失数据集或权重是分解缺口，不能绕过：指明应负责它的 data-readiness leaf，或转回 `star-plan-decomposer <parent>` 添加一个。
3. 拒绝执行带着 `dropped:` 的叶子、或祖先被丢弃的叶子：点名丢弃写在哪个节点上，然后停下。要重新启用它，先用 `star-plan-reviser` 清掉那个字段——照跑一个用户已经否掉的方向，只会把算力花在没有任何东西会去统计的工作上。
4. 检查 leaf 的尺寸是否合适。能执行的 leaf 未必是合适的工作单元，而拆完之后没有任何环节再看一眼。把 decomposer 用在自己草稿上的那条尺寸判据——一块可独立检验的工作（它的 `references/subplan_rubric_zh.md` 第 8 条）——拿来对着计划当下的样子再判一次；所有信号都在 Step 0 已经读进来的正文里，这一检查不额外花任何一次调用。**强信号，任一条成立即触发**：§5 写了不止一个彼此独立的检查；§3 越过 STOP line 不止一次，每一次把命令交回用户都是天然的 leaf 切口；§3 把取数据、建代码、跑实验混在同一个单元里，而数据集本该自成一个 leaf。**弱信号，两条同时成立算一条强信号**：§3 步骤数超过 12；§4 的产物横跨互不相关的产物族，或不止一个 run 目录。只有一条弱信号时，在报告里写一句话，不要发问——打断一个尺寸本来就合适的 leaf，代价比漏掉一个过大的 leaf 更高。检查命中时，照 `references/sizing_check_zh.md` 走：提问之前展示的拆分预览、问题本身与两个答案各自的代价、以及判定结论记在哪里。`exec_runs` 非空的 leaf、或有运行正在某个分支或 worktree 上进行的 leaf，直接跳过这一检查：运行途中拆分，会把那次 run 的 `wkdrs/<run>/` 挂在一个再没有执行器会光顾的节点上——正是 `star-plan-decomposer` 会停下来警告的事。

### Step 2：定位

遵循 `references/orient_checklist_zh.md`：

1. 读取 `.env`，解析 `CODE_NAME`、`CONDA_HOME`、`PYTHON_HOME`（规约 §3）。若这些路径指定的环境缺失或无法运行 Python，推荐执行前先用 `star-env-builder` 构建。
2. 映射 `${CODE_NAME}/`；若其中没有实现则声明空代码库（从零起步），或先用 `star-code-architect` 引入参考代码库。
3. 把每个 §3 步骤追踪到真实文件，并分类为 exists / modify / create。
4. 确认实际 run 入口和测试入口。

### Step 3：构建并写出 EXEC_PLAN

1. 把 §3 和缺口清单细化成有序 action。每个 action 必须绑定 `{files / command through project env / artifact / check}`；最后一个 action 绑定 §5 完成判据。action 清单要朝 Step 4 委派时的成组派遣去塑（`references/agent_dispatch_spec_zh.md`）：相邻 action 碰同一批文件、收在同一个 check 里的，写成一组（至多 3 个），不留成各自委派——每省一次委派，就少开一个全新的子代理上下文，而检查粒度不受损：一组仍只收在它那一个 check，遇 STOP line 边界照样拆开。
2. 明确标出 STOP line；已知时估算运行时间/成本。画完的计划是对 leaf 尺寸的第二次读数：若计划落成后 action 数超过 12、或越过 STOP line 不止一次，而 Step 1 的尺寸检查没有命中，把这件事带到第 5 条作为一项实质选择——实现开始前先回去拆分，或照计划原样执行——而不是单开一个问题。
3. 把 EXEC_PLAN 相对子计划 §2–§5 的实质性出入，以变更项形式（ADDED / MODIFIED / REMOVED / ENRICHED）记入 EXEC_PLAN 的“与子计划的偏差”表。与子计划自身粒度相矛盾算偏差；“更具体”不算——除非那是计划未写明、而某份方法文档会引用的值，那要记为一条 ENRICHED 行并写明该章节。偏差表非空时才读 `references/plan_sync_rules_zh.md`：它是第 6 条与 Step 5 执行的回写流程，空表两处都不跑。
4. **定下分支与 worktree 两行**（规约 §11）：EXEC_PLAN 里只要有 action 要修改 `${CODE_NAME}/` 下已存在的被跟踪文件，计划就带上 `branch: <run>` 并推荐在它上面执行；只新增文件、或只写 `tasks/<plan-name>/` 与 `wkdrs/<run>/` 的计划带 `branch: none`。把 checkout 当前所在分支记为 `base:`，无论它叫什么。worktree 这一行答的是当前 checkout 此刻腾不腾得出来（§11.7）：任一忙碌信号命中（HEAD 停在别的 run 的执行分支上；未提交改动的路径归属别的 run 的记录；有命令交回了用户、结果还没回收——可能有任务在跑；或用户明说要并行）→ `worktree: ../<根目录名>--wt/<run>`，并连带把 `branch: none` 改成 `branch: <run>`（§11.8）；无信号 → `worktree: none`。已有适用选择就沿用。两项都未定时，`low` 采用并记录推荐项，`medium` 随计划一并询问，`high` 把每项未定裁量分开问。两行只要有一行不是 `none` 就读 `references/branch_rules_zh.md`；它规定创建、提交、续跑、合并授权、冲突处理和保全产物的清理。
5. 在 commentary 中展示简洁计划和它会做出的改动。普通的范围内实现与轻量验证之前没有总批准门槛。逐 action 提交是推荐项：已有选择就沿用；没有时，`low` 采用并记录，`medium`/`high` 按规约 §7.7 询问。绝不暂存既有改动。偏差行按 `references/plan_sync_rules_zh.md` 处理：沿用具体适用授权；`auto=unattended` 只覆盖实质上不改变研究范围、关键输入、§5 验收与已批成本的行；仍未决定的实质行一次性询问。已有授权的 STOP-line 启动不重复问，但仍须满足 `references/stop_line_rules_zh.md` 要求的具体命令、成本和最新审查。
6. 先按 `references/branch_rules_zh.md` 的“创建”建起已记录的分支或树，让下面的一切都生在它上面。`<plan-name>` 取所选文件名去掉 `_plan.md`，为计划中间文件创建 `tasks/<plan-name>/`。**run 名为 `<prefix>_<slug>`**；重跑时追加用户给的后缀（`_v2`、某个日期）以示区分，该目录已存在但不是此 leaf 可恢复的 run 时，问一个后缀——绝不自行编造。从匹配语言的模板创建 `wkdrs/<run>/EXEC_PLAN.md`，并在同目录初始化 `EXEC_LOG.md`。把子计划 frontmatter 更新为 `exec_status: in_progress`，并将本 run **追加**到 `exec_runs`，不能替换最后一项。仍使用单个 `exec_run:` 的计划先迁移为 `exec_runs: [<that run>]`。此时把获授权的偏差行同步进子计划：原地更新受影响的 §2–§5 段落，追加 `## Revision History` 条目，从系统时钟更新 `updated`，并把每行标为 `synced`。


**实现前先跑设计检查。** 把 `references/design_check_zh.md` 交出去做一次“不知情”的复核：派一个只读子代理跑在 PLAN 档的模型上（规约 §10.8，前提是宿主能指定），交办材料正好三个文件——刚写出的 EXEC_PLAN、叶子子计划、根计划只读它的 §4——范围逐字写明：“只看这三个文件，根计划只看 §4。不排序、不决定、不运行任何东西。”它按条返回 `item`、`verdict: pass | fail | unclear`、`evidence`、`fix`。每条 `fail` 都重开所引证据；在已授权计划内纠正执行计划缺陷，只有发现留下研究范围、验收、关键输入或成本未定时才询问。没有受托者可用时，本地跑一次清单并记录缺少独立读者；不反复询问宿主没有的工具。

**把 Step 4 交给 EXEC 档。** EXEC_PLAN、EXEC_LOG 与当前所需决定都已记下，宿主支持且配置了不同的 EXEC 模型、本 run 又不是 `tier=exec` 受托者时，派一个可写子代理读取本说明并从 Step 4 恢复，带上 `involve=<level> tier=exec` 与合法的 `auto=unattended` 授权。它不得修改 EXEC_PLAN，也不得绕过计划级缺口自行发挥。STOP-line 命令或 blocked 编辑仍未决定时，记入日志并返回可与用户交互的运行；已有适用决定直接沿用。返回后重读 EXEC_LOG，从 Step 5 继续。没有可用 override 或委派路线时就在本地跑 Step 4，不为宿主缺少的机制反复询问。
### Step 4：执行与验证

主 agent 按依赖关系自主调度未完成的 action——独立 action 并发还是逐个由它自行判断（`references/agent_dispatch_spec_zh.md`）。带 `tier=exec` 的受托者只跑这一步：从第一个未完成的 action 接手，本步一结束就返回，Step 5 留给派它出来的那次运行。对每个 action：

1. 决定本地执行还是委派。委派时调用你的子代理工具，实现工作使用可写子代理、跑在 EXEC 档的模型上（只读勘察用只读子代理，跑在 READ 档的模型上），遵循 `references/agent_dispatch_spec_zh.md`，并保持文件所有权不重叠。
2. 只做该 action 必需的修改，并通过项目环境运行其范围受限检查。
3. 按 `references/agent_dispatch_spec_zh.md` 审查 diff 并核验 action 检查。确切命令、退出状态/结果、原始日志或产物、对应代码版本都可检查时，可以采用原次证据；溯源缺失或过期、以及整合改变相关行为、依赖或被检代码后，重跑最窄的受影响检查。通过后记录证据和产物路径；已记录选择启用逐 action 提交时才提交，执行分支上只连带暂存本 action 引起的运行记录更新（规约 §11.2）。失败时保留原始证据，只从 action 起点快照恢复归该 action 所有的增量，绝不抹掉既有/用户工作。存在具体修正时最多重试两次，否则标 `blocked`；已有适用的编辑处理决定就沿用，没有时只询问仍缺少的破坏性权限，然后停止。
4. action 跨越 STOP line 时，准备准确命令（还可选写入 `execs/scpts/<run>.sh`），记录到 `Awaiting user`，连同预计成本（GPU 数 × 小时，或调用次数与费用）、产出和代码版本。按 `references/stop_line_rules_zh.md` 处理：有具体授权的普通启动或合法 `star-auto` 启动，只有审查与成本守卫通过后才执行；否则交给用户。`tier=exec` 受托者到此返回，绝不自行启动。
5. 若重试或 blocker 在子计划粒度改变了方法（新增/删除/替换步骤，交付物路径或完成判据变化），在 EXEC_LOG 的 `Pending amendments` 下记录变更项。继续与其无关的已授权工作，但研究范围、关键输入或完成判据的变化未经具体授权前，绝不依赖它继续推进。

### Step 5：完成

1. `Pending amendments` 非空时按 `references/plan_sync_rules_zh.md` 处理：沿用已记录的具体决定，只把仍未决定的行呈现一次；获授权的行带 Revision History 溯源写回，`updated` 日期取系统时钟。`auto=unattended` 只覆盖实质上不改变研究范围、关键输入、§5 验收与已批成本的推荐战术行；节号或 ENRICHED 标签不扩权。父计划或 kill-criterion 变化通过第 5 点的方向性信号转交。
2. 检查 `references/exec_rubric_zh.md`，报告前修复范围内的失败；最多列出五个剩余失败及具体补救方法。
3. 核验子计划 §5 完成判据，把确切命令、原始结果/产物和对应代码版本记入 `EXEC_LOG.md`。这些内容可检查时采用已有有效证据；不为让主 agent 声称亲自执行而重复每项测试或昂贵命令。仅在溯源缺失/过期或相关整合发生变化时重跑。 此后若代码、关键输入或验收发生变化，受影响证据即失效：重开对应状态，运行必要的最窄检查，按当前判据重新成立后才能再次置为 `done`。
4. 满足时，把 run 与子计划 `exec_status` 设为 `done`。默认保留 `tasks/<plan-name>/` scratch 和计划自有工具脚本，并在报告中写明位置。只有用户具体要求、且持久产物与证据已提升到 `wkdrs/<run>/` 后才删除指定文件；`auto=unattended` 不提供 scratch 删除授权。未满足时，按 §6 的本地备选方案处理，或报告已验证缺口。
5. 若结果命中根计划 kill-criterion 或使低开销 MVP 假设失效，在日志中记录 **方向性信号**，并推荐 `star-plan-reviser <slug>`（审计证据并修订计划）、`star-plan-coach <slug>` 或 `star-plan-decomposer <slug>`。不要编辑父计划的策略章节。


### Step 6：报告

以结果开头。说明验证了什么及其证据，默认保留的 `tasks/<plan-name>/` 工作区和 `wkdrs/<run>/` 记录/产物的位置，哪些命令等待启动授权或结果，哪些 amendment 已同步，以及剩余风险。点出 Step 7 将在任何待跑重命令之前启动独立审查。确认的 blocker/major 发现及审查获授权应用的修复，经 `star-plan-executor <leaf>` 回来；它用新检查或可归属的原始证据核验受影响 action，才重试启动。执行分支审查干净后抵达 `references/branch_rules_zh.md` 的合并授权点：已有具体合并授权就沿用，否则询问。点出分支未合并状态及 worktree 路径。重型产出出现后，`star-expt-analyst <leaf>` 按 §5 评分并解释。报告控制在约 500 词以内。

### Step 7：审查并返回执行目标

当前执行器仍负责完成用户的执行目标。重命令启动或合并前，对该叶子运行 `star-code-reviewer`；已有审查覆盖当前代码版本和范围、且待启动时满足现有启动守卫，才直接复用。传递已有执行目标及授权，并要求复核器把证据与控制权交回这个执行器。单独的只复核请求不具有这条接续。

1. 无论返回的是干净报告、问题项还是已获授权应用的修复，都检查报告。按 Steps 4–5 重开受影响 action 并验证新代码；依赖新增实质决定前先解决它。独立复核仍必需；宿主无法提供时，本地做一次并记录限制。
2. 审查有效且没有未解决 blocker/major 时，恢复待执行的已授权动作：按 `references/stop_line_rules_zh.md` 启动，随后收集结果并回 Step 5；或在叶子完成后按 `references/branch_rules_zh.md` 合并。缺启动或合并权限时，交回具体待办。启动归父级 `star-auto` 所有时，将控制交回该启动器。
3. 不仅因为控制返回或日志更新就重新评审。代码版本与覆盖仍有效时复用同一报告；新的相关代码修改需要在继续前评审受影响范围。现有启动守卫要求更新日期的报告时，交回复核器核对未变的来源版本并刷新报告，绝不绕过守卫。避免复核器与执行器围绕未改变的工作无限循环。

## 状态与文件规则

- 把 `wkdrs/<run>/EXEC_LOG.md` 视为执行事实来源。再次调用时——`exec_runs` 非空的 leaf 就属于这种情况——读取该列表最后一项对应的 run，从第一个未完成项恢复。
- **已经有记录的运行是接着跑，不是重新规划。** 摘要里 `exec_runs` 非空、有以该 leaf 命名的分支、或 `wkdrs/<run>/` 已存在，三者任一都表示有运行在进行中：读 `references/resume_rules_zh.md` 并照它走——从哪里接着跑、分支或 worktree 改变什么、审查的 blocker 发现如何重开工作、执行分支最终抵达哪个合并授权点——而不是把这片 leaf 重新规划一遍。三者都没有的 leaf 从不读它。
- `tasks/<plan-name>/` 存放该计划自有的持久工具脚本与 scratch，两者默认保留。生成产物与持久证据放在 `wkdrs/<run>/`；只有用户具体要求、且相关内容已提升后才删 task 文件，也绝不触碰其他计划的 `tasks/` 目录。
- 可以自由编辑子计划 frontmatter 的 `exec_status`、`exec_runs`、`updated`；只有通过授权一次即沿用的回同步协议（`references/plan_sync_rules_zh.md`）才能编辑其 §2–§5，且始终原地更新并配对一个 `## Revision History` 条目。绝不重写 §1 或 §6，绝不触碰父计划——objective 或 strategy 级偏差转交 `star-plan-reviser` / `star-plan-coach` / `star-plan-decomposer`。
- Git：按已记录的项目默认值，每个已验证 action 一个 commit，只暂存该 action 触碰的文件及执行分支上由它引起的运行记录更新（规约 §1）。分支/worktree 创建是常规可逆隔离选择；合并、弃用、移除与删除按 `references/branch_rules_zh.md` 沿用已有具体授权或询问。绝不 rebase、抹掉用户改动或证据、删除记录未回基础分支的 branch，也不在产物移出前或用 `--force` 移除 worktree。
- 允许的 action status：`pending` / `in_progress` / `done` / `blocked` / `skipped`。

## 对话纪律

- 非交互运行中继续普通的已授权实现与轻量验证。仍有必需决定、又没有提问接口时，用纯文本呈现具体问题，只停止依赖它的动作，并继续与其无关的已授权工作；沉默或经过一段时间绝不是批准。
- **问题所指的内容写在同一条消息正文、排在调用之前**——例如仍未决定的 amendment、验收变化或具体成本承诺。选项承载答案，不隐藏材料。
- 匹配用户的对话语言，同时保留计划正文 frontmatter 的 `language`；中文计划中的技术术语保留英文。
- 参与度档位（规约 §7.7）控制仍未决定的裁量事项，不撤销已有授权。提交、分支与 worktree 选择：`low` 采用推荐项，`medium` 把未定项一并问，`high` 分开询问；已有适用选择绝不再问。研究范围、§5 验收、关键输入、成本/启动权限、覆盖、弃用、移除、删除或所有权歧义仍未解决时必须定下。`auto=unattended` 只增加规约写明的战术计划、经审查启动、干净 squash、非删除修复与空 worktree 授权；不授权研究或验收变化、merge conflict 消解、证据丢失、scratch 删除或其他破坏性动作。生效档位、来源和每项决定在 `EXEC_LOG.md` 各记一次。
