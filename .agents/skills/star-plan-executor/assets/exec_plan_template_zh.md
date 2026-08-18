---
title: <子主题> 可执行计划
run: <prefix>_<slug>                 # = wkdrs/<run>/ 目录名
source_plan: <prefix>_<slug>_plan.md # 本次执行的 metds/plans/ 下叶子子计划
task_dir: tasks/<prefix>_<slug>      # 该计划执行过程的中间文件目录
code_name: <CODE_NAME>               # 从 .env 解析
created: <YYYY-MM-DD>
started: <YYYY-MM-DD>                # Codex 开始本次已授权执行的日期
branch: <run 名 | none>          # 本次执行所在的执行分支，名字与上面的 run: 完全相同（规约 §11）；none = 在基础分支上执行
base: <分支名@短SHA | —>             # 分支从哪里分出——也是合并目标；branch 为 none 时写 —
worktree: <绝对路径 | none>          # 安置本次 run 的工作树（规约 §11.7–9）；none = 在被调用的 checkout 里执行
done_criterion: "<本轮必须满足的子计划 §5 检查,含阈值>"
model_id: <模型 id，写入时由运行时自报；运行时未提供则写 "unrecorded">
model_trail:                    # 只追加：每次写入会话一条，新的加在末尾，绝不改写既有条目
  - { date: <YYYY-MM-DD>, model: <模型 id 或 "unrecorded">, skill: <star-…>, scope: <本次会话写了什么> }
---

# <子主题> 可执行计划

## 现状勘察（现状 vs 要求）

<!-- Step 2 的缺口清单。对计划涉及的每个区域,写清 ${CODE_NAME}/ 现在有什么 vs 必须新建/修改什么。
     ${CODE_NAME}/ 为空则写 "空代码库（从零起步）"。指向真实路径,不要猜。 -->

## 与子计划的偏差

<!-- 本 EXEC_PLAN 相对子计划 §2–§5 的实质性变更项(references/plan_sync_rules_zh.md):步骤增/删/替换/重排、
     §2 依赖与现实不符、§4 产出路径变化、§5 判据调整,以及 ENRICHED 行——子计划未写明、而某份方法文档
     会引用的值,其"原因"栏写明该章节。其余"更具体"不算偏差。执行前先向用户确认这些行,
     确认后同步回子计划;写回后标记 `synced`。忠实执行则写"无"。 -->

| # | 类型 | 子计划原文(§) | 确认后的改法 | 原因 | synced |
|---|------|----------------|--------------|------|--------|
| D1 | <ADDED/MODIFIED/REMOVED> | §3.<n> <…> | <…> | <…> | ☐ |
| D2 | ENRICHED | §3.<n> 未写明 | <执行敲定的值> | 被引用:training.md §3 | ☐ |

## 动作清单

<!-- 有序。每个动作绑一个 check。`执行方` = `codex`、`子代理` 或 `stop → 用户`(Codex 备好命令、用户来跑
     ——见红线)。命令走 .env 的 conda 环境;产物落 wkdrs/<run>/ 下。 -->

| # | 动作 | 文件 / 模块(${CODE_NAME}/…) | 命令(走 conda) | 产物(wkdrs/<run>/…) | 检查 | 执行方 |
|---|------|------------------------------|-----------------|----------------------|------|--------|
| 1 | <新建/修改 …> | <路径> | — | — | <import / runnable check> | codex |
| 2 | <…> | <路径> | <命令> | <路径> | <证明它完成的检查> | codex/子代理 |
| N | <重实验> | — | <备好的命令> | <路径> | §5 完成判据 | stop → 用户 |

## 红线

<!-- 哪些动作越过红线、为什么(长时/多卡训练、全量评测、大开销 API)。每条给出:走 conda 环境的确切命令
     (存在运行入口时经 execs/run.sh)、它产出什么和存哪、用户该带回什么输出以便验证完成判据。可把可复用的启动
     脚本写到 execs/scpts/<run>.sh(写它没问题;跑它仍归用户)。 -->

## 完成判据

<!-- 复述本轮收尾的子计划 §5 检查,含阈值,相关时对应回根计划 §4 指标 / §5 kill-criteria。这是 Step 6 要验证的。 -->
