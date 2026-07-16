# 编排规范

本 skill 的主循环如何调度 `Task` subagent。同门契约：executor 的 `agent_dispatch_spec.md`——同一套哲学，适配到勘察与迁移场景。主循环负责编排、复核、提交；它自己不改代码。

## 角色

- **主循环（架构师）**——制定方案、执行两道门、划分工作、亲自重跑检查、打提交检查点、回滚失败。
- **勘察者**——只读 `Task` subagent（`subagent_type: explore`），一线一个（`survey_spec_zh.md`）。
- **迁移者**——`Task` subagent（`subagent_type: generalPurpose`），每组一个，写权限仅限本组文件。

## 迁移分组

1. 只取门 2 批准的条目。
2. 分组时保证**文件所有权互不相交**：任何文件不得同属两组（被移动的文件和因移动而需改 import 的文件都算）。两条目争用同一文件时，合并成一组。
3. 无相互依赖的组可并行，**最多同时 3 个**；有 import 链依赖的组串行，上游先行。
4. 每组前置条件：其涉及路径在 git 中是干净的（没有未暂存/未提交的改动）。

## 派发契约（迁移者）

给每个迁移者：

- **范围**——本组迁移条目原文照录，外加："**只做**这些条目；不顺手改别的，不做条目之外的重命名，不做风格美化"（AGENTS.md §3）。
- **文件**——它拥有的明确文件清单（被移动的文件 + 需修 import 的位置）。
- **操作性质**——移动/重命名及其连带的 import/路径修正；不改任何行为。
- **运行时**——检查通过 `.env` 的 conda 环境跑（`CONDA_HOME`/`PYTHON_HOME`）；`python -m compileall -q` 永远可用（无需依赖）。
- **返回**（结构化）：`changed`——文件，每项一行；`ran`——命令 + 结果，或 `none`；`check`——本组绑定检查的结果，`pass`/`fail` + 证据；`blockers`——或 `none`。

## 迁移者返回之后

**主循环亲自重跑验证**——绝不信任自报的 `pass`：

1. `python -m compileall -q ${CODE_NAME}`；环境可用时再做 import 扫描与快速测试。
2. **通过** → 提交 `star-code-architect: migrate <ids> — <summary>`，只暂存本 skill 涉及的路径；更新迁移记录。
3. **失败** → 把失败信息喂回，有界重试（≤2）。仍失败 → 回滚该组路径（`git restore` / `git checkout -- <paths>`），在 `codearc.md` §6 把其条目标 `blocked` 并记下 blocker，继续其他组。

## STOP 线（本 skill 版本）

以下操作绝不擅自执行——准备好确切命令、写进汇报、移交用户：

- 涉及 CUDA/C++ 编译的环境构建（带扩展算子的 `pip install`、含此类依赖的 `conda env create`）。
- 超过约 1 GB 的下载（权重、数据集）。
- 完整测试套件、benchmark，以及任何训练。

纯 Python 的轻量安装仅在用户当场明确同意后才可执行。拿不准就当重操作处理。
