---
run: <prefix>_<slug>
source_plan: <prefix>_<slug>_plan.md
task_dir: tasks/<prefix>_<slug>
updated: <YYYY-MM-DD>
status: in_progress   # in_progress / blocked / done
involvement: <档位 (来源)>   # 生效参与度档位，规约 §7.7——如 low (invocation)；从未设置时为 medium
model_id: <模型 id，照抄运行时本会话为你声明的那串——Kimi 会话有报告就照记；仅当本会话未声明任何模型才写 "unrecorded">
model_trail:                    # 只追加：每次写入会话一条，绝不改写既有条目
  - { date: <YYYY-MM-DD>, model: <模型 id 或 "unrecorded">, skill: <star-…>, scope: <本次会话写了什么> }
---

# 执行日志 — <prefix>_<slug>

本轮进度的真源。执行过程的中间工作文件放在 `tasks/<plan-name>/`;本日志等持久记录及生成的 run 产物放在
`wkdrs/<run>/`。全新 session 应能仅凭本文件续跑:跳过 `done` 步,从第一个未完成步继续。

## 步骤状态

<!-- 每个 EXEC_PLAN 动作一行。`检查结果` 由**主循环**重跑绑定 check 填写,不是 agent 自报。
     合法 status:pending / in_progress / done / blocked / skipped。 -->

| # | 步骤 | status | model | 产物(wkdrs/<run>/…) | 检查结果 | 备注 |
|---|------|--------|-------|----------------------|----------|------|
| 1 | <…> | pending | | | | |
| 2 | <…> | pending | | | | |

## 待用户执行（STOP 线）

<!-- 用户必须自己跑的命令(重实验)。某步越过 STOP 线时,把它移到这里而非直接执行。每条:确切的 conda 命令、
     它产出什么、以及用户该带回什么输出以便验证完成判据。 -->

- [ ] `<conda 命令>` → 产出 `wkdrs/<run>/…`;带回 <指标/输出> 以验证完成判据。

## 待同步修正（尚未写回子计划）

<!-- 执行过程中新出现的实质性偏差,delta 形式与 EXEC_PLAN 的"与子计划的偏差"一致
     (references/plan_sync_rules_zh.md)。绝不为它们中断执行;收尾时向用户一次性批量确认,
     确认的行写回子计划 §2–§5 及其 `## Revision History`,然后在此勾掉。 -->

- [ ] <ADDED/MODIFIED/REMOVED> §3.<n>:"<原文>" → "<新做法>" —— 原因:<…>
- [ ] ENRICHED §3.<n>:<计划留白处> → <执行敲定的值> —— 被引用:<文档 §>

## 备注 / 决策

<!-- 续跑的 session 需要知道的一切:做过的假设、遇到的 blocker 及其解决方式(子计划层面的实质性
     偏差记到上面"待同步修正",不记这里)。
     若某结果撞上根计划 §5 的 kill-criterion,在此记为 **战略信号**,并注明推荐的反馈路径
     (/skill:star-plan-coach 或 /skill:star-plan-decomposer)——执行器本身绝不改父计划。 -->
