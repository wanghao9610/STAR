# Digest Rubric — 两层证据、变化推导，以及 digest 永远不做的事

digest 是一份**进展记录**，不是结果表。`wkdrs/results/results.md` 是经核实的台账；`metds/evaluation.md` 是评测协议；这里是两个日期之间发生了什么的叙事。本文件规定什么可以进来、以什么信任等级进来，以及界线在哪。

## 两层证据

范围内的每个 run 恰好落入一层，且两层绝不共用一张表。

### 第一层 —— 报告支撑

该 run 有 `EXPT_ANALYSIS_<date>.md`。取**最新**的一份。只从它、且只从它读取：

- run 判定（`met` / `partially met` / `not met` / `inconclusive` / `invalid`）；
- §5 done-criteria 记分卡，压缩成一行；
- 头条指标，逐条按报告记录的 `{值, 来源, split}` 原样转录；
- 它点名的任何 blocker 或 major 观察，以及任何战略信号或 kill-criterion 命中。

**不要为了补充报告而打开该 run 的原始日志。** 报告就是接口。绕到它背后去"核对"、或补上它遗漏的某个指标，属于逐 run 分析——那是 `$star-expt-analyst` 的活，且带着本 skill 不做的核实环节。看起来不对的报告要路由出去（`$star-expt-analyst <run dir>` 刷新它），而不是在这里改正。

数字是**连同出处一起抄录，而非重新核实**（`SKILL.md` 核心原则 3）。digest 记录报告所引的来源，让读者能自己去查；它自己不查。这就是 digest 与 `aggregate` 全部的成本差别，也正是 digest 能按周跑的原因。

### 第二层 —— 临时

该 run 有目录但没有分析报告。它出现在 digest 里，是为了让一周的工作**可见**，不是为了让它被打分。

**只读 `EXEC_LOG.md`。** 从中读取：日志 `status`、步 done / 总数、任何 `blocked` 步、任何未勾选的"待用户执行"STOP 命令、任何记录的战略信号。如果日志本身点名了一个头条数字**并且**给出了它来自哪个文件，就连 `path:line` 一起引用；否则该格写 `not measured`。

这一层的硬边界：

- **绝不去找数字**。如果 EXEC_LOG 没有把数字递到你手上，答案就是 `not measured`。grep run 的指标文件、解析 results JSON、读 TB event 文件，都属于分析，在这里越界。
- **绝不出图**，绝不跑解析脚本，绝不计算派生量（跨种子均值、delta、百分比）。
- **绝不给临时 run 评分**，不对照任何 §5 done-criterion。它没有判定；frontmatter 记 `verdict: —`，表格里写 `awaiting analysis`。
- **每个临时值都要标注** `provisional (unverified)`，并带上它的 `path:line`。

临时层的每一行都要带上它的路由：`$star-expt-analyst <run dir>`。

### 两层之间的那堵墙

一个临时数字**永远不可以**：

1. 出现在报告支撑表里，或出现在任何混排两层的表里；
2. 被用来计算或声称"变化"段里的任何 delta；
3. 在 digest 的头条里、或在对话回复里，被当作结果或结论引用；
4. 进入 `wkdrs/results/results.md` 或任何按范围的 `wkdrs/results/results_<slug>.md`——digest 不写台账，而台账自身的信任模型要求从源头重新核实，临时数字按定义没有通过；
5. 被带有判断意味的词描述——`提升`、`超过`、`达标`、`证实`、`有效`。中性的动词是"报告"：*日志在 `train.log:812` 报告 0.41（临时）*。

这堵墙正是临时层可以安全存在的原因。撤掉它，digest 就变成第二个未经核实的分析器，产出与台账互相矛盾的数字。

## 变化推导

由本次 run 集合与上一份 digest 的 `sources:` 列表求差得到。**只取报告支撑行**——临时 run 没有可以变化的判定。

| 变化 | 触发条件 |
|---|---|
| 新增 run | 该 run 不在上一份 `sources:` 中 |
| 判定变化 | 同一 run 在两份中都出现，但 `verdict` 不同 |
| 新近分析 | 该 run 在那边是 `tier: provisional`，在这边是 `report-backed` |
| 报告刷新 | 同一 run、同一层，但 `report:` 文件名更新 |

平实地写出方向（`not met → met`），点名该 run 与两个报告日期，到此为止。**为什么**变化不归你说（核心原则 5）。一个从 `met → not met` 的判定是值得放在最前面讲的发现，也值得路由给 `$star-plan-reviser`——但 digest 报告的是这个变化，不是它的成因。

没有上一份 digest → 整段省略，并由 §1 说明序列从此开始。与上一份 digest 求差为空则写"无变化"，这本身也是信息：一个有 run 却没有任何判定变化的周期，说明活干了、判定没动。

## digest 永远不做的事

- **绝不把 delta 归因到某个原因。** 逐字继承自 `aggregate_spec.md`。赢了的变体就是赢了；说出理由需要这一家 skill 都不做的受控对比。
- **绝不评判 criterion。** 判定要么引自分析报告，要么就是没有。digest 对某条 done-criterion 有没有达成不持观点。
- **绝不复述协议或方法。** benchmark 怎么跑属于 `metds/evaluation.md`；方法是什么属于 `metds/overview.md`。digest 引用一下就走。
- **绝不成为可引用的来源。** 每份 digest 都在自己的抬头里写明：其中的数字抄自报告，经核实的台账是 `wkdrs/results/results.md`。从 digest 里把数字抄进论文，是这个文件正面就在警告的误用。
- **绝不靠跑点什么来填缺口。** 未执行的叶子、未分析的 run、待用户执行的 STOP 命令：每一条都是带着关闭命令的缺口，交回给用户（规约 §2）。
- **绝不把空周期报成成绩。** 窗内没有 run 就写"本周期没有 run"，附上最新 run 日期与水位线，别的不写。用树的状态去填满一份空 digest，那是 `$star-flow-status` 的输出，不是这里的。

## 写头条

三到五句，也是本文件里最难写对的部分。它只用报告支撑的证据回答*本周期我们学到了什么*：

- 先讲发现，别讲活动。"3-way ablation 在 `01_core-method` 上证伪了共享头假设"胜过"本周完成了三个 run"。
- 如果负面结果是本周期最大的事实，就让它打头。kill-criterion 命中永远打头（`analysis_rubric.md` 的立场，在此沿用）：那是计划在起作用。
- 用一个从句点明还有什么没测。一个为五条 claim 里的两条产出了数字的周期，应该说清还有哪三条悬着。
- 如果范围内每个 run 都是临时层，头条就恰如其分地说出这件事——*完成 N 个 run，均未分析*——对它们的数字只字不提。那是这个周期最诚实的头条，并且直接路由到 `$star-expt-analyst`。
