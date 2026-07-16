# 修订规则 — 权限、痕迹与涟漪

star-plan-reviser 允许改什么、改动如何记录、什么必须转交别处。一次会话只修订**一个目标文件**（外加至多父计划里对应的那一行索引）。

## 权限表

| 对象 | 是否允许 |
|---|---|
| 目标计划正文 §1–§6（根或子计划） | 允许——逐条经用户批准，一次一条候选 |
| 目标 frontmatter `updated` | 允许——任何编辑后必须更新 |
| 目标章节 `status` 映射 | 允许——如实反映编辑后的内容状态 |
| 目标 frontmatter `depends_on` | 允许——仅作为已批准候选；必须保持为无环的兄弟前缀列表 |
| 目标 frontmatter `exec_status` | 允许——仅按下方重置规则、经明确批准 |
| 父计划 `## Sub-plans` 中目标对应行 | 允许——仅当目标的标题 / 一行目标发生变化 |
| `EXEC_PLAN.md` / `EXEC_LOG.md` | 绝不——run 属于 executor；审查报告写在日志*旁边*，不写进日志 |
| 数字前缀 / 文件名 | 绝不——不重编号、不改名、不分叉 `_v2`、不删除 |
| 兄弟或子计划的正文 | 本次会话绝不——对那个文件单独运行 reviser，或转给 star-plan-decomposer |
| 目标的 `## Revision History` | 只追加——绝不改写既有条目 |

## 该转交的不要编辑

- **structural**——增删子计划、调整粒度、跨兄弟重画依赖边 → 建议 star-plan-decomposer。（编辑*目标自己*的 `depends_on` 列表属于 local、可批准的候选。）
- **strategic**——研究问题、核心方法赌注或方向本身被推翻 → 建议 star-plan-coach。

对战略章节做有界的文本修订仍属 local、是允许的：收紧一条 kill-criterion、给里程碑改期、记录某假设已被验证或已失败。"方法已死，换一个"不是一次编辑——那是一场 coaching 对话。

## Revision History 格式

追加在计划文件末尾（若有 `## Sub-plans` 则在其后）；首次修订时创建该节：

```markdown
## Revision History

### 2026-07-16 — star-plan-reviser (report: wkdrs/00_mvp-3way-ablation/REVIEW_2026-07-16.md)
- §3 step 4: batch eval → streaming eval——run 在 step 4 OOM（证据：EXEC_LOG.md step 4, blocked）
- §5: mIoU 阈值 85 → 80——MVP run 达到 82.3，父计划 §4 的余量分析可接受 80（证据：wkdrs/00_mvp-3way-ablation/eval.json）
- exec_status: done → pending（done-criterion 已变化）
```

每次会话一个 `###` 块，真实日期（绝不编造）；每处改动一个要点：章节、改了什么、为什么、证据。`exec_status` 的重置也记在这里；值得留痕的被拒候选可选记一笔（"用户保留 85 阈值，尽管未达标"）。

## exec_status 重置规则

| 编辑后的情形 | 动作 |
|---|---|
| §5 done-criterion 实质变化，且叶子为 `done` / `blocked` | 提议重置为 `pending`（`exec_run` 保留，指向历史 run） |
| §3 新增或实质改动了步骤，且叶子为 `done` | 提议重置为 `pending` |
| 叶子为 `in_progress` | 不动——executor 下次运行会从 `EXEC_LOG.md` 重新定位 |
| 编辑只涉及 §1/§2/§4 的行文或 §6 风险 | 无需重置——仅更新 `updated` |

绝不悄悄重置；提议时说明后果（该叶子将重新进入 star-plan-status / star-plan-executor 的可执行队列）。

## 章节状态翻转

- 引入 `[TBD]` / `【待定】` 的编辑 → 该节翻为 `in_progress`。
- 无遗留缺口、经确认的重写 → 该节保持（或置为）`done`。
- 仍带 `[TBD]` 的章节绝不标 `done`。

## 涟漪义务

- 每个被编辑的文件都要更新 `updated`。下游的 star-plan-status 会标记比修订后父计划更旧的 children——这种过期提示正是设计意图，不是要压掉的 bug。
- 若修订的内容正是 children 派生的依据，在最终汇报里点名受影响的 children 并建议对它们重新拆解。
- 编辑完成后复核 `children:` 条目与 `depends_on` 前缀仍可解析；报告悬空引用——不要悄悄修复。

## 语言

编辑与审查报告跟随计划 frontmatter 的 `language`；中文计划里技术名词保留英文。对话语言绝不改写文件语言——那需要用户明确要求。
