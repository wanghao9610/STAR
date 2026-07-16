# Agent 派发契约（Cursor Task）

EXEC_PLAN 里每个步骤(或每个连贯步骤组)用 `Task` 派一个 subagent。优先 `subagent_type: generalPurpose`;只读勘察可用 `explore`。主循环负责编排与验证;agent 只做这一步的改/跑。让 agent 保持窄,以便失败可定位、上下文短。

## 交给 agent 什么

- **范围**——该步目标,逐字取自 EXEC_PLAN,加上它绑定的 check。明确写:"**只**做这一步;不要推进到后续步骤。"
- **文件**——`${CODE_NAME}/` 下要新建或修改的确切文件/模块(取自差距清单)。要求它匹配既有代码风格,只碰这一步需要的地方(AGENTS.md §3,surgical changes)。
- **运行环境**——走 `.env` 的 conda 环境(`CONDA_HOME` / `PYTHON_HOME`);绝不用系统 python、绝不硬编码本地路径(AGENTS.md §6)。
- **边界**——它**只能跑轻量验证**。若它的步骤在 STOP 线上,必须**备好命令并返回,不要跑**(`stop_line_rules_zh.md`)。
- **产出**——产物存哪(`wkdrs/<run>/…`)。

## agent 必须返回什么（结构化）

- `changed`——新建/修改的文件,每个一行。
- `ran`——实际跑过的命令 + 结果,或 `none`。
- `check`——绑定 check 的结果:`pass` / `fail` + 证据(测试输出、指标、产物路径)。
- `blockers`——让它停下的东西,或 `none`。
- `handoff`——为用户备好的任何 STOP 线命令,或 `none`。

## agent 返回后

**主循环——而非 agent——重跑绑定的 check** 确认,再 checkpoint 到 EXEC_LOG。没有证据不轻信自报的 `pass`。

- **通过** → 在 EXEC_LOG 把该步标 `done`,附产物路径 + 检查结果;更新子计划 `exec_status` / `updated`。
- **失败** → 有限重试(≤2),把失败喂回下一次派发。仍失败 → 该步标 `blocked`,记下 blocker,带日志停下。
- **有 handoff** → 把命令移到 EXEC_LOG"待用户执行"并停下;不要跑它。
