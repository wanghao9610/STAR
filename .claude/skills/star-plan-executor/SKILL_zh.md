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

**把档位模型传给受托者。** 派发前取 `claude` 条目，没有则取不带标签的备选。该档每次派发都把解析值传给 `Agent` 的 `model`；键为空则省略。模型须为当前工具所接受，后文规定的角色与写入限制照旧。盲读只拿产物与量表，不继承产出该工作的对话。模型不可用就留在这里并说明一条原因；派发被拒后，须确认它尚未开始工作才能退回本地。受托者从自己的会话溯源解析实际模型，不从请求中的别名或父会话转录取值。

## 角色

你通过修改代码、跑轻量验证，把一份**叶子执行子计划**推到完成判据。上游 `star-plan-decomposer` 产出可执行子计划（§1 目标 / §2 输入与依赖 / §3 任务分解 / §4 产出物 / §5 完成判据 / §6 局部风险）；本 skill 产出**结果**：`${CODE_NAME}/` 下的代码、`tasks/<plan-name>/` 下的中间工作文件、`wkdrs/<run>/` 下的生成产物与持久执行记录，以及一条验证过的完成判据。`<plan-name>` 取选定计划文件名去掉 `_plan.md` 后的部分。

你**只执行,不重做研究规划、也不重新拆解**。若 §3 或 §5 太模糊、无法执行,把用户送回 `star-plan-decomposer`。

## 核心原则

1. **先读再写**。动手规划任何改动前,先在 `${CODE_NAME}/` 里勘察:读子计划 §2 指向的模块/入口,产出一份"现状 vs §3 要求"的缺口清单。绝不假设代码已存在;`code/` 可能是空的(只有 `.gitkeep`),此时计划从零搭骨架——更好的做法是先用 `star-code-architect` 搭好参考代码库。参见 `references/orient_checklist_zh.md`。
2. **让计划可见，再在范围内推进。**把子计划转成 `EXEC_PLAN`，逐 action 写明文件、命令、产物与检查。只有仍有实质决定时才用 `EnterPlanMode` / `ExitPlanMode`；否则在 commentary 展示计划后直接继续，不另设批准门槛。调用 executor 已授权普通范围内实现与轻量验证；只有改变范围或需要新增权限时才请求方向。
3. **该委派时才委派。**有边界、相互独立的工作确实受益时，派 `Agent` subagent：实现用 `subagent_type: general-purpose`，只读勘察用 `Explore`，档位模型值非空时传给 `model:`。不给琐碎串行步骤逐个开代理。主 agent 负责集成与核验，可采用绑定代码版本的可归属原始证据，仅在溯源缺失/过期或整合改变相关行为时重跑。action 起点快照与 blocked 编辑决定绝不抹掉既有/用户工作或原始证据。
4. **在未获授权的重型或不可逆工作前停。**长时/多卡训练、全量评测、高成本 API、无界任务与覆盖有价值产物都越过 STOP line。备好可复现命令、成本与产出；只有具体适用的用户授权或边界内 `star-auto` 例外才启动，否则交给用户。见 `references/stop_line_rules_zh.md`。
5. **记录已验证状态，并保持子计划真实。**执行记录存在 `wkdrs/<run>/`，中间工作文件在 `tasks/<plan-name>/`。每个 action 检查后更新日志。子计划 frontmatter 只维护 `exec_status`、`exec_runs`、`updated`；偏差或方法文档会引用的补充值只通过一次授权后沿用的回同步流程写入 §2–§5 并追加 `## Revision History`。泛泛实现请求和 `auto=unattended` 都不授权改变研究范围或 §5 验收。
6. **使用项目运行时和布局。**从 `.env` 读取 `CONDA_HOME`、`PYTHON_HOME`、`CODE_NAME`，不用系统 Python 或猜测路径。项目入口存在时用 `execs/run.sh`；中间文件放 `tasks/<plan-name>/`，脚本放 `execs/scpts/`，产物与记录放 `wkdrs/<run>/`，数据、权重和代码分别放 `datas/`、`inits/`、`${CODE_NAME}/`。遵循 `CLAUDE.md`。

## 工作流

**本次运行在哪里执行。**整体运行属于 PLAN；仍有必需决定时留在可与用户交互的会话。执行—验证阶段按后文交给 EXEC。既有执行授权继续有效；带 `tier=` 的受托者不再次转交同一阶段。

### Step 0：定位目标计划

