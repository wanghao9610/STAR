# 状态规则 —— 如何读整条流程、如何挑下一步

这里的一切都靠读文件得到。绝不写任何东西。

计划树带顺序语义，所以走一遍图。覆盖检查刻意做得很薄——只看存在性与新鲜度。优先顺序在两者之上挑出唯一的建议；未识别文件行是注册表的兜底检查。

## 每个文件读什么

每个 `metds/plans/<prefix>_<slug>_plan.md` 的 frontmatter 可能带：

- 总体计划（来自 coach）：六节的 `status:` 映射、可选的 `finalized:`、`updated:`，以及（拆解后）`children:` + 正文的 `## Sub-plans` 索引。
- 子计划（来自 decomposer）：`parent:`、`prefix:`、`level:`、`traces_to:`、`depends_on:`、六个执行章节的 `status:` 映射、`updated:`。
- 已执行的叶子（来自 executor）：`exec_status:`（`pending`/`in_progress`/`done`/`blocked`/`skipped`/`abandoned`）——`done`、`skipped`、`abandoned` 都是**终态**：处于其中任一状态的叶子不再欠任何东西，也不会卡住下游的确认点。`abandoned` 记录的是被自身 kill-criterion 判死的方向；理由写进计划的 `## Revision History`，让这个负结果留存下来；`exec_runs:`——一个只追加的 `wkdrs/<run>/` 目录列表，最新的在最后，**最后一项就是当前 run**；更早的条目是重跑（换个 seed、修掉一个 bug），留作记录。此字段出现之前写的计划带的是单个 `exec_run:`；把它当作只有一项的列表来读——executor 下次写入时会迁移它。

对带 `exec_runs` 的叶子，另读当前 run 的 `wkdrs/<run>/EXEC_LOG.md`：步骤状态表（数 `done` / 总数、注意任何 `blocked`）、"待用户执行（红线）"清单、以及 Notes 里的任何"方向性信号"。加了 `--slim` 时，超过六行的表已经数好了——`[tally] 8 data rows | c3: done×7, blocked×1` 一行里就是这个计数和这个提醒，而写成 `N distinct` 的列装的是步骤名或日期，不会是状态。无论表怎么处理，未勾选的待办项与方向性信号都原样打印，所以红线规则和 Step 3 需要的东西不会被藏在计数后面。日志 frontmatter 的 `branch:` / `merged:` 随同一次读取一并带回（规约 §11）。

扫描调用还会列出 `exec/*` 分支（规约 §11）。某个分支匹配到一个叶子、而这个叶子的 run 目录在当前 checkout 里不存在，就是一次正在该分支上进行的 run：基础分支始终是准据（§11.3），所以这边叶子的 frontmatter 读作未完成是对的——渲染这个叶子时点出分支名，而不是只当它 pending；分支侧状态只在下面某一行需要时才读，用只读的 `git show exec/<run>:wkdrs/<run>/EXEC_LOG.md`（§1 的只读清单涵盖 `show`）。

覆盖检查所需的其它注册产物，只按"存在与否"和各自那一个日期字段来读——绝不读它们的正文。注册表见规约 §8；下面覆盖表逐行写明用的是哪个字段。

## 节点分类

- **根** —— 无 `parent:`（一份 coach 计划）。前缀 1 位。
- **内部** —— 有非空 `children:` 列表（被进一步拆解）。
- **叶子** —— `children:` 为空或不存在。只有叶子可执行。

按 `parent:`（权威）重建父子链，而非按前缀。父之下，子按 `depends_on` 拓扑排序；缺失或有歧义则回退到前缀升序。

## 状态符号图例（每节点一个）

