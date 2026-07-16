# 审查规范 — 证据收集与报告定义

star-plan-reviser 如何收集证据、报告各节必须包含什么。收集器一律**只读**：绝不创建、编辑或删除任何文件，只报事实、不提修订意见。报告里的一切都来自磁盘上的文件——绝不来自对话记忆。

## 证据来源

| 来源 | 提供什么 |
|---|---|
| 计划文件本身 | 意图：§1 目标、§3 任务、§4 交付物路径、§5 done-criterion、§6 风险；frontmatter 的 `status` / `exec_status` / `exec_run` / `depends_on` / `children` / `updated` |
| `wkdrs/<exec_run>/EXEC_PLAN.md` | executor 当时承诺的动作，以及 STOP 线划在哪 |
| `wkdrs/<exec_run>/EXEC_LOG.md` | 步骤状态、绑定检查的结果、产物路径、"待用户执行"命令、Notes/decisions（含 **Strategy signal** 记录） |
| `wkdrs/<exec_run>/EXPT_ANALYSIS_<日期>.md`（若存在） | star-expt-analyst 的结果审计：run 判定、带每个指标来源的完成判据记分卡、日志健康，以及含 kill-criteria 命中的解读——一份已核实过的证据基础，但仍与其他声明一样要对照磁盘复核 |
| §4 交付物路径 | 磁盘上的产物：是否存在、大小、修改时间、廉价 sanity 检查 |
| §2/§3 点名的 `${CODE_NAME}/` 模块 | 承诺的代码是否落地、与日志声称的改动是否吻合 |
| children 的 frontmatter（根/内部目标） | 每个子计划的章节状态、`exec_status`、`updated`、`depends_on` |
| 已执行后代的日志（根/内部目标） | 与本节点假设相关的 kill-criteria 命中与 strategy signal |

缺失的证据记为"unknown"或"absent"——绝不猜测。

## 收集器契约（结构化返回）

**Log collector**——针对一个 run 目录：

- `steps`——id / 标题 / status / 自报检查结果 / 自报产物路径，每步一行
- `awaiting_user`——记录在案、等待用户执行的命令，或 `none`
- `strategy_signals`——Strategy signal 或 kill-criterion 记录，原文引用，或 `none`
- `log_gaps`——日志缺失或格式异常的字段，或 `none`

**Artifact collector**——针对 §4 的每个交付物路径：

- `path` / `exists` / `size` / `mtime`
- `sanity`——一项廉价内容检查（非空、可解析、行数/键数符合预期），或 `not cheaply checkable`
- `verdict`——`found` / `missing` / `suspect`（存在但 sanity 不过，或早于声称产出它的步骤）

**Code collector**——针对点名的每个模块/入口：

- `path` / `exists` / `consistent`（文件现状与日志声称的新建/修改是否说得通）/ `notes`

所有收集器：只读；宁报"unknown"不猜测；不提修订建议；对 `datas/`、`inits/`、`wkdrs/` 除读取外零接触。

## 核实阶梯

每条完成度声明按实际站住的最高一级打分：

1. 日志说 `done` →
2. ……且绑定的产物在磁盘上存在 →
3. ……且廉价复检通过。

| 结论 | 含义 |
|---|---|
| `met` | 适用于该项的所有梯级全部成立（无产物的步骤可凭 1+3 判 met） |
| `partial` | 部分子项成立，其余不成立 |
| `unmet` | 证据明确表明没做或失败 |
| `unverifiable` | 有声明无产物、产物无法廉价核验、或相互矛盾（日志 `done` 而产物缺失） |

绝不仅凭日志一面之词把 `unverifiable` 抬成 `met`。

**廉价检查边界**：文件存在性 / 大小 / 开头几行、小型解析、校验和、单测量级的命令——大致一分钟内、不占 GPU、不花付费 API、无副作用。超出即为重检查：不要跑；在报告里注明完整复核需要什么。

## 按节点类型圈定范围

- **叶子**：对它自己的 run 走完整阶梯。
- **根/内部**：不逐后代展开——直接读 children 的 frontmatter；只对确实存在的 run 派 log collector；用汇总后的信号审计本节点自己 §1–§6 的假设（子计划的 strategy signal 就是反对父假设的证据）。
- **处处无执行证据**：纯文档审查——记分卡记 `unverifiable`/absent；偏差与候选依据计划文本和用户补充的信息。

## 报告各节

1. **目标回顾**——1–2 行目标；叶子逐字引用其 §5 done-criterion，根/内部写明 finalized 状态与其依赖的关键主张/假设。
2. **实际发生了什么**——步骤 done / blocked / skipped；磁盘核实过的产物；仍在"待用户执行"的命令；根/内部目标附 children 汇总。
3. **完成度记分卡**——每个 §3 任务一行，外加 §5 done-criterion 一行：结论 + 证据指针。
4. **偏差清单**——计划说 X 实际做 Y；计划之外的额外工作；被证据推翻的假设；kill-criteria 命中与原文引用的 strategy signal。
5. **阻塞与遗留**——blocked 的步骤及原因；残留的 `[TBD]` / `【待定】`；执行提出但未回答的问题。
6. **涟漪图**——反向 `depends_on` 边（把本节点列入依赖的兄弟）、由它派生的 children、各修订候选会让什么失效。
7. **修订候选**——编号；每条写明目标章节、改什么、证据、修改草案、爆炸半径分级。

**证据指针**必须具体：`路径[:行号]`、命令及其输出片段、或某个 frontmatter 字段——每条结论至少一个。

**爆炸半径**：`local`（本文件的正文/frontmatter）/ `structural`（树形结构或跨兄弟依赖边 → star-plan-decomposer）/ `strategic`（研究问题、方法赌注或 kill-criteria 被推翻 → star-plan-coach）。

无话可说的节收敛成一行（"None observed."）——绝不注水。