1. 解析 `PLAN_NAME`(slug / 数字前缀 / 完整文件名),与开场装载的摘要列出的计划匹配;它就是那份清单,不必再列一次目录。
2. **只有叶子可执行**。若 `PLAN_NAME` 命中一个有子节点的节点(`children:` frontmatter 非空),不要直接执行它:列出它的叶子(前缀 + slug + 一句话目标),用 AskUserQuestion 让用户选执行哪一个(推荐依赖顺序中第一个就绪的),或提议按依赖顺序一次一个地执行它们。
3. 若未给参数或匹配有歧义，列出可选计划并通过 AskUserQuestion 询问。
4. 完整读取选定的子计划。

### Step 1：就绪检查

1. **可执行性**。§3 任务分解与 §5 完成判据必须具体。若仍大量是 `[TBD]` / `【待定】`,说明拆解尚未完成,用 AskUserQuestion 提供:*先回 `star-plan-decomposer` 补完*(推荐) / *仍然执行(较浅,缺口保留 `【待定】`)*。
2. **依赖**。检查 §2 输入与依赖:指定的数据集(`datas/`)、权重(`inits/`)、代码模块是否就位?叶子 `depends_on` frontmatter 列出的上游兄弟叶子是否都已 `exec_status: done`?从已带着每个兄弟 frontmatter 的摘要读它们的状态,不要逐个打开。若硬依赖缺失,**停下上报**——缺失的数据集或权重是拆解上的缺口,不是绕开就行的 blocker:指明本该负责它的数据就绪叶子,或转交给 `star-plan-decomposer <父计划>` 去补一个。不要伪造输入。
3. **未被丢弃**。带着 `dropped:` 的叶子、或祖先被丢弃的叶子，一律不执行：点名丢弃写在哪个节点上，然后停下。要重新启用它，先用 `star-plan-reviser` 清掉那个字段——照跑一个用户已经否掉的方向，只会把算力花在没有任何东西会去统计的工作上。
4. **尺寸合适**。能执行的叶子未必是合适的工作单元，而拆完之后没有任何环节再看一眼：这份计划可能是几周前拆的，也可能是手写的。把 decomposer 用在自己草稿上的那条尺寸判据——一块可独立检验的工作（它自己的 `references/subplan_rubric_zh.md` 第 8 条）——拿到这里，对着计划当下的样子再判一次。所有信号都在 Step 0 已经读进来的正文里，这一检查不额外花任何一次调用。

   - **强信号，任一条成立即触发**：§5 写了不止一个彼此独立的检查；§3 越过红线不止一次，每一次把命令交回用户都是天然的叶子切口；§3 把取数据、建代码、跑实验混在同一个单元里，而数据集本该自成一叶。
   - **弱信号，两条同时成立算一条强信号**：§3 步骤数超过 12；§4 的产物横跨互不相关的产物族，或不止一个 run 目录。

   只有一条弱信号时，在回复里写一句话，不要发问——打断一个尺寸本来就合适的叶子，代价比漏掉一个过大的叶子更高。检查命中时，照 `references/sizing_check_zh.md` 走：写在问题之上的拆分预览、问题本身与两个答案各自的代价、以及判定结论记在哪里。

   **只在全新运行时判，且只问一次**。`exec_runs` 非空的叶子、或有运行正在某个分支或 worktree 上进行的叶子，直接跳过这一检查：运行途中拆分，会把那次运行的 `wkdrs/<run>/` 挂在一个再没有执行器会光顾的节点上——正是 `star-plan-decomposer` 会停下来警告的事。

### Step 2：勘察代码库

遵循 `references/orient_checklist_zh.md`:

1. 读 `.env`,解析 `CODE_NAME`、`CONDA_HOME`、`PYTHON_HOME`(规约 §3)。若这些路径指向的环境缺失或无法运行 python,建议先用 `star-env-builder` 构建后再执行;run 需要而环境里没有的包,走 `star-env-builder add <包名>`——本 skill 自己不装任何东西。
2. 摸清 `${CODE_NAME}/`。若为空,声明 **空代码库（从零起步）**。
3. 对每个 §3 步骤,判断做它的代码是**已存在 / 需修改 / 需新建**——这个映射就是**缺口清单**。

### Step 3：建立可执行计划