- `✔` 完成 —— 总体计划节点设了 `finalized:`；叶子 `exec_status: done`。
- `◐` 进行中 —— 部分章节 `done`/`in_progress`，或六节全 `done` 但未设 `finalized:`（评分表还没跑），或叶子 `exec_status: in_progress`（有日志则显示 `k/n` 步）。
- `○` 待办 —— 尚未开始（`exec_status` 缺失/`pending`，或全部章节 `pending`）。
- `⊘` 受阻 —— 叶子 `exec_status: blocked`，或其 `depends_on` 未满足的叶子。
- `⏸` 待用户 —— EXEC_LOG 里有未勾选"待用户执行"STOP 命令的叶子。
- `⚠` 需关注 —— **太粗、无法直接执行**，有两种情形：其自身 §3 任务分解 / §5 完成判据大量 `[TBD]` 或 `【待定】` 的子计划叶子（两个记号都算——中文计划写的是后者，扫描一并计数），**或**带着 `finalized:` 却没有 `children:` 的总体计划——从未被拆解过，因而算作叶子（规约 §5.4），执行器会拒绝它。这是唯一的定义；第 3 层的资格判定一律依它，与生命周期规则最终渲染出哪个状态符号无关 → 建议 `/skill:star-plan-decomposer`。

**每节点只有一个状态符号，生命周期状态优先。** 同时符合生命周期状态符号和 `⚠` 的节点，取生命周期的那个：finalized 之后又被改过的根仍是 `✔`，done 但没有 run 的叶子仍是 `✔`。失配属于失配段——读者本来就是去那里找它的——绝不让一个失配标记盖掉节点真实所处的状态，否则这棵树就不再表示它字面的意思了。`⏸` 和终态 `exec_status` 可能同时落在一个叶子上——某次运行留下了未勾选的红线命令，之后这个叶子被关掉了。终态优先，理由和生命周期状态符号压过 `⚠` 是同一个：叶子渲染成 `✔`，那条仍在案上的命令交给失配段。`⏸` 用于 `exec_status` 尚未进入终态的叶子。

每个叶子行显示其 `depends_on`、（正在执行时）`k/n` 步，以及——当前 run 记录了执行分支时——它的合并状态：`exec/<run> unmerged`，日志写明之后则是 `merged`。示例：

```
0_open-vocab-det-seg            ◐  总体方向 6/6 done, 已拆解 (4 个子计划)
├ 00_baseline-impl              ✔  exec done                        依赖: —
├ 01_mvp-verify                 ✔  exec done                        依赖: 00
├ 02_core-method                ◐  exec 进行中 2/5 步               依赖: 01
│ ├ 020_desc-generation         ✔  exec done                        依赖: —
│ ├ 021_set-matching            ◐  exec 进行中 2/4                  依赖: 020
│ └ 022_det-seg-heads           ○  exec pending                     依赖: 020, 021
└ 03_final-rets                 ⏸  待用户 (1 条 STOP 命令)          依赖: 02
```

上例中的根是 `◐` 而非 `✔`，因为它的 `finalized:` 未设——六节全 `done` 本身并不能关闭一个总体计划节点，评分表还得跑。总体计划节点的状态符号只报告**它自己**的状态，绝不报告其子树：一个已 finalized 的根即使下面的子树只执行了一半，仍然是 `✔`；子树没做完这件事由进度汇总来说。

## 进度汇总（三个数）

1. **总体方向完整度** —— 各总体计划（来自 coach 的根/内部节点）里：`done` 的章节数 /（6 × 总体计划数）。注明哪些未 `finalized:`。
2. **拆解覆盖度** —— 内部节点（已拆解）vs 被标 `⚠` 的粗糙叶子（定义见上文）。
3. **执行进度** —— 叶子 `exec_status: done` / 总叶子数；以及所有有 run 的叶子的 EXEC_LOG 步 `done` / 总数之和。

## 覆盖检查（已完成的工作还差什么）

