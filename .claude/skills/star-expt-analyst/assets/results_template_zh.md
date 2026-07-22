---
type: results
language: zh
generated: <YYYY-MM-DD>
scope: <这些数字来自哪个子树，或 "whole forest">
model_id: <模型 id，写入时由运行时自报；运行时未提供则写 "unrecorded">
model_trail:                    # 只追加：每次写入会话一条，绝不改写既有条目
  - { date: <YYYY-MM-DD>, model: <模型 id 或 "unrecorded">, skill: <star-…>, scope: <本次会话写了什么> }
sources:
  - run: <prefix>_<slug>
    report: EXPT_ANALYSIS_<YYYY-MM-DD>.md
    verdict: <met|partially met|not met|inconclusive|invalid>
---

# 结果

<!-- 由 /star-expt-analyst aggregate 写入。下面每个数字入表前都在其来源处被重开确认过
     （references/aggregate_spec_zh.md），并携带它的出处。这些数字是在什么协议下测出来的见
     metds/evaluation.md——本文件只放分数。请把它当作生成物：要改一个数字，去修或重跑那个 run
     再重新编译，绝不在这里手改。 -->

## 1. 概览

<!-- 三四句话：这个实验计划测了什么、多少个 run 进了表、多少个被排除及原因、根 §4 还要求什么但没人测过。
     只说表显示了什么——不做超出它的解读。 -->

## 2. 主结果

<!-- 根 §4 的 claim→实验映射里，每条 claim / benchmark 一张表。表题用根 §4 自己的话说明这条 claim
     测试什么——不是在这里下的结论。 -->

### <claim / benchmark>

<!-- 表题：根 §4 说这测试什么。 -->

| Run | 变体 / 设置 | <指标> | Split | 判定 | 来源 |
|---|---|---|---|---|---|
| `<prefix>_<slug>` | <…> | <值> | test | met / not met | `<path:line 或键名>` @ EXPT_ANALYSIS_<日期> |

## 3. 消融

<!-- 根 §4 消融设计里每个消融一张表，行是它的各变体。设计说明什么在变——绝不写某个变体为什么赢
     （aggregate_spec_zh.md：绝不归因差值）。 -->

### <消融名称>

<!-- 表题：根 §4 说这个消融隔离的是什么。 -->

| Run | 变体 | <指标> | Split | 判定 | 来源 |
|---|---|---|---|---|---|
| `<prefix>_<slug>` | <…> | <值> | val | met | `<path:line 或键名>` @ EXPT_ANALYSIS_<日期> |

## 4. 其他 run

<!-- 根 §4 既没映射到 claim、也没映射到消融的 run。连同其头条数字列出来，绝不丢掉。
     全部都映射上了则写"无"。 -->

## 5. 已排除

<!-- 被挡在上面各表之外的 run：报告判定为 `invalid` 或 `inconclusive`，或数字复核未通过
     （报告说 X，来源现在说 Y）。一行一个并写明原因——读者必须能看见、并数得出被拿掉了什么。
     没有排除任何 run 则写"无"。 -->

| Run | 判定 | 排除原因 | 下一步 |
|---|---|---|---|
| `<prefix>_<slug>` | invalid | <…> | `/star-expt-analyst <slug>` |

## 6. 尚未测量

<!-- 根 §4 要求、但还没有 run 产出的东西：claim/benchmark、应该产出它的计划，以及它的状态
     （从未执行 / STOP 线命令仍在等用户）。这就是结果节目前还缺的清单。设计已被完整覆盖则写"无"。 -->

- <claim / benchmark> —— `<prefix>_<slug>_plan.md`；<状态> → `/star-plan-executor <slug>`
