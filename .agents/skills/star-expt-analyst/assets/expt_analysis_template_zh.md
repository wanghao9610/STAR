---
run: <prefix>_<slug>
source_plan: <prefix>_<slug>_plan.md
analyzed: <YYYY-MM-DD>
verdict: <met | partially met | not met | inconclusive | invalid>
model_id: <模型 id，写入时由运行时自报；运行时未提供则写 "unrecorded"——见 docs/mds/star-workflow/model_id_spec.zh-CN.md>
model_trail:                    # 只追加：每次写入会话一条，新的加在末尾，绝不改写既有条目
  - { date: <YYYY-MM-DD>, model: <模型 id 或 "unrecorded">, skill: <star-…>, scope: <本次会话写了什么> }
---

# 实验分析 — <run>（<YYYY-MM-DD>）

<!-- 由 star-expt-analyst 写入。对这个 run 的产出做只读审计，对照计划的预期打分。这里的每个数字
     在写下之前都按来源重开核实过。没什么可说的章节压成一行——绝不注水。 -->

## 1. 范围与证据基础

<!-- run 目录及其解析方式（计划名 → exec_runs 最后一项，或路径 → 其计划）。载入的预期：子计划 §4/§5、根计划
     §4 指标与 §5 kill-criteria、EXEC_PLAN/EXEC_LOG——以及哪些缺失。读了多少文件（给数量，不要罗列）。
     检测到的兄弟 run。哪些分析没做全："无 matplotlib——纯文字"、"tensorboard 缺失——TB 指标未读"、
     "环境不可用——仅阅读"。 -->

## 2. 判定

<!-- 2–4 行。run 判定（met / partially met / not met / inconclusive / invalid）及其理由，然后按编号
     列出所有 blocker/major 观察。诚实，不打太极：`inconclusive` 与 `invalid` 都是答案。不虚高，
     也不危言耸听。 -->

## 3. 完成判据记分卡

<!-- 核心结论。一条评判依据一行：先子计划 §5，再根计划 §4 指标，再计划写明的任何 baseline。
     `threshold: none stated` → 报出数值，判定留空。数值按来源打印的原样——四舍五入到翻转判定
     是错误，不是"整理"。
     `种子数 / n` 是这个数值跑了几次或重复了几次，`离散度` 是它们散在哪；
     写 `—` 表示只跑了一次，这和不知道是两回事。 -->

| 判据（原文） | 来源 | 指标 | 数值 | 种子数 / n | 离散度 | Split | 阈值 | 判定 | 出处 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| <"…"> | §5 / 根计划 §4 / baseline | <名字> | <值> | <n 或 1> | <std、min–max，或 —（单次）> | train/val/test | <阈值或 none stated> | met / not met / unmeasurable | <path:line 或键名> |

## 4. 产物与完成度

<!-- A：§4 交付物 vs 磁盘，附完整性检查结果。B：EXEC_LOG 的 `done` 说法用产物核实的结果，以及每条
     "Awaiting user" 红线命令是已跑还是仍待跑。`done` 而没有产物是 blocker。结尾给这个 run 在磁盘
     上的体积，以及日志里带的任何未同步 "Pending amendments" 或 方向性信号。 -->

| 交付物（§4） | 在磁盘上 | 完整性 | 备注 |
| --- | --- | --- | --- |
| <路径> | present / missing / unexpected | <非空、可解析、大小合理> | <…> |

## 5. 日志健康

<!-- C：致命 / 数值 / 动态信号，每条给 `path:line` 与引用的证据。常规警告噪音不报。日志干净就
     用一行说清——干净的 run 本身就是一个值得写出来的结论。 -->

## 6. 指标与对比

<!-- §3 背后的数字，标明每个来自哪一档来源（结果 JSON > 评测汇总 > TB event > 日志行），以及任何
     关于报告方式的注意事项。 -->

### 图

<!-- 仅当 matplotlib 已安装时才渲染：给 wkdrs/<run>/analysis/*.png 的相对链接，每张图一行说明曲线
     显示了什么。每张图旁边就是生成它的脚本，可以重新生成。否则写："无图——.env 环境未安装
     matplotlib"。 -->

### 跨 run 对比

<!-- 仅当存在同计划的兄弟 run（同 <prefix>_<slug> 共同前缀）时才有。只放关键指标——§5 写明的那些。说明
     数字朝哪个方向动；**不要**把差异归因：说清某个变体为何更好需要一次受控对比，而本 skill 不跑那个。
     本 run 是独苗时整节删掉。 -->

| Run | <指标> | <指标> | 备注 |
| --- | --- | --- | --- |
| <本 run> | <值> | <值> | <…> |
| <兄弟 run> | <值> | <值> | <…> |

## 7. 解读

<!-- E：结果支持 / 推翻 `traces_to` 里的主张，还是暂不下结论？是否命中根计划 §5 的 kill-criterion（重点写——
     方向性信号是计划在起作用）。跑了哪些泄漏与结果好得反常的排查、结果如何。然后把局限当局限写：seed 数、
     split 规模、方差，以及这个 run 没有显示什么。 -->

## 8. 建议与转交

<!-- 一个未决项一个归属；本 skill 除这份报告外什么都不写。步骤未完成或红线命令仍待跑 →
     star-plan-executor <slug>；§5 已达标、待 finalize → star-plan-executor <slug>（exec_status 归它）；
     计划文本已不属实 → star-plan-reviser <slug>；命中 kill-criterion 或主张被推翻 →
     star-plan-reviser / star-plan-coach / star-plan-decomposer；日志指向的代码缺陷 →
     star-code-reviewer <slug>；环境损坏 → star-env-builder。需要新 run 才能拿到的指标：给出确切的、
     可直接粘贴的命令，绝不在这里执行。 -->
