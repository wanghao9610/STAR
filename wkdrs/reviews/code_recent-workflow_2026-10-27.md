# 代码审查 — 最近两次工作流提交（2026-10-27）

<!-- 由 star-code-reviewer 写出。模式：git range；目标：HEAD~2..HEAD。
model_id: gpt-6-astra
review_gate: blocked
-->

## 1. 范围与证据基础

审查版本：`7fd415ad28c8a40d103fdc93c18873e3a47a702f`。范围为 10 月 22 日及 23 日两次提交中的工作流工具、配置、测试及其规则契约。开始时工作区干净，本次未编写范围内的实现。

三名独立只读收集器分别检查 16 个状态工具及测试、28 个配置/启动器/钩子文件、18 个宿主扩展/生成器/检查文件，共 62 个现存代码、配置及测试文件；删除的示例启动器另按 diff 核对。生成的技能副本由 port 检查验证，未逐份重复审查。主审核对来源绑定、方法编译、结果汇总、执行恢复和授权规则的相关 Markdown。为验证新增内容指纹契约，额外打开未修改的 `star-metd-summarize/references/extract_map.md` 及中文版本。

依据：AGENTS.md 的简单实现、局部修改和验证要求；代码审查 rubric 的 E 类（具体输入输出与跨文件契约）及 A 类（说明不能与行为矛盾）；共享规约和 source_state 的来源有效性约定。没有 `metds/codearc.md`，本次不是研究计划符合度审查。独立收集器使用可用的继承模型；配置的 READ 模型 `gpt-6.1-luna@medium` 不在本次工具可选列表中，未声称应用了该模型或深度。主审保留在本会话运行。

验证证据：

| 检查 | 结果 |
| --- | --- |
| `bash .github/scripts/port.sh --check` | 六套生成树各 180/180 文件复现，差异为 0 |
| `bash .github/scripts/check_consistency.sh` | 通过，包括 77 个共享脚本语法检查 |
| `bash .github/scripts/check_model_routing.sh` | 通过 |
| `bash .github/scripts/tests/test_source_state.sh` | 45 个用例通过 |
| `bash .github/scripts/tests/test_finding_resolution.sh` | 33 个用例、320 个断言通过 |
| `bash .github/scripts/tests/test_review_state.sh` | 39 个用例通过 |
| `bash .github/scripts/tests/test_launch_state.sh` | 48 个用例通过 |
| `bash .github/scripts/tests/test_workflow_state.sh` | 25 个用例通过，退出码 0；已核对收集器返回的完整逐例输出 |
| `bash .github/scripts/tests/test_hook_shell.sh` | 126 个用例、290 个断言通过 |
| `bash .github/scripts/tests/test_port_helpers.sh` | 通过 |
| `bash .github/scripts/tests/test_run_launcher.sh` | 通过 |
| `node --test .github/scripts/tests/plan-mode.test.mjs .github/scripts/tests/subagent.test.mjs` | 11 个测试通过 |

主审运行了工作流总入口，并检查上述测试输出；最后的 workflow-state 完成结果采用独立收集器同版本运行的原始结果。Shell、Perl 语法及 scoped diff 检查通过。范围内未发现机器本地路径字面量；较大模块包括 consistency 检查、更新器、Pi 子代理入口和配置器，文件长度本身不作为缺陷。未运行真实 Pi 会话、重实验、网络接口或安装操作；实际宿主交互仍不在这些离线检查的证明范围内。

## 2. 结论

确认 1 项 major 模板与校验器不兼容问题，以及 2 项 minor 文档契约冲突。`review_gate: blocked` 的原因是 F3 会使按模板生成的合法报告无法通过强制来源检查。F3 在两次提交之前已存在，本次报告生成时实际触发；它属于审查范围内的已有缺陷，不算本次提交引入的回归。离线回归用例均通过，未运行真实宿主交互。

## 3. 问题项

### Major

