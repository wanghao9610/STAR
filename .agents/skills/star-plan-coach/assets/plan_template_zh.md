---
title: <研究主题> 研究计划
slug: <slug>
language: zh
created: <YYYY-MM-DD>
updated: <YYYY-MM-DD>
model_id: <模型 id，写入时由运行时自报；运行时未提供则写 "unrecorded">
model_trail:                    # 只追加：每次写入会话一条，新的加在末尾，绝不改写既有条目
  - { date: <YYYY-MM-DD>, model: <模型 id 或 "unrecorded">, skill: <star-…>, scope: <本次会话写了什么> }
status:
  problem: in_progress
  related_work: pending
  method: pending
  experiments: pending
  risks: pending
  milestones: pending
---

# <研究主题> 研究计划

## 1. 问题定义与动机

<!-- 一句话研究问题；动机（为什么现在值得做）；缺口；预期影响 -->

## 2. 相关工作与定位

<!-- 最接近的 3-5 项工作及各自不足；本工作的定位（它们都做不到 X） -->

## 3. 核心方法

<!-- 关键洞见；技术路线；novelty 类型与主张；为什么该有效 -->

## 4. 实验与验证设计

<!-- 主张 → 实验对应表；数据集；baseline；指标与有意义的提升幅度；消融设计；算力预算 -->

## 5. 风险与备选方案

<!-- 主要风险；kill criteria（什么结果会否定该方向）；Plan B。
     已否定的路线：每条被否掉的方向一行——试了什么、哪个结果否定了它、下次不要再走哪一段。
     被丢弃的节点自己的修订历史此后不再有人翻，这里是它唯一还会被读到的去处；
     写 limitations 一节、回答审稿人"你们试过 X 吗"时，翻的就是这几行。 -->

## 6. 里程碑与产出

<!-- 最小验证实验；时间线（从目标 deadline 倒推）；目标 venue；资源需求 -->