每一行**必须全部条件同时成立**才触发。其余一律沉默——特别是：还在跑的 run 什么都不欠，未 `done` 的叶子对下游什么都不欠。触发的行报一句话：欠的是什么、欠在哪个节点或哪个 run、以及补上它的命令。收敛规则：给了 `PLAN_NAME` 时，只检查属于该子树的产物（以及从其叶子 `exec_runs` 可达的 run）。

| # | 信号 | 触发条件（须全部成立） | 转交给 |
|---|---|---|---|
| 1 | 想法未立项 | 某 `metds/ideas/<slug>_idea.md` 带 `finalized:` **且** 没有同 slug 的根计划 **且** 没有任何根计划的 §1 正文提到该想法文件 | `/skill:star-plan-coach <slug>` |
| 2 | 文献缺失 | 至少存在一份根计划 **且** `metds/refs/refs_index.md` 不存在 | `/skill:star-refs-reviewer` |
| 3 | 缺代码审查 | 某叶子 `exec_status: done` **且** 其当前 run 目录存在 **且** 该目录下没有 `CODE_REVIEW_<date>.md` | `/skill:star-code-reviewer <叶子>` |
| 4 | 代码审查过期 | 该 run 最新的 `CODE_REVIEW_<date>.md` 存在 **且** 其日期早于该 run `EXEC_LOG.md` 里最后一条带日期的记录 | `/skill:star-code-reviewer <叶子>` |
| 5 | 缺实验分析 | 某叶子 `exec_status: done` **且** 其当前 run 目录存在 **且** 该目录下没有 `EXPT_ANALYSIS_<date>.md` | `/skill:star-expt-analyst <叶子>` |
| 6 | 结果汇总表过期 | ≥2 个叶子有 `EXPT_ANALYSIS_<date>.md` **且**没有覆盖该范围的现行结果汇总表——即 `wkdrs/results/results.md` 与（限定到 `PLAN_NAME` 时的）`wkdrs/results/results_<slug>.md` 都不存在、或其 `generated:` 都早于这些报告里最新的日期 | `/skill:star-expt-analyst aggregate` |
| 7 | 方法文档过期 | 某个编译出的 `metds/*.md`（带 `type:` + `generated:` + `sources:`）在 `sources:` 里记录的某计划 `updated`，早于该计划当前的 `updated` | `/skill:star-metd-summarize` |
| 8 | 方法文档缺失 | 每个叶子都处于终态（`done` / `skipped` / `abandoned`）**且** 每个总体计划都带 `finalized:` **且** 没有任何 `metds/*.md` 带 `type:` + `generated:` | `/skill:star-metd-summarize` |
| 9 | 接入未回填 | `metds/adopt.md` 存在 **且** 其 `backfilled:` 缺失或为 `—` **且** 至少存在 1 个带 `parent:` 的子计划 | `/skill:star-proj-adopt backfill` |
| 10 | Digest 过期 | `wkdrs/digests/` 里至少有 1 份 `EXPT_DIGEST_<date>.md` **且** 范围内至少有 1 个 run 的 `EXPT_ANALYSIS_<date>.md` 日期晚于最新那份**序列** digest 的 `covers.through` | `/skill:star-expt-digest` |
| 11 | 缺代码库规范 | 存在 ≥1 个可执行叶子 **且** `metds/codearc.md` 不存在 | `/skill:star-code-architect` |
| 12 | 缺运行环境 | 存在 ≥1 个可执行叶子 **且** 不存在任何 `wkdrs/env_*/ENV_REPORT.md` | `/skill:star-env-builder` |
| 13 | 缺发布准备 | 每个叶子都处于终态（`done` / `skipped` / `abandoned`）**且** 已有带 `type:` + `generated:` 的 `metds/*.md` **且** `wkdrs/release/` 下没有 `RELEASE_<date>.md` | `/skill:star-code-release` |
| 14 | 待合并 | 某叶子当前 run 记录了 `branch:` 而 `merged:` 仍是 `pending` **且** 该叶子在那个分支上 `exec_status: done` **且** 该 run 最新的 `CODE_REVIEW_<date>.md` 存在、没有其日志里悬而未决的 blocker/major 问题项 | `/skill:star-plan-executor <叶子>`（抵达合并确认点——规约 §11） |

