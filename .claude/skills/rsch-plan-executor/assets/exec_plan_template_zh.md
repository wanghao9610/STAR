---
title: <子主题> 可执行计划
run: <prefix>_<slug>                 # = wkdrs/<run>/ 目录名
source_plan: <prefix>_<slug>_plan.md # 本次执行的 metds/plans/ 下叶子子计划
code_name: <CODE_NAME>               # 从 .env 解析
created: <YYYY-MM-DD>
approved: <YYYY-MM-DD>               # 用户经 ExitPlanMode 批准的日期
done_criterion: "<本轮必须满足的子计划 §5 检查,含阈值>"
---

# <子主题> 可执行计划

## 现状勘察（现状 vs 要求）

<!-- Step 2 的差距清单。对计划涉及的每个区域,写清 ${CODE_NAME}/ 现在有什么 vs 必须新建/修改什么。
     ${CODE_NAME}/ 为空则写 "greenfield"。指向真实路径,不要猜。 -->

## 动作清单

<!-- 有序。每个动作绑一个 check。`执行方` = `agent`(在此执行) 或 `stop → 用户`(agent 备好命令、用户来跑
     ——见 STOP 线)。命令走 .env 的 conda 环境;产物落 wkdrs/<run>/ 下。 -->

| # | 动作 | 文件 / 模块(${CODE_NAME}/…) | 命令(走 conda) | 产物(wkdrs/<run>/…) | 检查 | 执行方 |
|---|------|------------------------------|-----------------|----------------------|------|--------|
| 1 | <新建/修改 …> | <路径> | — | — | <import / smoke test> | agent |
| 2 | <…> | <路径> | <命令> | <路径> | <证明它完成的检查> | agent |
| N | <重实验> | — | <备好的命令> | <路径> | §5 完成判据 | stop → 用户 |

## STOP 线

<!-- 哪些动作越过 STOP 线、为什么(长时/多卡训练、全量评测、大开销 API)。每条给出:走 conda 环境的确切命令
     (存在运行入口时经 execs/run.sh)、它产出什么和存哪、用户该带回什么输出以便验证完成判据。可把可复用的启动
     脚本写到 execs/scpts/<run>.sh(写它没问题;跑它仍归用户)。 -->

## 完成判据

<!-- 复述结束本轮的子计划 §5 检查,含阈值,相关时挂回父计划 §4 指标 / §5 kill-criteria。这是 Step 6 要验证的。 -->
