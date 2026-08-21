# Step 8：新增依赖（仅 add 模式）

在调用带 `add <包名>…` 时读。本技能的其余每一次运行——创建环境，或就地校验与修复——都不读本文件。

环境已存在；本模式只往里装，并记录装了什么——环境坏了是一次完整 run 的事（Step 2 的*原地验证修复*）。

1. 按原则 1 从 `.env` 解析 `ENV_PY`。没有可用解释器 → 如实说明并建议跑一次完整的 `star-env-builder`；什么都不装。
2. 按 `references/installer_policy_zh.md` 给每个包归类——framework / runtime / optional / conda 专属——并说明各自落进哪个 requirements 文件。
3. **确认点**（原则 2——确认点之前不装任何东西）：呈现这些包、它们的类别、将用的版本与索引源、下载量大时的估计、以及任何 CUDA 耦合；询问*批准并安装* / *调整* / *中止*。
4. 按优先顺序安装（uv > pip > conda；conda 仅在 conda 后端下、且仅限白名单）。需要源码编译的项留在红线上：把确切命令备好，不要跑。
5. 只对新增包做跑通性检查（`references/runnable_check_spec_zh.md`）：L1——每个包都能经 `$ENV_PY` 导入并报出版本；新增的 framework 包再加 L2。失败 → 诊断，重试一次，仍失败则标记 `blocked` 并汇报；绝不留下"装了但没验证"的包。
6. 把每个装好的包追加进所属的 requirements 文件，保留布局既有的顺序与锁定。在最新的 `wkdrs/env_<ENV_NAME>_<日期>/ENV_REPORT.md` 追加一个 `## Added <日期>` 块（没有报告就新写一份）。提交：`star-env-builder: add <包名>`，只暂存 `${CODE_NAME}/requirements*`。
7. 汇报 ≤500 字：装了什么、各 requirements 文件增加了什么、跑通性检查证据、blocked 或待用户处理的项。

