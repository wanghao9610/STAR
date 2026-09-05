---
name: star-auto
description: 朝显式调用的 $star-auto 请求给定的目标自动推进 STAR 工作流，凭该调用的授权自行启动每个下一步 skill。用户未敲 $star-auto 时不得使用。
---

# 朝目标自动推进工作流

从当前项目根目录读取 `.agents/commands/star-auto.md`，并将其作为权威流程。
当 `.env` 设置 `STAR_LANG=zh`，或该变量未设置且对话使用中文时，用户可见措辞使用 `.agents/commands/star-auto.zh-CN.md`，但决策仍以英文文件为准。

只为 Codex 调整调用拼写和模型路由：

- `$star-auto <目标> [stop=<停止线>] [involve=<档位>]` 是本命令。
- 当共享文件写作 `/star-<name> <argument>` 时，拼写为 `$star-<name> <argument>`。

本命令启动的每次运行，均按规约 §10.8 解析它的档位和模式例外。随开场 `.env` 装载一次读取对应的 `STAR_PLAN_MODEL`、`STAR_EXEC_MODEL` 或 `STAR_READ_MODEL`。逗号分隔的值先取 `codex:<模型>`，否则取不带标签的模型；带其他宿主标签的条目忽略。解析结果为空即没有指定模型。

解析出的模型非空、不是当前会话实际模型的别名，且本 Codex 运行时能为子代理指定模型时，用 `spawn_agent` 启动该运行并显式传入该模型。运行时提供 `fork_turns` 字段时一律传入 `fork_turns: "none"`，包括不知情复核：本运行时不能在完整 fork 上覆盖模型。未标记的 skill 与 `†` skill 都遵循这条规则。否则保留共享流程：在这里加载并遵循未标记的项目 `star-*` skill，或按共享文件要求派出 `†` skill 的子代理，均不设置模型。

每份按模型路由的子代理交办必须自包含：要求它完整读取所选 skill 的项目 `SKILL.md`；带上原始 skill 调用、解析出的 `tier=<名称>` 与 `involve=<档位>` token、本次调用带有时的 `auto=unattended`，以及由 `STAR_LANG` 或对话解析出的语言。附上当前会话实际出处中的模型 id，但仅限 id。绝不传递父会话的模型解析命令，也不把它的输出当作子代理的模型出处：子代理从自己的会话上下文解析并记录自己的出处。这些路由规则继承共享流程的确认、STOP line、沙箱和审批边界，不授权任何额外操作。

如果 `.agents/commands/star-auto.md` 缺失，应报告当前项目不包含 STAR 自动推进流程，不要根据插件包猜测。