- **F3：代码审查模板的来源标记不能通过模型来源校验。**
  - 位置：`.agents/skills/star-code-reviewer/assets/code_review_template.md:3`、中文模板同一行；`.codex/hooks/star_model_id.sh:92`。
  - 规则：共享规约第 8 节（产物模型来源）要求报告记录模型，当前会话的来源钩子要求写后检查通过才能报告完成；rubric E 要求生产者和消费者契约一致。
  - 证据：模板第一行是标题，第三行才在 HTML 注释中内嵌 `model_id:`。校验器只在 `NR == 1` 读取内嵌标记，其他行则要求独立的 `model_id:` 键。主审按中文模板写出本报告后，来源检查实际返回 `expected 'gpt-6-astra', found '<missing>'`。报告随后在同一注释块内改为独立键，才能满足消费者格式；这仅修正本次新报告，未修改项目模板。
  - 建议：统一中英文模板与钩子支持的格式。最小改动是在模板注释块内使用独立的 `model_id:` 行，并用真实模板生成样例验证写后检查，而不只验证手工构造的首行标记。同步生成树。该缺陷已存在于 `HEAD~2`，此次模板变更和现有回归检查均未覆盖它。

### Minor

- **F1：来源有效性的旧日期规则仍在被流程引用。**
  - 位置：`.agents/skills/star-metd-summarize/references/extract_map.md:123`、中文版本同一行；`docs/mds/star-workflow/research-workflow-conventions.md:261`。
  - 规则：rubric A、E；`star-flow-status/references/source_state.md:26` 明确日期仅作来源信息，不能决定有效性。
  - 证据：方法编译主流程第 84 行已要求内容指纹检查，但提取说明仍称 `sources.updated` 是过期检查依据，共享规约也称日期比较能检测过期。来源在同一天修改时，两套规则可能给出不同结论。
  - 建议：把这些段落统一为“日期保留用于追溯，是否有效由内容绑定及当前来源清单决定”，同步中英文提取说明并重新生成宿主副本。该问题是明确的文字冲突，尚未观察到真实模型因它作出错误结论，故评为 minor。

- **F2：方法正文不变时，缺少明确的仅刷新绑定路径。**
  - 位置：`.agents/skills/star-metd-summarize/SKILL.md:82`；`references/extract_map.md:161` 及中文版本同一行。
  - 规则：rubric E；来源变化后须由生产者核验再记录，缺少绑定的旧文档不能被宣称当前有效。
  - 证据：提取说明要求“全部小节未变的一轮什么都不写”。如果计划变化不影响这份方法摘要，重新编译可以得到相同正文，但旧指纹仍过期；已有正文完全正确而缺少绑定的旧文档也存在同类问题。结果汇总在 `star-expt-analyst/references/aggregate_spec.md:108` 已明确允许核验后只刷新来源信息和绑定，方法编译尚未说明这一例外。
  - 轻量复现：临时目录内创建计划和方法文档，调用 `source_state.sh record ... --kind method --method-plan ...` 得到 current；只在计划末尾添加不影响方法摘要的细节；保持文档正文不变后 `check` 返回 stale、退出码 1；再次 record 后 check 返回 current。工具按预期工作，冲突在生产者的写入规则。
  - 建议：明确“核验后正文未变但绑定过期或缺失时，仅刷新绑定及必要来源信息；正文不变，不能仅重算散列绕过核验”。补一项覆盖生产者决策的场景检查，而不只重复测试散列工具。

### Unconfirmed

无保留的未确认缺陷。未能证明的边界猜测不计入结论。

## 4. 计划符合度记分卡

非计划范围的审查。

## 5. 好实践

启动回执先持久化再清理标记；来源缺失或旧格式返回 unknown；生成树能从作者源完整复现。这些行为都有对应的离线用例。

## 6. 下一步

先修 F3 的模板格式并增加真实模板到来源检查的回归样例，再统一 F1 的过期判定文字，补充 F2 的核验后仅刷新绑定规则。修改共享源后运行生成检查、来源状态用例和规则一致性检查。宿主实际交互可另做小规模烟雾检查。

## 7. 修复记录

未运行修复轮。此次请求是检查与建议，仅新增本报告，没有修改实现、规则或提交 Git。
