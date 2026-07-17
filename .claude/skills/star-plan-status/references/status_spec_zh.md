# 状态规则 —— 如何读树、如何挑下一个

这里的一切都靠读文件得到。绝不写任何东西。

## 每个文件读什么

每个 `metds/plans/<prefix>_<slug>_plan.md` 的 frontmatter 可能带：

- 战略计划（来自 coach）：六节的 `status:` 映射、可选的 `finalized:`、`updated:`，以及（拆解后）`children:` + 正文的 `## Sub-plans` 索引。
- 子计划（来自 decomposer）：`parent:`、`prefix:`、`level:`、`traces_to:`、`depends_on:`、六个执行章节的 `status:` 映射、`updated:`。
- 已执行的叶子（来自 executor）：`exec_status:`（`pending`/`in_progress`/`done`/`blocked`）与 `exec_runs:`——一个只追加的 `wkdrs/<run>/` 目录列表，最新的在最后，**最后一项就是当前 run**；更早的条目是重跑（换个 seed、修掉一个 bug），留作记录。此字段之前写的计划带的是单个 `exec_run:`；把它当作只有一项的列表来读——executor 下次写入时会迁移它（一个 `wkdrs/<run>/` 目录）。

对带 `exec_runs` 的叶子，另读当前 run 的 `wkdrs/<run>/EXEC_LOG.md`：步骤状态表（数 `done` / 总数、注意任何 `blocked`）、"待用户执行（STOP 线）"清单、以及 Notes 里的任何"战略信号"。

## 节点分类

- **根** —— 无 `parent:`（一份 coach 计划）。前缀 1 位。
- **内部** —— 有非空 `children:` 列表（被进一步拆解）。
- **叶子** —— `children:` 为空或不存在。只有叶子可执行。

按 `parent:`（权威）重建父子链，而非按前缀。父之下，子按 `depends_on` 拓扑排序；缺失或有歧义则回退到前缀升序。

## 字形图例（每节点一个）

- `✔` 完成 —— 战略节点设了 `finalized:`；叶子 `exec_status: done`。
- `◐` 进行中 —— 部分章节 `done`/`in_progress`，或六节全 `done` 但未设 `finalized:`（rubric 还没跑），或叶子 `exec_status: in_progress`（有日志则显示 `k/n` 步）。
- `○` 待办 —— 尚未开始（`exec_status` 缺失/`pending`，或全部章节 `pending`）。
- `⊘` 受阻 —— 叶子 `exec_status: blocked`，或其 `depends_on` 未满足的叶子。
- `⏸` 待用户 —— EXEC_LOG 里有未勾选"待用户执行"STOP 命令的叶子。
- `⚠` 需关注 —— 看起来太大、难以直接执行的粗糙叶子（其 §3/§5 大量 `[TBD]`）→ 建议 `/star-plan-decomposer`；或一个 drift 标记（见下）。

每个叶子行显示其 `depends_on`，以及（正在执行时）`k/n` 步。示例：

```
0_open-vocab-det-seg            ◐  战略 6/6 done, 已拆解 (4 个子计划)
├ 00_mvp-3way-ablation          ✔  exec done                        依赖: —
├ 01_core-method-pipeline       ◐  exec 进行中 2/5 步               依赖: 00
│ ├ 010_desc-generation         ✔  exec done                        依赖: —
│ ├ 011_set-matching            ◐  exec 进行中 2/4                  依赖: 010
│ └ 012_det-seg-heads           ○  exec pending                     依赖: 010, 011
├ 02_full-experiments           ⏸  待用户 (1 条 STOP 命令)          依赖: 01
└ 03_writing-submission         ○  exec pending                     依赖: 02
```

## Rollup（三个数）

1. **战略完整度** —— 各战略计划（来自 coach 的根/内部节点）里：`done` 的章节数 /（6 × 战略计划数）。注明哪些未 `finalized:`。
2. **拆解覆盖度** —— 内部节点（已拆解）vs 被标 `⚠` 的粗糙叶子（`done` 的战略节点却从未拆解，或 §3/§5 大量 `[TBD]` 的叶子）。
3. **执行进度** —— 叶子 `exec_status: done` / 总叶子数；以及所有有 run 的叶子的 EXEC_LOG 步 `done` / 总数之和。

## 下一个可执行叶子（唯一建议）

挑**执行顺序里最靠前**、且同时满足以下全部的叶子：

- `exec_status` 既非 `done` 也非 `blocked`；
- 其 `depends_on` 里每个前缀都能解析到一个 `exec_status` 为 `done` 的兄弟；
- 它不是 `⚠` 粗糙叶子（若是，改为建议先拆解它）。

"执行顺序" = 由 `depends_on` 得到的拓扑序，以前缀升序破平局，深度优先遍历（使某个已拆解节点自己的叶子排在它后面的兄弟之前）。输出：`→ 下一个: /star-plan-executor <前缀或 slug>` + 一句话理由。若无合格者，说清挡路者：某个未满足的依赖（点名）、需拆解的粗糙叶子、或一个 `⏸` 等待用户 STOP 命令的叶子（点名该命令）。

## Drift / 一致性标记（只报告，绝不修复）

- **可能过期的子计划** —— 某子计划 `updated` 早于其父计划 `updated`（父计划在拆解后被改）。建议 `/star-plan-decomposer <父计划>` 对账。
- **悬挂链接** —— 某 `children:` 项找不到对应文件，或某计划文件的 `parent:` 指向不存在的文件、或未被其父计划 `## Sub-plans` 索引列出。
- **坏依赖** —— 某 `depends_on` 前缀解析不到现存兄弟，或依赖图里有环。
- **孤儿 run** —— 某个 `exec_runs` 条目指向不存在的 `wkdrs/<run>/` 目录，或某 EXEC_LOG 的 `source_plan` 与叶子不符。

本段保持简短；无任何标记时整段省略。
