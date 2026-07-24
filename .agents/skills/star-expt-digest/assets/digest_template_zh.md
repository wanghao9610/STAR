---
type: digest
language: zh
generated: <YYYY-MM-DD>
mode: <incremental|window|plan|all>
scope: <whole forest | family of <prefix>_<slug>>
covers:
  from: <YYYY-MM-DD 或 "—">
  through: <YYYY-MM-DD>
previous: <EXPT_DIGEST_<YYYY-MM-DD>.md 或 "—">
model_id: <模型 id，写入时由运行时自报；运行时未提供则写 "unrecorded">
model_trail:                    # 只追加：每次写入会话一条，绝不改写既有条目
  - { date: <YYYY-MM-DD>, model: <模型 id 或 "unrecorded">, skill: <star-…>, scope: <本次会话写了什么> }
sources:
  - run: <prefix>_<slug>
    report: <EXPT_ANALYSIS_<YYYY-MM-DD>.md 或 "none">
    tier: <report-backed|provisional>
    verdict: <met|partially met|not met|inconclusive|invalid|—>
---

# 实验 Digest — <周期>

<!-- 由 $star-expt-digest 写入。这是一份**进展记录**，不是结果表。§3 的数字连同出处抄自 EXPT_ANALYSIS
     报告，并未在此重新核实；§4 的数字是临时的、未核实的。论文据以撰写的、经核实的台账是
     wkdrs/results/results.md（$star-expt-analyst aggregate）；这些数字所依据的评测协议是 metds/evaluation.md。
     绝不要把本文件里的数字抄进论文。 -->

## 1. 周期与范围

<!-- 两三行：窗口是怎么定的（自上一份 digest 续接 / 显式窗口 / 计划家族）、范围、窗内有多少 run、
     报告支撑与临时各占多少。plan 模式下点名为取 claim 语境而读过的祖先。若没有上一份 digest，说明
     序列从此开始。若周期为空，写明这一点并附最新 run 日期与水位线，下面每段都写"无"，然后收尾。 -->

## 2. 头条 —— 学到了什么

<!-- 三到五句，只用报告支撑的证据（references/digest_rubric_zh.md，"写头条"）。先讲发现，别讲活动。
     kill-criterion 命中永远打头。用一个从句点明根 §4 还要求什么、而至今无人测量。若每个 run 都是
     临时层，头条就恰如其分地说出这件事，对它们的数字只字不提。 -->

## 3. 本周期的 run —— 报告支撑

<!-- 每个有 EXPT_ANALYSIS 报告的 run 一行；判定与数字均引自该报告。"来源"是报告记录下来的东西，
     原样转录以便读者自查。若范围内没有任何 run 被分析过，写"无"。 -->

| Run | 计划 | 判定 | 头条指标 | Split | 来源 | 报告 |
|---|---|---|---|---|---|---|
| `<prefix>_<slug>` | `<prefix>_<slug>_plan.md` | met | <值> | test | `<path:line 或 key>` | EXPT_ANALYSIS_<date> |

## 4. 本周期的 run —— 临时（未核实）

<!-- 有目录但没有分析报告的 run。只读 EXEC_LOG；只有当日志本身点名了数字及其文件时，数字才出现在
     这里（references/digest_rubric_zh.md 第二层）。无判定、不评分、不出图。这些数字不得被引用、
     比较，或进入台账。若范围内每个 run 都已被分析，写"无"。 -->

| Run | 计划 | 日志状态 | 步数 | 日志报告的数字（临时） | 来源 | 下一步 |
|---|---|---|---|---|---|---|
| `<prefix>_<slug>` | `<prefix>_<slug>_plan.md` | in_progress | 3/5 | <值> —— provisional (unverified) | `<path:line>` | `$star-expt-analyst <run dir>` |

## 5. 发生了什么变化

<!-- 与上一份 digest 的 sources: 求差。只取报告支撑行。写出方向；绝不写成因
     （references/digest_rubric_zh.md）。没有上一份 digest 时整段省略；求差为空时写"无变化"。 -->

| Run | 变化 | From → To | 证据 |
|---|---|---|---|
| `<prefix>_<slug>` | 判定变化 | not met → met | EXPT_ANALYSIS_<old> → EXPT_ANALYSIS_<new> |
| `<prefix>_<slug>` | 新近分析 | provisional → met | EXPT_ANALYSIS_<date> |

## 6. 信号与发现

<!-- kill-criteria 命中、EXEC_LOG 里记录的战略信号、报告判为证伪或不成立的 claim，以及 blocker/major
     观察。每条一行，带上它的 run、它被记在哪里，以及路由。kill-criterion 命中是计划在起作用——
     把这一点说明白。什么都没触发则写"无"。 -->

- <信号> —— `<prefix>_<slug>`，<记录位置> → `$star-plan-reviser <slug>`

## 7. 期内计划树变化

<!-- `updated` 或 `finalized:` 落在窗内的计划：新建、修订、拆解、定稿。只读 frontmatter——绝不 diff
     正文。plan 模式下若无变化可省略。没有计划变动则写"无"。 -->

- `<prefix>_<slug>_plan.md` —— <新建|修订|拆解|定稿> <YYYY-MM-DD>

## 8. 缺口与欠账

<!-- 本周期还欠着什么：范围内没有分析报告的 run、没有 exec_runs 的叶子、EXEC_LOG 里有未勾选"待用户
     执行"STOP 命令的叶子，以及比范围内最新分析报告更旧的台账。每条一行，附上能关闭它的命令。
     周期干净则写"无"。 -->

- <欠着什么> —— `<prefix>_<slug>` → `<命令>`

## 9. 下一步

<!-- 接下来要做的一两件事，各附确切命令。只路由，不动手：未分析的 run 交 $star-expt-analyst，过期台账
     交 $star-expt-analyst aggregate，未执行或待用户的叶子交 $star-plan-executor，被证伪的 claim 交
     $star-plan-reviser，整棵树的当前状态交 $star-flow-status。 -->

- <动作> → `<命令>`
