# 修订规则 — 权限、痕迹与连带影响

star-plan-reviser 允许改什么、改动如何记录、什么必须转交别处。一次会话只修订**一个目标文件**（外加至多父计划里对应的那一行索引）。

## 权限表

| 对象 | 是否允许 |
|---|---|
| 目标计划正文 §1–§6（根或子计划） | 允许——逐条经用户批准：整张候选清单摊在页面上，用一次提问定下来（规约 §7.13） |
| 目标 frontmatter `updated` | 允许——任何编辑后必须更新 |
| 目标章节 `status` 映射 | 允许——如实反映编辑后的内容状态 |
| 目标 frontmatter `depends_on` | 允许——仅作为已批准候选；必须保持为无环的兄弟前缀列表 |
| 目标 frontmatter `exec_status` | 允许——仅按下方重置规则、经明确批准 |
| 目标 frontmatter `dropped:` | 允许——仅作为已批准候选，按下方丢弃规则 |
| 已丢弃子树在磁盘上的文件（计划文件、`tasks/<plan-name>/`、`wkdrs/<run>/` 目录、`execs/scpts/<run>.sh`） | 允许——仅限已批准的丢弃或恢复所带的、搬进或搬出 `dropped/` 位置的那次移动（`drop_rules_zh.md`）；内容绝不编辑 |
| 父计划 `## Sub-plans` 中目标对应行 | 允许——仅当目标的标题 / 一行目标发生变化，或为它加上、去掉丢弃标记 |
| 目标 `## Sub-plans` 里的概要行（还没展开的单元——规约 §0） | 允许——作为已批准候选：改写、重排、增删概要行；已展开子计划文件的条目仍归 star-plan-decomposer |
| `EXEC_PLAN.md` / `EXEC_LOG.md` | 绝不——run 属于 executor；审查报告写在日志*旁边*，不写进日志 |
| 数字前缀 / 文件名 | 绝不——不重编号、不改名、不分叉 `_v2`、不删除（丢弃的搬移保留每个文件名，变的只是目录） |
| 兄弟或子计划的正文 | 本次会话绝不——对那个文件单独运行 reviser，或转给 star-plan-decomposer |
| 目标的 `## Revision History` | 只追加——新条目加在最后一条之下；绝不改写既有条目 |

## 该转交的不要编辑

- **structural**——增删子计划、调整粒度、跨兄弟重画依赖边 → 建议 star-plan-decomposer。（编辑*目标自己*的 `depends_on` 列表属于 local、可批准的候选——修目标的概要行也是：还没展开成文件的单元只是文字，不是结构。把某条展开成文件才归 decomposer。）
- **strategic**——研究问题、核心方法关键假设或方向本身被推翻 → 建议 star-plan-coach。

对总体计划章节做范围受限的文本修订仍属 local、是允许的：收紧一条 kill-criterion、给里程碑改期、记录某假设已被验证或已失败。"方法已死，换一个"不是一次编辑——那是一场重新做计划的对话。

## Revision History 格式

追加在计划文件末尾（若有 `## Sub-plans` 则在其后）；首次修订时创建该节，每条新条目接在上一条之下：

```markdown
## Revision History

### 2026-07-16 — star-plan-reviser · claude-opus-4-8 (report: wkdrs/01_mvp-verify/REVIEW_2026-07-16.md)
- §3 step 4: batch eval → streaming eval——run 在 step 4 OOM（证据：EXEC_LOG.md step 4, blocked）
- §5: mIoU 阈值 85 → 80——MVP run 达到 82.3，根计划 §4 的余量分析可接受 80（证据：wkdrs/01_mvp-verify/eval.json）
- exec_status: done → pending（done-criterion 已变化）
```

每次会话一个 `###` 块，真实日期（绝不编造），并在 skill 名之后写上本次编辑会话的 `model_id`——运行时报出的 id 原样抄录，没有则写 `unrecorded`（规约 §8）。这个逐条记录的 id 就是计划的模型归属依据：frontmatter 的 `model_id` 只写明最近一次写入者；更早的修订出自谁手保留在本节。每处改动一个要点：章节、改了什么、为什么、证据。`exec_status` 的重置、以及被清除的 `finalized:` 也记在这里；值得留痕的被拒候选可选记一笔（"用户保留 85 阈值，尽管未达标"）。丢弃同样是其中一条要点——`dropped: 2026-08-11 — 被 02 取代`——什么终结了这个方向写在这一条里，因为 frontmatter 那个字段只放得下一行。

## exec_status 重置规则

| 编辑后的情形 | 动作 |
|---|---|
| §5 done-criterion 实质变化，且叶子为 `done` / `blocked` | 提议重置为 `pending`（`exec_runs` 无论如何都留着历史） |
| §3 新增或实质改动了步骤，且叶子为 `done` | 提议重置为 `pending` |
| 叶子为 `in_progress` | 不动——executor 下次运行会从 `EXEC_LOG.md` 重新定位 |
| 编辑只涉及 §1/§2/§4 的行文或 §6 风险 | 无需重置——仅更新 `updated` |

绝不悄悄重置；提议时说明后果（该叶子将重新进入 star-flow-status / star-plan-executor 的可执行队列）。

## 丢弃一份计划（`dropped:`）

一次丢弃写什么、绝不动什么、以及怎么走回来，都在 `drop_rules_zh.md`，本次运行是丢弃或恢复时才读，之前不读。

## 章节状态翻转

- 引入 `[TBD]` / `【待定】` 的编辑 → 该节翻为 `in_progress`。
- 无遗留缺口、经确认的重写 → 该节保持（或置为）`done`。
- 仍带 `[TBD]` 的章节绝不标 `done`。

## 连带影响义务

- 每个被编辑的文件都要更新 `updated`。下游的 star-flow-status 会标记比修订后父计划更旧的 children——这种过期提示正是设计意图，不是要压掉的 bug。
- 若修订的内容正是 children 派生的依据，在最终汇报里指明受影响的 children 并建议对它们重新拆解。
- 编辑完成后复核 `children:` 条目与 `depends_on` 前缀仍可解析；报告悬空引用——不要悄悄修复。

## 语言

编辑与审查报告跟随计划 frontmatter 的 `language`；中文计划里技术名词保留英文。对话语言绝不改写文件语言——那需要用户明确要求。
