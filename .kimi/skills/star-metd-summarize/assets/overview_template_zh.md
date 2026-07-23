---
type: overview
language: zh
generated: <YYYY-MM-DD>
model_id: <模型 id，照抄运行时本会话为你声明的那串——Kimi 会话有报告就照记；仅当本会话未声明任何模型才写 "unrecorded">
model_trail:                    # 只追加：每次写入会话一条，绝不改写既有条目
  - { date: <YYYY-MM-DD>, model: <模型 id 或 "unrecorded">, skill: <star-…>, scope: <本次会话写了什么> }
sources:
  - plan: <prefix>_<slug>_plan.md
    updated: <YYYY-MM-DD>
---

<!-- 由 star-metd-summarize 从 metds/plans/ 编译而成。手工编辑会在下次运行时被覆盖——要改这份
     文档，请改它的来源计划。 -->

# <方法 / 项目名称> —— 总览

## 1. 问题与动机

<!-- 根 §1：一句话讲清研究问题，为什么是现在，以及没人填的那个 gap。写给一个从没看过、也不会
     去看这些计划的读者。 -->

## 2. 现有工作的不足

<!-- 根 §2：最接近的几条工作线，以及各自留下的具体短板，最后落到本方法的定位（"它们都做不到 X"）。
     点作品名，不写 citation key——文献库在 metds/refs/。 -->

## 3. 核心思想

<!-- 根 §3：用一段话讲清关键洞察，要能让读者复述出来；再用几句话讲技术路线。这是论文 introduction
     的地基——实现细节留在 framework.md。 -->

## 4. 方法总览

<!-- 方法由什么构成。一行一个组件，来自各叶子的 §1 目标，按样本流经的顺序排。这张表是通往其余
     四份文档的地图。 -->

| 组件 | 在方法中的作用 | 详见 |
|---|---|---|
| <名称> | <一行> | [framework](framework.md) §<n> |

## 5. 贡献与 Claims

<!-- 根 §3 novelty claims + §4 claim→实验映射。每条贡献写成可证伪的 claim，并给出承载其证据设计的
     文档。没有实验去测的 claim 是一个值得点名的缺口。 -->

| # | Claim | 由谁验证 |
|---|---|---|
| C1 | <…> | [evaluation](evaluation.md) §<n> |

## 6. 状态与里程碑

<!-- 根 §6 里程碑 + 各叶子的 exec_status：什么做完了、什么在进行、下一步是什么。只写几行——计划树的
     实时进度视图归 status skill，不归一份编译文档。 -->