有五行特别容易做错：

- **第 4 行需要日志里有日期，没有就沉默。** EXEC_LOG 的步骤表并不强制带日期列。日志里没有可比对的带日期条目时，第 4 行无法判定——那就什么都不报，绝不退回去拿文件 mtime 猜。真正要紧的那种情况（压根没有审查）已经由第 3 行覆盖。
- **第 7 行是精确对账，不是拿 mtime 猜。** `/skill:star-metd-summarize` 会逐个源计划记下"读取时该计划带的 `updated` 值"。拿那个记录值和计划当前的 `updated` 比——绝不用文件 mtime，它会因为无关的事情变动（一次 checkout、一次格式化）。
- **第 8 行要等整棵树。** summarizer 编译的是已确定的方法——只要还有叶子未执行、或总体计划未定稿，它自身的就绪门槛就不会放行——所以覆盖检查只在每个叶子都 `done`、每个总体计划都带 `finalized:` 之后才推荐它，无论更早已经完成了多少叶子。
- **第 10 行只对已经在记 digest 的项目触发。** 与第 2、7、8 行不同，产物缺失并不触发它：digest 是工作辅助，不是研究欠下的交付物，一个从没跑过 `/skill:star-expt-digest` 的项目并不因此欠账。所以这一行问的是“已有的序列有没有落在分析报告后面”。“最新那份序列 digest”指 `mode` 为 `incremental`、`window` 或 `all` 的最新一份——`plan` 模式的 digest 是回溯性阅读，它的 `covers.through` 不能当作续接点，这与该 skill 自己的 `scope_spec_zh.md` 对上次覆盖到的日期的定义一致。
- **第 14 行去记录所在的地方读。** 在分支 checkout 上，记录就在工作区里；从基础 checkout 看，`exec/*` 清单是触发器，只读的 `git show` 是读取手段。它的审查条件指的是分支侧的 `CODE_REVIEW_<date>.md`；一份都没有时，改由第 3 行在分支侧状态上触发，而且它在这一档里本来就排在前面。
- **第 1 行是这里最弱的信号。** `/skill:star-plan-coach` 把种子记在计划 §1 的正文里（"Seeded from `metds/ideas/<slug>_idea.md`"），不是 frontmatter 字段，所以检测靠 slug 匹配加上对想法文件名的正文 grep。一份由想法长出来、之后又被改名的计划，会被读成"未立项"。当只有第 1 行触发时，说明这条检查是启发式的。

## 下一步动作（唯一的建议）

自上而下按优先顺序走，取**第一个**能给出候选的层。其余欠账留在覆盖检查里，此处不重复。

