# 代码审查 — <scope>（<YYYY-MM-DD>）

<!-- 由 /star-code-reviewer 写出。模式：full | plan | path | diff；目标：<原样的参数>；
     审查文件数：<n>。finding 编号 F1、F2、…，均引用 file:line、违反的规则和具体修法。
     无话可说的节收缩为一行——绝不注水。 -->

## 1. 范围与证据基础

<!-- 范围如何解析（计划模式：§2 / §4 交付物 / EXEC_LOG 各贡献了哪些文件）。载入的准绳
     （项目守则、metds/codearc.md、计划 §2–§5）及缺失项。静态证据：compileall 结果；
     ruff/flake8 结果或"未安装"；环境不可用时注明"纯阅读审查"。 -->

## 2. 结论

<!-- 2–4 行：整体状态、各严重度 finding 数量、符合度小结（计划模式）。
     具体而诚实——不虚高，也不危言耸听。 -->

## 3. Findings

<!-- 按严重度分组，按报告顺序编 F 号。只收已确认的 finding；存疑的进 Unconfirmed，
     绝不计入结论统计。空的严重度组直接省略。 -->

### Blocker

- **F1** `<file>:<line>` — <问题>
  - Rule: <准绳> · Evidence: <片段> · Fix: <具体改法>

### Major

### Minor

### Nit

### Unconfirmed

<!-- 值得人看一眼但未核实。每条一行，写明怎样才能确认。 -->

## 4. 计划符合度记分卡

<!-- 仅计划模式；否则一行："非计划范围的审查"。对照磁盘打分，绝不对照 EXEC_LOG 声明。 -->

| 条目 | 结论 | 证据 |
| --- | --- | --- |
| §3.1 <任务> | implemented / partial / missing | <模块/函数，或找过哪里> |
| §4 <交付物> | present / absent | <路径> |
| §5 完成判据 | supported / unsupported | <检查它的机制> |

## 5. 好实践

<!-- ≤3 条值得保留或推广的做法；宁可省略这节，不要硬凑。 -->

## 6. 下一步

<!-- 越界 finding 的路由：功能缺口 → /star-plan-executor <叶子>；计划文本偏差 →
     /star-plan-reviser <slug>；结构性重组 → /star-code-architect；环境不可用 →
     /star-env-builder。然后列修复 pass 候选（机械 findings，按编号）。 -->

## 7. 修复记录

<!-- 由修复 pass 追加：每条可修 finding 一行——F<n>：applied / skipped / reverted（<原因>）
     ——以及提交修复时的 commit hash。未运行修复 pass 时写"未运行修复 pass"。 -->
