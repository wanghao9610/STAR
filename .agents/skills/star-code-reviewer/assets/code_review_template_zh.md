# 代码审查 — <scope>（<YYYY-MM-DD>）

<!-- 由 star-code-reviewer 写出（model_id: <模型 id，写入时由运行时自报；运行时未提供则写 "unrecorded"——见 docs/mds/star-workflow/research-workflow-conventions.md §8>）。模式：full | plan | path | diff；目标：<原样的参数>；
     review_gate: blocked
     仅在已核实无未解决的 blocker/major 且行为与约束覆盖充分时改为 passed；审查者负责判定。
     使用 scripts/review_state.sh 记录最终报告及明确的源码/配置/计划范围；报告变更或修复验证后重新记录。
     审查文件数：<n>。问题项编号 F1、F2、…，均引用 file:line、违反的规则和具体修法。
     无话可说的节收缩为一行——绝不注水。 -->

## 1. 范围与证据基础

<!-- 范围如何解析（计划模式：§2 / §4 交付物 / EXEC_LOG 各贡献了哪些文件）。载入的评判依据
     （项目守则、metds/codearc.md、计划 §2–§5）及缺失项。各语言的行为证据：具体输入/输出、边界与失败用例、跨文件契约。
     静态/运行证据：已安装的 Python、shell、JS/TS、配置检查的确切窄范围命令及结果；
     明列缺失工具和未验证行为。其他语言审查不以 Python 为前提。范围内筛查：在所审文件上检查机器本地路径字面量、过大模块与（改动可能波及时）codearc.md 受保护名称的结果；为核对契约额外加入的路径及原因。
     代码版本：审查时的 head commit（`git rev-parse --short HEAD`），run 记有执行分支时在旁边写上分支。明确列出源码/配置文件或目录范围及提供约束的叶子/祖先计划；
     REVIEW_STATE.md 记录绑定这些内容和这份报告的完整内容，不按日期判断有效性。 -->

## 2. 结论

<!-- 简要写：整体状态、各严重度问题项数量、符合度小结（计划模式）。
     说明 passed/blocked 判定依据与未解决 blocker/major 数量。
     具体而诚实——不虚高，也不危言耸听。 -->

## 3. 问题项

<!-- 按严重度分组，按报告顺序编 F 号。只收已确认的问题项；存疑的进 Unconfirmed，
     绝不计入结论统计。空的严重度组直接省略。 -->

### Blocker

- **F1** `<file>:<line>` — <问题>
  - Rule: <评判依据> · Evidence: <片段> · Fix: <具体改法>

### Major

### Minor

### Nit

### Unconfirmed

<!-- 值得人看一眼但未核实。每条一行，写明怎样才能确认。 -->

## 4. 计划符合度记分卡

<!-- 仅计划模式；否则一行："非计划范围的审查"。对照磁盘打分，绝不对照 EXEC_LOG 的说法。 -->

| 条目 | 结论 | 证据 |
| --- | --- | --- |
| §3.1 <任务> | implemented / partial / missing | <模块/函数，或找过哪里> |
| §4 <交付物> | present / absent / pending | <路径，或待执行的红线命令> |
| §5 完成判据 | supported / unsupported | <检查它的机制> |

## 5. 好实践

<!-- 少数值得保留或推广的做法；宁可省略这节，不要硬凑。 -->

## 6. 下一步

<!-- 越界问题项的转交去向：功能缺口 → star-plan-executor <叶子>；计划文本偏差 →
     star-plan-reviser <slug>；结构性重组 → star-code-architect；环境不可用 →
     star-env-builder。然后列修复轮候选（例行问题项，按编号）。 -->

## 7. 修复记录

<!-- 由修复轮追加：每条可修问题项一行——F<n>：applied / skipped / reverted（<原因>），并写明授权来源
     ——以及提交修复时的 commit hash。未运行修复轮时写"未运行修复轮"。 -->