1. **待用户** —— 某个 `⏸` 叶子有未勾选的 STOP 命令。写明该命令；只有用户能清掉它，在那之前下面几层都不重要。只有一件事排在这条命令之前：该 run 目录里还没有 `CODE_REVIEW_<date>.md` 时，先推荐 `/skill:star-code-reviewer <叶子>`，把待跑命令紧挨着写在它下面——bug 在算力烧掉之前最便宜，而第 3 行覆盖不到这里，因为该叶子还不是 `done`。这两条归属不同：审查属于那八个 agent 可以自己启动的 skill，是接下来真正要跑的那条（见下）；待跑命令则打印出来，归用户。
2. **已完成工作的欠账** —— 落在已完成之事上的覆盖检查触发项，按"欠账滚得多快"取：回填（第 9 行）→ 审查（第 3、4 行）→ 合并（第 14 行）→ 分析（第 5 行）→ 生成结果汇总表（第 6 行）→ 凝练方法（第 7、8 行）→ 文献（第 2 行）→ digest（第 10 行）。第 9 行排在最前，因为它是那种会把其余欠账一起藏起来的欠账：在被接入项目里已完成的叶子拿到 `exec_status: done` 之前，第 3、5 行根本无法在它们身上触发，而第 3 层还会兴高采烈地建议你去执行一个成果早已躺在磁盘上的叶子。合并（第 14 行）紧随审查之后：未合并的分支卡住每一个依赖它的叶子（规约 §11.3），也让自己的记录在基础 checkout 上看不见——这两笔代价都随着围绕它执行的每一个叶子越滚越大。除第 1 行外的每一条覆盖行都能在这一层被取到；第 1 行归第 4 层，因为"开一个新题目"不是欠账。digest 排在最末，也是这份清单上唯一一条推迟不付出代价的欠账：每份 digest 都由留在磁盘上的分析报告重新编译，而且无论隔多久，序列都不会出现缺口——所以迟写的 digest 不丢任何信息，而这份清单上其余每一行都会越拖越贵。文献虽然在流程里靠前，却排在倒数第二：缺综述的代价是写作时的定位，而未审代码的代价是压在它上面的每一个叶子——所以"去读文献"绝不该盖过"你刚跑完的那个 run 从没审过代码"。欠账优先于进度，因为它会滚：每多执行一个建立在未审代码之上的叶子、每多引用一次过期结果汇总表里的数字，将来要返工的面就更宽。而下一个叶子不会过期。
3. **下一个可执行叶子** —— **执行顺序里最靠前**、且同时满足以下全部的叶子：`exec_status` 不是终态（`done` / `skipped` / `abandoned`）也不是 `blocked`；其 `depends_on` 里每个前缀都能解析到一个 `exec_status` 为 `done` 的兄弟；它不是 `⚠` 粗糙叶子（若是，改为建议先拆解它）；且没有现存的 `exec/*` 分支与它匹配——这样的叶子是在那个分支上进行中的一次 run（归第 14 行或普通的续跑管），不能当新叶子开跑，理由那一句要写明这一点。"执行顺序" = 由 `depends_on` 得到的拓扑序，以前缀升序破平局，深度优先遍历（使某个已拆解节点自己的叶子排在它后面的兄弟之前）。输出 `→ 下一个: /skill:star-plan-executor <前缀或 slug>`。
4. **已定稿但未立项的想法** —— 即覆盖检查第 1 行。只有当树全部完成且不欠任何东西时才会走到这一层；而那时正是开下一个题目的时候。

给一句话理由和命令。 点名的每一条命令各判各的，第 1 档那一对也不例外：落在那八个 agent 可以自己启动的 skill 上、且目标已经定死的那条，就是接下来要跑的东西，而不只是打印出来的东西——拾起发生在本次运行结束之后，本 skill 自己不启动任何东西（规约 §10）；而紧挨着它的那条 STOP 命令照旧打印出来，等用户。若各层都给不出候选，说清是以下哪一种：不欠任何东西且每个叶子都已了结——整项研究已经完成，转交给 `/skill:star-code-release`，或用 `/skill:star-idea-storm` 开下一个题目；某个未满足的依赖（写明）；需拆解的粗糙叶子；或 `metds/plans/` 为空（转交给 `/skill:star-plan-coach`；连想法也没有则 `/skill:star-idea-storm`）。

## Drift / 一致性标记（只报告，绝不修复）

