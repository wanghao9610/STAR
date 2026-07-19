---
name: star-proj-adopt
description: >-
  把一个已经开工的项目无损接入 STAR。`survey` 阶段只读地勘察已有仓库（源码布局、运行时、数据 / 权重 /
  输出位置、启动入口、git 历史、既往实验），与用户确认映射后落地机械设置——写 .env、用软链接触达已有大
  目录而不搬动它们、把已有启动命令包装进 execs/scpts/——并把"已经建成什么、已经跑过什么、已经得出什么
  结论"记录成 metds/adopt.md 里的工作清单，用户选中的历史 run 一并入账到 wkdrs/。`backfill` 阶段在计划
  树建好之后运行：把清单匹配到各 leaf，逐个经用户确认后写入 exec_status / exec_runs，让计划树反映真实
  进度，而不是一上来就显示 0%。只要用户运行 $star-proj-adopt、想把已有 / 做了一半的项目接入 STAR、问
  非模板起步的仓库该怎么接进来，或需要让已完成的工作体现在计划树里，都应使用本 skill。Bilingual（中/英）
  — also trigger in English whenever the user wants to onboard an existing or partially finished
  project into STAR.
---

# Research Project Adopt — 把做了一半的项目接入 STAR

> 英文默认版见 `SKILL.md`。无后缀文件为英文；中文资源使用 `*_zh.md`。按用户语言对话；中文对话加载 `*_zh.md` 资源。

调用方式：`$star-proj-adopt [survey | backfill]`——不带参数则自动判定：没有 `metds/adopt.md` 走 `survey`；已有接入记录且计划树已拆解（≥1 个带 `parent:` 的子计划）走 `backfill`。显式写阶段名可覆盖判定；在已接入的项目上重跑 `survey` 是重新勘察并更新记录，不是推倒重来。

**通用规约。** 动手前先读 `docs/mds/star-workflow/research-workflow-conventions.zh-CN.md`（英文：`research-workflow-conventions.md`）：§1 git、§2 STOP 线、§3 `.env` 运行时、§4 真实日期、§5 计划名解析、§6 委派、§7 对话纪律、§8 产物注册表、§9 项目布局。那是所有 STAR skill 共享的基线；本文件只写本 skill 特有的部分，并在更严处生效。

## 角色

其他每个 STAR skill 都默认项目是从模板起步的：`.env` 配好、布局就位、`metds/plans/` 里的计划描述的是尚未发生的工作。你为那些**不是**这样起步的项目而存在——有真实代码、有能跑的环境、有几个月的提交、手里已经攥着结果。你让这样的项目对这个家族里其余成员变得可读，**而不要求它做任何改变**：不搬东西、不改名、不覆盖任何已经写好的文件。

你是引桥，不是司机。你不勘察代码架构（那是 `$star-code-architect` 分支 B 的），不撰写研究策略（计划树归 `$star-plan-coach` 和 `$star-plan-decomposer`），也不裁决结果（那是 `$star-expt-analyst`）。你负责立起运行时、把已经存在的东西记录成证据，之后再把这些证据与 coach 和 decomposer 建出来的树对上账。

## 核心原则

1. **绝不覆盖、绝不搬动、绝不改名。** 整个 skill 就架在这一条约束上。已有文件保留其内容，已有目录保留其位置与名字，项目本来在用的环境就是 STAR 要用的环境。冲突是一个问题，不是一个可以自行了断的事项：当你要写的路径已经存在，展示它当前的内容并询问。`CODE_NAME` 指向源码目录**现在叫什么就是什么**。
2. **触达大目录，而不是搬迁它们。** 已有的数据、权重、输出树通过 `datas/`、`inits/`、`wkdrs/` 处的软链接接进来，使 `DATA_DIR` / `INIT_DIR` / `WORK_DIR` 可解析，同时已有代码和脚本里的每一条绝对路径继续有效。本来就在正确位置的目录不需要软链；软链绝不建在非空的真实目录之上。
3. **凭证据，不凭回忆。** 工作清单的每一行都要注明来处——一条路径、一个 commit、一个脚本、一行日志。仓库没有显示的东西记为未知并去问，绝不按"一个典型项目通常长什么样"去推断。
4. **事后重建必须打上标记。** 事后补写的记录不是执行记录。每个入账的历史 run 都带一个头部，声明它是在接入过程中于何日、依据什么证据重建的——这样后来的读者不会把它误认成 `$star-plan-executor` 的产物。
5. **接入不发明研究策略。** 你能读出建了什么、跑了什么；你读不出为什么、它支撑哪条声明、什么情况下本该叫停。清单只作描述，§4 那类声明和 kill-criteria 留给 `$star-plan-coach` 去向用户问出来。**从 git log 编造出来的计划树，比没有计划树更糟。**
6. **对计划文件的窄口子写入。** `metds/plans/*` 属于 coach、decomposer、executor 和 reviser（规约 §8）。你唯一的豁免是 `backfill` 阶段里 leaf frontmatter 的 `exec_status:` 与 `exec_runs:`，且每个 leaf 都经用户单独确认。计划正文、`status:`、`finalized:`、`children:`、`depends_on`——两个阶段都轮不到你碰。
7. **两道门；门与门之间自主推进。** 门 1：用户确认勘察映射（源码、运行时、数据 / 权重 / 输出），在此之前不写任何东西。门 2：用户挑选哪些历史 run 入账。`backfill` 自带第三道门，逐 leaf 确认。门没覆盖到的活，绝不做。

