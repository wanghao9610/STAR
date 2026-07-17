# 审查报告 — <prefix>_<slug>（<YYYY-MM-DD>）

<!-- 由 $star-plan-reviser 生成。目标：metds/plans/<file>；节点类型：leaf | internal | root；
     exec_runs：<run 目录列表，最新的在最后，或 none>。每条结论都要引证据（路径[:行号]、命令输出、或 frontmatter 字段）。
     无话可说的节收敛成一行——绝不注水。 -->

## 1. 目标回顾

<!-- 1–2 行目标。叶子：逐字引用其 §5 done-criterion。
     根/内部：finalized 状态与计划所依赖的关键主张/假设。 -->

## 2. 实际发生了什么

<!-- 依据 run 日志与磁盘，而非记忆：步骤 done / blocked / skipped；磁盘上核实过的产物；
     仍在"待用户执行"的命令。根/内部：children 汇总（每个子计划：exec_status、步骤 done/总数、
     值得注意的信号）。 -->

## 3. 完成度记分卡

<!-- 每个 §3 任务一行，末尾加 §5 done-criterion 一行。
     结论：met / partial / unmet / unverifiable（见 review_spec）。每行都要引证据。 -->

| 项目 | 结论 | 证据 |
| --- | --- | --- |
| §3.1 <任务> | <结论> | <路径[:行号] / 输出片段> |
| §5 done-criterion | <结论> | <证据> |

总计：<n>/<m> 项任务 met；done-criterion：<结论>。

## 4. 偏差清单

<!-- 计划说 X、run 做了 Y；计划之外的额外工作；被证据推翻的假设；
     kill-criteria 命中与日志中原文引用的 Strategy signal。 -->

## 5. 阻塞与遗留

<!-- blocked 的步骤及原因；残留的 [TBD] / 【待定】；执行提出但未回答的问题。 -->

## 6. 涟漪图

<!-- 反向 depends_on 边（把本节点列入依赖的兄弟）；由它派生的 children；
     下方哪些修订候选会让什么失效。 -->

## 7. 修订候选

<!-- 编号。爆炸半径：local（本文件）/ structural（树形结构 → $star-plan-decomposer）/
     strategic（方向 → $star-plan-coach）。每条候选由用户逐一裁决；
     被采纳的改动落在计划文件及其 Revision History 里，不落在这里。 -->

1. [<local|structural|strategic>] §<n> — <改什么>
   - 依据：<证据>
   - 修改草案：<一行概述>