1. 只有 EXEC_PLAN 仍含需要用户决定的实质选择时才用 `EnterPlanMode`。`low` 档，或目标、研究范围、验收、关键输入、成本和权限都已定下时，在 plan 模式外起草，不制造新的批准门槛。
2. 把 §3 + 缺口清单细化成 **EXEC_PLAN**:一串有序动作,每个标注 `{要碰的文件 / 要跑的命令(走 conda) / wkdrs/<run>/ 下的产物 / 绑定的 check}`。末尾动作绑 §5 完成判据。动作清单要朝 Step 5 成组派遣的形状去塑(`references/agent_dispatch_spec_zh.md`):相邻动作碰同一批文件、收在同一个 check 里的,写成一组(至多 3 个),不留成各自派遣——每省一次派遣,就少开一个全新的 subagent 上下文,而检查粒度不受损:一组仍只收在它那一个 check,遇红线边界照样拆开。
3. 按 `references/stop_line_rules_zh.md` 明确 STOP line 并估算运行时间/成本。若计划超过 12 个 action 或多次越线而 Step 1 未命中，把它作为一项实质选择：先拆分再实现，或照原计划执行。已有选择就沿用，否则在依赖它的工作前询问。
4. **收集实质性偏差**:把 EXEC_PLAN 相对子计划 §2–§5 的实质性出入,以变更项形式(ADDED / MODIFIED / REMOVED / ENRICHED)记入 EXEC_PLAN 的"与子计划的偏差"表。与子计划自身粒度相矛盾算偏差;"更具体"不算——除非那是计划未写明、而某份方法文档会引用的值,记为一条 ENRICHED 行并写明该章节;点不出会引用它的那一节,就是细节。偏差表非空时才读 `references/plan_sync_rules_zh.md`:它是 Step 4 与 Step 6 执行的回写流程,空表两处都不跑。
5. **定下分支与 worktree 两行**（规约 §11）：修改 `${CODE_NAME}/` 的既有跟踪文件推荐 `branch: <run>`；只新增文件或只写 `tasks/`、`wkdrs/` 推荐 `branch: none`。记录当前分支为 `base:`。忙碌信号推荐 worktree 并强制使用分支；任务状态不明时优先隔离，不切换可疑 checkout。已有选择就沿用；否则 `low` 取推荐，`medium` 随计划一起问，`high` 分开问。任一行非 `none` 时读 `references/branch_rules_zh.md`。

### Step 4：解决剩余决定并记录计划

**实现前先跑设计检查。** 派一个只读 `Agent` subagent（`subagent_type: Explore`，PLAN 档值非空时传给 `model:`）只读 EXEC_PLAN、叶子计划和根计划 §4。每条 `fail` 都重开所引证据；在已授权计划内纠正执行计划缺陷，只有研究范围、验收、关键输入或成本仍未解决时才问。`Agent` 不可用时本地跑一次并记录缺少独立视角，不反复请求宿主没有的机制。

1. 在 commentary 中展示具体计划。若使用了 `EnterPlanMode`，只用 `ExitPlanMode` 解决随计划展示的未定实质选择；已有适用授权直接沿用。逐 action 提交为推荐：已有选择沿用，否则 `low` 采用、`medium` 随计划询问、`high` 分开询问。偏差按 `references/plan_sync_rules_zh.md` 处理；`auto=unattended` 只覆盖不改变研究范围、关键输入、§5 验收和已批成本的战术行。
2. 必需决定全部解决后，按 `references/branch_rules_zh.md` 创建已记录的分支或树，再创建 `tasks/<plan-name>/`、`wkdrs/<run>/EXEC_PLAN.md` 与 `EXEC_LOG.md`。把 run 追加到 `exec_runs`，保留既往记录；旧 `exec_run:` 先迁移。已有同名非可恢复 run 时使用用户给出的后缀。
3. **把获授权偏差同步回子计划。**原地更新受影响的 §2–§5，追加 `## Revision History`，从系统时钟更新 `updated`，并把对应行标为 `synced`。研究范围、关键输入、§5 验收或成本变化仍未决定时继续询问。

**把 Step 5 交给 EXEC 档。** EXECPLAN、EXEC_LOG 和当前必需决定均已记录，且配置了不同 EXEC 模型、本 run 不是 `tier=exec` 时，派一个 `Agent` subagent（`subagent_type: general-purpose`、`model:` 取该 EXEC 值）读取本说明并从 Step 5 恢复，带上 `involve=<level> tier=exec` 与合法 `auto=unattended`。它不得改 EXEC_PLAN 或绕过计划级缺口。STOP-line 命令或未决 blocked 编辑记入日志并返回用户侧运行；已有适用决定直接沿用。返回后重读日志并进 Step 6。无可用 override 或 `Agent` 路径时在本地执行，不反复请求不可用机制。

### Step 5：执行—验证循环（每步一个 agent）

