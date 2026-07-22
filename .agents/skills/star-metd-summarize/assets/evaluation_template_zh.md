---
type: evaluation
language: zh
generated: <YYYY-MM-DD>
model_id: <模型 id，写入时由运行时自报；运行时未提供则写 "unrecorded">
model_trail:                    # 只追加：每次写入会话一条，绝不改写既有条目
  - { date: <YYYY-MM-DD>, model: <模型 id 或 "unrecorded">, skill: <star-…>, scope: <本次会话写了什么> }
sources:
  - plan: <prefix>_<slug>_plan.md
    updated: <YYYY-MM-DD>
---

<!-- 由 star-metd-summarize 从 metds/plans/ 编译而成。手工编辑会在下次运行时被覆盖——要改这份
     文档，请改它的来源计划。本文档定义协议；某个 run 实际测出了什么在
     wkdrs/<run>/EXPT_ANALYSIS_<date>.md 里。 -->

# 评测

## 1. 评测协议总览

<!-- 整个评测面收进一张表，来自根 §4：什么任务、在哪个 benchmark、用什么指标、对比哪些 baseline。
     不写分数——在这里出现的数字，是一个本文档拿不出证据的声明。 -->

| 任务 | Benchmark | Split | 指标 | Baselines |
|---|---|---|---|---|
| <…> | <…> | <test> | <…> | <…> |

## 2. 逐 Benchmark 详情

<!-- 只为"一行说不完"的 benchmark 各写一小节，来自根 §4 的指标与评测类叶子 §5 的阈值。有意义的提升
     幅度和指标本身一样重要：没有它，任何 delta 都能被说成提升。 -->

### 2.1 <Benchmark>

**Split 与协议。** <确切的 split；存在多个协议变体时说明用哪个>
**指标。** <计划点名的定义或实现——仅当它不是标准那个时才写>
**有意义的幅度。** <计划称之为真实提升的 delta，以及这个数字的出处>

## 3. Baselines

<!-- 每个 baseline、它的数字将从哪来、以及是什么让这个对比公平。引用来的数字必须点名出处；"我们自己
     复现的"和"从论文里引的"不是同一种声明，读者必须能分辨。 -->

| Baseline | 数字来自 | 可比性说明 |
|---|---|---|
| <名称> | <本项目复现 / 引自 `<工作>`> | <数据 / backbone / 预算是否一致？> |

## 4. 消融设计

<!-- claim→消融的设计，来自根 §4 消融设计与 §5 kill-criteria：每条 claim 对应隔离它的那个变体，以及
     什么结果支持它、什么结果推翻它。"什么推翻它"这一列是在任何 run 之前就写好的——正是这一点让它成为
     一个检验。 -->

| # | 受检 claim | 变体 | 什么结果支持 | 什么结果推翻 |
|---|---|---|---|---|
| A1 | <…> | <…> | <…> | <…>（kill-criterion） |

## 5. 评测执行

<!-- 逐 benchmark：计划记录的入口、config 与命令，加上输出落在 wkdrs/ 的哪里。链接某个 run 的分析报告，
     而不是把它的数字抄过来——结果及其解读归实验分析 skill，抄到这里的数字会悄无声息地过期。 -->
