---
title: <子主题> 执行计划
slug: <slug>
language: zh
prefix: "<prefix>"           # 例如 "00" —— 父前缀 + 本单元的 0 起始序号
parent: <parent-filename>    # 例如 0_open-vocab-det-seg_plan.md（权威链接）
level: <n>                   # = 前缀长度（根 = 1）
traces_to: "<本子计划执行根计划的哪一节/哪条 claim，例如 §6 里程碑 1（MVP）；§4 claim 1>"
depends_on: []               # 必须先完成的兄弟前缀，例如 ["00", "01"]；[] = 无依赖，可独立开工
created: <YYYY-MM-DD>
updated: <YYYY-MM-DD>
model_id: <模型 id，照抄运行时本会话为你声明的那串——Claude Code 在会话开始注入；仅当本会话未声明任何模型才写 "unrecorded">
model_trail:                    # 只追加：每次写入会话一条，绝不改写既有条目
  - { date: <YYYY-MM-DD>, model: <模型 id 或 "unrecorded">, skill: <star-…>, scope: <本次会话写了什么> }
status:
  objective: in_progress
  deps: pending
  steps: pending
  deliverables: pending
  verification: pending
  risks: pending
---

# <子主题> 执行计划

## 1. 目标与范围

<!-- 用一两句话说明本子计划交付什么，并对应它所服务的根计划 claim/章节。明确写出 non-goals:
     哪些内容有意留给兄弟子计划或更深一层。本子计划应恰好负责父计划执行中的一个内聚块。 -->

## 2. 输入与依赖

<!-- 具体前置条件,每项指向一个项目位置:
     - 数据: 哪些数据集/划分, 放在 datas/
     - 权重: 哪些预训练/基础模型, 放在 inits/
     - 代码: 哪些模块/入口, 放在 code/
     - 必须先完成的上游子计划(按前缀标注),以及它交付什么产物。
       把这些前缀同时写进 frontmatter 的 `depends_on` 列表(机器可读的执行顺序)。 -->

## 3. 任务分解

<!-- 有序、动词明确、研究者能逐条执行并勾掉的步骤。不要用"探索/结合/研究一下"这类无法验证
     完成与否的动词。每一步应足够小,使其完成与否毫不含糊。给步骤编号。 -->

## 4. 产出物与输出

<!-- 本子计划产生的具体产物,以及它们确切存放在哪里:
     生成输出放 wkdrs/<run-name>/…, run 名要能区分本任务/实验; 数据放 datas/; 权重放 inits/;
     本计划自己要写的脚本放 tasks/<plan-name>/ (绝不放 execs/, 它的根目录是封闭的)。
     写出文件/目录名,而不是笼统的"结果"。 -->

## 5. 验证 / 完成判据

<!-- 证明本子计划完成的那一条检查: 一个通过的测试、一个越过阈值的指标、一个存在且正确的具体输出。
     相关时把阈值挂回根计划 §4 指标 / §5 kill-criteria。无法检查的,就不算完成判据。 -->

## 6. 局部风险与备选

<!-- 执行本子任务特有的风险(不是研究层面的风险——那些在根计划 §5)。什么会让这一步失败或卡住、
     需要盯的早期信号,以及局部备选方案。若与根计划 kill-criteria 有关联,标注出来。 -->