对 EXEC_PLAN 的步骤,主 agent 按依赖关系自主调度——独立步骤并发还是串行由它自行判断(`references/agent_dispatch_spec_zh.md`)。带 `tier=exec` 的受托者只跑这个循环:从第一个未完成的步骤接手,循环一结束就返回,Step 6 留给派它出来的那次运行。对每个步骤:

1. 按 `references/agent_dispatch_spec_zh.md` 的交办说明派一个 `Agent` subagent（`subagent_type: general-purpose`；只读勘察可用 `Explore`；`model:` 取开场装载返回的 EXEC 档值，只读勘察那种情况取 READ 档值，键为空时不带这个参数）:本步目标、要碰的确切文件、已解析的解释器路径、绑定的 check,以及"**只**做这一步;返回结构化结果(changed / ran / check / blockers / handoff)"。
2. 检查 diff，并按 `references/agent_dispatch_spec_zh.md` 核验 action 的 check。原始证据可检查且绑定代码版本时直接采用；溯源缺失/过期或整合改变相关行为时才重跑。通过则记证据并按已定选项提交；失败则保留原始证据，只恢复 action 自有增量，有具体修正时最多重试两次，否则标 `blocked`，沿用已有编辑处理决定或询问缺失的破坏性权限。
3. **action 越过 STOP line 时**，在“待用户执行”记录命令、预计成本、产出和代码版本。普通运行已有具体授权或合法 `star-auto` 时，也只有审查与成本守卫通过后才启动；否则交给用户。`tier=exec` 受托者在此返回，绝不自行启动。
4. 重试或 blocker 改变子计划粒度做法时，记一行“待同步修正”。可继续与该变化无关的已授权工作，但研究范围、关键输入或完成判据未具体授权前不得依赖新值。

主 agent 回复保持精简;细节都在日志里。

### Step 6：收尾 / 完成判据验证

**修正同步（战术信号）。**先应用已有具体决定，只把未决行摊在正文并通过 AskUserQuestion 按规约 §7.13 问一次。`auto=unattended` 只覆盖不改变研究范围、关键输入、§5 验收和已批成本的推荐战术行；章节号或 ENRICHED 标签不会扩大授权。已授权行按 `references/plan_sync_rules_zh.md` 写回。触及 §1/§6、父计划或 kill-criterion 的是方向性信号，不在此同步。

**执行评分表。**先检查 `references/exec_rubric_zh.md`，修复范围内失败后才能声称完成；最多报告五条剩余失败及具体补救方法。

**完成判据。**修正同步与评分表修复都处理完后才核验 §5。已有证据可归属且仍有效时直接采用；溯源缺失/过期或整合改变相关行为时才重跑。此后代码、关键输入或验收变化会使受影响证据失效并重开状态。达标才把 run 与子计划设为 `exec_status: done`，默认保留 `tasks/<plan-name>/` 的 scratch 和工具脚本并报告位置；只有用户具体要求、且持久证据已提升到 `wkdrs/<run>/` 后才删除，`auto=unattended` 不授权删 scratch。未达标则走 §6 或报告缺口。

**向上反馈(方向性信号)**。若结果与父计划依赖的某个假设相悖——即撞上根计划 §5 的 **kill-criterion**,或计划称为"便宜早测"的 MVP 完成判据返回了负面结果——你不改父计划 §1–§6(那归 coach/decomposer)。而是:把它记进本轮 `EXEC_LOG.md` 的"备注 / 决策"(这个文件本 skill 拥有),并在 Step 8 简报里**显式点出**,建议回 `star-plan-reviser <slug>`(审计证据并在逐条批准下修订计划)、`star-plan-coach <slug>`(重审风险/方法)或 `star-plan-decomposer <slug>`(重新拆分子计划)。

### Step 7：进度记录与续跑规则

- **唯一依据**:`wkdrs/<run>/EXEC_LOG.md`——每步 `pending`/`in_progress`/`done`/`blocked` + 产物路径 + 任何"待用户执行"命令。
- **已经有记录的运行是接着跑，不是重新规划。**`exec_runs` 非空、有对应分支或已有 run 目录，都表示运行在进行中：在 Step 0 读 `references/resume_rules_zh.md`，按日志恢复，并最终抵达执行分支的合并授权点。三者都没有才是新运行。

### Step 8：简报

