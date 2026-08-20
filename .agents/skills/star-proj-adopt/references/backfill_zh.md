# 阶段 `backfill`

在阶段解析为 `backfill` 时读——参数点名了它，或 Step 0 从"已有采纳记录 + 已分解的计划树"自动选中它。走 `survey` 的运行不读本文件。`adopt_spec_zh.md` 的第 7 节随这个阶段搬到了这里：对账规则在下面，不在那边。

## Step B1：清单与 leaf 对账

读 `metds/adopt.md` 和 `metds/plans/` 里的每个 leaf（规约 §5.4）。小树（≤ ~8 个 leaf）通常由主 agent 自己读更省事；更大的则把 leaf 切成互不相交的只读收集，逐 leaf 返回 `{leaf, deliverable_paths, step_paths, done_criterion（原文照录）, exec_status, overlap, weak}`——匹配规则只用得到这些，用不着整份计划正文。主 agent 对每个准备判为 `done` 的 leaf 重读完整 §5，并保留多对多那条规则和确认点。给出映射表：清单条目 → leaf → 它支持的状态（`done` / `in_progress`）→ 证据。两类错配都要如实报告——没有任何 leaf 覆盖的清单条目（计划树漏掉的工作），以及清单够不着的 leaf（真正的新工作，是常态，不是问题）。

## Step B2：确认点 3——逐 leaf 确认

用户逐个确认——条目较多时用一个问题列出全部提议行（可多选），较少时一个一问。未获确认的 leaf 原样不动。标为 `done` 但没有入账 run 的 leaf 是允许的，并记一笔：`star-flow-status` 会把它标为 done-with-no-run，那正是诚实的状态。

## Step B3：写入、记录、汇报

只在获确认的 leaf 上写 `exec_status:`，以及在 S5 已入账 run 时写 `exec_runs:`——只碰 frontmatter 字段，文件里别的一律不动（原则 6）。对获确认且 run 已入账的匹配，同时把那份重建版 `EXEC_LOG.md` 的 `source_plan:` 改为该 leaf 的文件名——用户刚刚确认的正是这层对应关系，日志里留着 `(none)` 会让状态 skill 的 orphaned-run 检查在每个接入 run 上误报。向 `metds/adopt.md` 追加一段带日期的回填记录，写明每个被改动的 leaf 及其证据，并把 frontmatter 的 `backfilled:` 设为今天的日期——哪怕一个 leaf 都没获确认，这个阶段也跑过了，记录里写明即可。状态 skill 的覆盖行读的正是这个字段；不设它，那一行会在健康的项目上一直触发。汇报后交棒 `star-flow-status`，那是接入后的项目第一次拿到诚实的全景图。

## 对账规则

leaf 与清单行只在**证据重叠**时才算匹配：leaf 的 §4 交付路径或 §3 步骤中出现了某条路径、脚本或模块，而它也出现在该行的 `evidence` 或 `run_dir` 里。仅凭名字相似不算匹配——把它作为 `weak` 提出来，交给用户定夺。

对匹配上的每个 leaf，提议的状态如下：

| 清单 `state` | 提议的 leaf `exec_status` |
|---|---|
| `concluded` | `done` |
| `run` | 证据显示 leaf 的 §5 done-criterion 明显已达成时 `done`；否则 `in_progress` |
| `built` | `in_progress` |
| `abandoned` | 不提议——报告出来交给用户决定 |

`exec_runs` 只在该行的 run 已于确认点 2 入账时才写；`done` 但没有入账 run 的 leaf 只写 `exec_status`，并在报告中标出——`star-flow-status` 会把它列在 done-with-no-run 之下。对获确认且 run 已入账的匹配，同一趟把重建日志的 `source_plan:` 更新为该 leaf 的文件名——用户确认的正是这层对应关系。

绝不提议 `blocked`，绝不写 `depends_on`，绝不重排任何东西。当一条清单行匹配到多个 leaf、或多条清单行匹配到同一个 leaf 时，如实呈现并询问——多对多的匹配通常意味着拆解与历史彼此对不上：是信息，不是需要抹平的错误。