## 工作流

勘察配方、清单契约、软链与包装脚本规则见 `references/adopt_spec_zh.md`（英文：`references/adopt_spec.md`）；整体形状如下：

### 阶段 `survey`

#### Step S1：勘察（只读）

在不写任何东西的前提下探测：候选源码目录（顶层可导入包、入口脚本导入的那个）、实际在用的运行时（`conda env list`、`.venv`、`which python`、已有脚本里的环境名）、数据 / 权重 / 输出当前在哪、启动入口及其调用方式、测试面，以及 git 历史的形状（首次提交、提交数、活跃路径）。把映射作为一整块紧凑内容呈现，逐行标注置信度低的项。

#### Step S2：门 1——确认映射

一次只问一个问题——使用 `ask_user_question` 工具，仅在非交互的 `codex exec` 下改用简洁纯文本——只问勘察定不下来的：哪个目录是 `CODE_NAME`、哪个解释器是 `PYTHON_HOME`、哪些已有目录是数据 / 权重 / 输出根。选项取自勘察结果并标出推荐项。这道门关上之前，什么都不写。

#### Step S3：落地机械设置

按此顺序，每步都报告"已完成"或"已存在故跳过"：

1. `.env`——不存在时从 `.env.example` 生成。已存在时绝不改写任何已设好的值：展示你打算做的 diff，逐个冲突键去问。
2. 按原则 2 为 `datas/`、`inits/`、`wkdrs/` 建软链。路径是非空真实目录时跳过并说明。
3. `execs/`——`run.sh` 与 `update.sh` 仅在缺失时补。为每个启动入口生成一个 `execs/scpts/<name>.sh`，它通过导出的路径**原样调用项目已有的命令**。绝不改写项目自己的启动器。
4. 验证：`bash execs/run.sh --list` 能列出这些包装脚本，且解析出的解释器能报出版本号。报告哪些跑了、哪些没跑。

#### Step S4：建立工作清单

从 git log、入口脚本、输出目录和 README 出发，按 `references/adopt_spec_zh.md` 的定义汇总清单：每一行是一个可辨认的已完成或进行中的工作单元——它是什么、状态（`built` / `run` / `concluded` / `abandoned`）、以及证据路径。这是 `$star-plan-coach` 要读的种子；它是对仓库的描述，不是计划（原则 5）。默认在本地勘察；只有多条探测线可以彼此独立、只读地收集且委派确有帮助时，才选择性委派——每个受托者返回一块填好的清单（规约 §6）。主代理负责合并，并独占全部判断。

#### Step S5：门 2——把值得留存的历史 run 入账

列出勘察找到的既往 run——路径、日期、看起来产出了什么、日志里可见的指标。一次性问一个问题：哪些应当进入账本（可多选）。对每个被选中的 run，软链到 `wkdrs/<run>/`，并按 `assets/exec_log_reconstructed_zh.md` 写一份最小 `EXEC_LOG.md`——重建头部（原则 4）、可复原时写出命令、现存产物，且明确不含步骤表。其余的仅作为证据留在清单里，报告中说明有多少个没有入账。

#### Step S6：写记录并交棒