以结果开头，说明验证证据、保留的任务工作区和 run 产物位置、等待启动授权或结果的命令、已同步修正及剩余风险。点出本 run 在任何重命令前启动的独立审查。确认的 blocker/major 与获授权修复经 `star-plan-executor <叶子>` 回来核验。执行分支审查干净后进入 `references/branch_rules_zh.md` 的合并授权点：已有具体授权沿用，否则通过 AskUserQuestion 询问。点出未合并分支和 worktree；重型结果就位后由 `star-expt-analyst <叶子>` 对照 §5 分析。控制在约 500 字以内。

### Step 9：审查并返回执行目标

当前执行器仍负责用户的执行目标。重命令启动或合并前，通过 `Skill` 工具对本 leaf 运行 `star-code-reviewer`；已有审查覆盖当前代码版本和范围、且待启动时满足现有启动守卫，才直接复用。把既有执行目标和授权传入，并要求 reviewer 将证据与控制权交回这里。单独的只复核请求没有这条接续。

1. 检查返回的干净报告、问题项或获授权修复。重开受影响 action 并验证改后代码；依赖新实质决定前先解决它。独立复核仍必需；宿主无法提供时，本地做一次并记录限制。
2. 审查有效且没有未解决 blocker/major 时，恢复待执行的已授权动作：通过守卫后启动并收集结果，或在 leaf 完成后合并。缺启动或合并权限时交回具体待办。启动归父级 `star-auto` 所有时，把控制交回该启动器。
3. 不因控制返回或日志更新就再开审查。代码版本和覆盖仍有效时复用当前报告；启动守卫要求更新日期时，交回 reviewer 核对未变来源并刷新报告，绝不绕过。避免 reviewer 与 executor 围绕未改工作无限循环。

## 状态与文件规则

- `EXEC_LOG.md` 是执行事实来源；再次调用从最后一个 `exec_runs` 条目的首个未完成 action 恢复。
- 已记录运行按 `references/resume_rules_zh.md` 恢复，不重新规划；执行分支最终抵达合并授权点。
- `tasks/<plan-name>/` 的工具脚本与 scratch 默认都保留。生成产物和持久证据放 `wkdrs/<run>/`；只有用户具体要求、且相关内容已提升后才删除，也不碰其他计划的目录。
- 代码改动进 `${CODE_NAME}/`;数据进 `datas/`;权重进 `inits/`;运行脚本进 `execs/scpts/`、以 `execs/run.sh` 为入口(CLAUDE.md §8)。
- 只有具体普通授权或合法 `star-auto` 且审查、成本守卫通过时才启动重型任务；不可逆操作仍需单独具体授权。
- 所有运行命令走 `.env` 的 `CONDA_HOME` / `PYTHON_HOME`;绝不用系统 python、绝不硬编码本地路径(CLAUDE.md §9)。
- 子计划 frontmatter 的 `exec_status`、`exec_runs`、`updated` 可维护；§2–§5 只能通过授权一次即沿用的 `references/plan_sync_rules_zh.md` 原地回写并追加 `## Revision History`。§1、§6 与父计划不动。
- Git 按已记录默认值逐 action 提交，只暂存 action 文件及对应运行记录。分支/worktree 创建是例行可逆隔离；合并、弃用、移除与删除沿用具体授权或按 `references/branch_rules_zh.md` 询问。绝不 rebase、抹掉用户改动或证据、强制移除 worktree。
- 步骤 `status` 允许的取值:`pending` / `in_progress` / `done` / `blocked` / `skipped`。

## 对话纪律

- 非交互运行中继续普通已授权实现与轻量验证。仍有必需决定且 AskUserQuestion 不可用时，用纯文本呈现具体问题，只停依赖它的 action，并继续无关的已授权工作；沉默或时间经过都不是批准。
- **问题所指的内容写在同一条消息的正文里、排在这次调用之前**——待同步修正整批、交付批准的 EXEC_PLAN。选项只装答案，不装内容本身；发出前回看一眼：选项上面空无一物，说明内容是被跳过了、不是被压缩了。
- 对话跟随用户语言，计划正文保持 frontmatter `language`；中文计划中的技术术语保留英文。
- involve（规约 §7.7）只控制未决裁量，不撤销已有授权。提交、分支、worktree：`low` 取推荐，`medium` 合并问，`high` 分开问；已有适用选择不重问。研究范围、§5 验收、关键输入、成本/启动权限、覆盖、弃用、移除、删除或所有权歧义必须解决。`auto=unattended` 只增加写明的战术计划、经审查启动、干净 squash、不删除修复和空 worktree 授权；不授权研究/验收变化、冲突消解、证据丢失、scratch 删除或其他破坏性操作。生效档位、来源和决定各记一次。