- **可能过期的子计划** —— 某子计划 `updated` 早于其父计划 `updated`（父计划在拆解后被改）。建议 `/skill:star-plan-decomposer <父计划>` 对账。
- **悬挂链接** —— 某 `children:` 项找不到对应文件，或某计划文件的 `parent:` 指向不存在的文件、或未被其父计划 `## Sub-plans` 索引列出。
- **坏依赖** —— 某 `depends_on` 前缀解析不到现存兄弟，或依赖图里有环。
- **孤儿 run** —— 某个 `exec_runs` 条目指向不存在的 `wkdrs/<run>/` 目录，或某 EXEC_LOG 的 `source_plan` 与叶子不符。
- **done 但没有 run** —— 某叶子 `exec_status: done` 却没有 `exec_runs`（或其 run 目录已不在）。覆盖检查第 3、5 行都要求 run 目录存在，所以这样的叶子对下游悄悄什么都不欠；改在这里标出来——一个被手工标成 done 的叶子，要么是记账疏漏，要么是 run 被删了。
- **终态但红线命令未清** —— 某叶子处于终态 `exec_status`，其当前 run 却还带着未勾选的「待用户执行」命令。要么是命令跑过了没勾，要么是叶子带着它被关掉了。图例把这个叶子渲染成 `✔`，所以这一行是读者唯一能知道那条命令还挂在案上的地方，优先顺序里的待用户那一档也就不再挑它。
- **finalized 之后又被改过** —— 某总体计划节点的 `updated` 晚于其 `finalized:`。评分表跑过了，之后计划又变了，那个 `✔` 已经不再有评分表背书。建议 `/skill:star-plan-coach <slug>` 重新关闭它。
- **分支遗留** —— 某 `exec/*` 分支匹配不到任何叶子；某个日志已带 `merged:` 的 run，其分支却还在（删除被拒或被推迟——只标记）；或某叶子当前 run 记录着 `branch:`，这个分支却已不存在（分支从 run 底下被删——executor 把这当作 blocker）。

本段保持简短；无任何标记时整段省略。

## 未识别文件行（注册表的兜底检查）

上面的覆盖检查是按文件名匹配产物的。如果某个产出方 skill 改了它写出来的东西，覆盖检查会悄悄不再触发那一行——这是一次没人会察觉的漏报。这一行把那种失败翻转成看得见的。只数**报告形**文件，让 run 产物（权重、图、原始日志）绝不进来：

- 直接位于某个 `wkdrs/<run>/` 目录下的 `*.md`，且文件名不是 `EXEC_PLAN.md`、`EXEC_LOG.md`、`CODE_REVIEW_<date>.md`、`EXPT_ANALYSIS_<date>.md`、`REVIEW_<date>.md`；
- 直接位于 `wkdrs/` 下四个已登记非 run 目录里的 `*.md`，且用了 §8 未在该处登记的名字：`wkdrs/reviews/`（无 run 时的共用兜底目录）登记的名字是 `code_<scope>_<date>.md` 与 `<prefix>_<slug>_<date>.md`（数字前缀）；`wkdrs/env_<name>_<date>/` 目录登记的名字是 `ENV_REPORT.md`；`wkdrs/digests/` 登记的名字是 `EXPT_DIGEST_<date>.md` 与 `MODEL_LEDGER.md`；`wkdrs/results/` 登记的名字是 `results.md` 与 `results_<slug>.md`。其余任何 `wkdrs/` 子目录一律按上一条当作 run 目录审计；
- `metds/` 顶层的 `*.md`，其主名不属于 `overview`、`framework`、`dataset`、`training`、`evaluation`、`codearc`、`adopt`，**且**带有 `type:`、`generated:`、`sources:` 三者之一。这三个字段合起来是"编译文档"的指纹：按三者取并、而不是只认 `type:`，意味着某个产出方既改了输出名又丢掉了 `type:` 时仍然会被抓到；而 `metds/` 下手写的笔记三者皆无，保持沉默。

不要递归进入子目录（`analysis/`、`raw/`、`refs/`）——那是各产出方自己的工作空间，本就不在注册表内。报一行：`⚠ N 个未识别的报告文件` + 至多三个路径。N 为 0 时整行省略。这是命名不一致，不是对文件本身的判断：它意味着规约 §8 的注册表和磁盘上的实际情况已经分叉，两者之一需要更新。