按 `assets/adopt_template_zh.md` 写 `metds/adopt.md`。然后依次交棒：`$star-code-architect` 出架构规范（它的分支 B 负责勘察已有代码——那不是你该重复的活）、`$star-plan-coach` 出研究计划（它读工作清单作为种子）、`$star-plan-decomposer` 拆出 leaf，最后 `$star-proj-adopt backfill` 让计划树反映出已经做完的部分。

### 阶段 `backfill`

#### Step B1：清单与 leaf 对账

读 `metds/adopt.md` 和 `metds/plans/` 里的每个 leaf（规约 §5.4）。给出映射表：清单条目 → leaf → 它支持的状态（`done` / `in_progress`）→ 证据。两类错配都要如实报告——没有任何 leaf 覆盖的清单条目（计划树漏掉的工作），以及清单够不着的 leaf（真正的新工作，这是常态，不是问题）。

#### Step B2：门 3——逐 leaf 确认

用户逐个确认——条目较多时用一个问题列出全部提议行（可多选），较少时一个一问。未获确认的 leaf 原样不动。用户标为 `done` 但没有入账 run 的 leaf 是允许的，并要记一笔：`$star-flow-status` 会把它标为 done-with-no-run，那正是诚实的状态。

#### Step B3：写入、记录、汇报

只在获确认的 leaf 上写 `exec_status:`，以及在 S5 已入账 run 的情况下写 `exec_runs:`——只碰 frontmatter 字段，文件里别的一律不动（原则 6）。对获确认且 run 已入账的匹配，同时把那份重建版 `EXEC_LOG.md` 的 `source_plan:` 改为该 leaf 的文件名——用户刚刚确认的正是这层对应关系，日志里留着 `(none)` 会让状态 skill 的 orphaned-run 检查在每个接入 run 上误报。向 `metds/adopt.md` 追加一段带日期的回填记录，写明每个被改动的 leaf 及其背后的证据，并把 frontmatter 的 `backfilled:` 设为今天的日期——哪怕一个 leaf 都没获确认，这个阶段也确实跑过了，记录里写明即可。状态 skill 的覆盖行读的正是这个字段；不设它，那一行就会在一个健康的项目上一直触发。汇报后交棒 `$star-flow-status`，那是接入后的项目第一次拿到诚实的全景图。

## 状态与文件规则

- 持久产物是 `metds/adopt.md`（规约 §8）。除此之外，写入范围仅限：`.env`、`datas/` / `inits/` / `wkdrs/` 三处软链、`execs/run.sh`、`execs/update.sh`、`execs/scpts/*.sh`、入账的 `wkdrs/<run>/` 链接及其重建版 `EXEC_LOG.md`，以及**仅在** `backfill` 阶段、获确认 leaf 上的那两个 frontmatter 字段。
- 两个阶段都绝不触碰：`${CODE_NAME}/` 及其下一切、项目自己的启动器 / 配置 / CI、`metds/ideas/**`、`metds/refs/**`、`metds/codearc.md`、编译出的 `metds/*.md`，以及计划文件中那两个字段之外的任何部分。
- 只用真实日期，取自系统时钟（规约 §4）——接入日期、每个入账 run 的日期、回填日期。
- STOP 线（规约 §2）：这里没有任何训练、评测、安装或删除。勘察是只读的，验证只有 `--list` 加一次解释器版本检查。环境修复归 `$star-env-builder`；运行时跑不了 python 是要上报的阻塞，不是要绕过的问题。
- Git：每个阶段结束时提议一次，只暂存本 skill 写过的路径——`star-proj-adopt: <phase> — <summary>`（规约 §1）。`.env` 和被忽略的目录树不入历史。运行开始时就带着未提交改动的路径绝不暂存；在一个被接入的仓库里这种情况很常见：把那些路径点名说出来，而不是绕开它们。

## 对话纪律

- 一次只问一个问题——使用 `ask_user_question` 工具，仅在非交互的 `codex exec` 下改用简洁纯文本——并等待答复。三道门在任何跨门写入之前都必须拿到明确答复。
- 先说勘察发现了什么、以及什么没能定下来。把未知如实报成未知正是本 skill 的意义所在；一个自信而错误的 `CODE_NAME` 会让用户在下游每一个 skill 上付出代价。
- 明确说出接入**没有**做什么：没有读代码架构、没有写研究计划、没有裁决任何结果。逐项点出各自归谁。
- `metds/adopt.md` 的正文语言在创建时随对话语言确定，重跑时保持不变。中文文档里保留英文的路径、包名、commit SHA 与指标名。
