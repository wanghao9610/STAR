---
name: star-auto
description: 朝显式调用的 /star-auto 请求给定的目标自动推进 STAR 工作流，凭该调用的授权自行启动每个下一步 skill。用户未敲 /star-auto 时不得使用。
disableModelInvocation: true
---

# 朝目标自动推进工作流

从当前项目根目录读取 `.agents/commands/star-auto.md`，并将其作为权威流程。
当 `.env` 设置 `STAR_LANG=zh`，或该变量未设置且对话使用中文时，用户可见措辞使用 `.agents/commands/star-auto.zh-CN.md`，但决策仍以英文文件为准。

只为 Kimi Code 调整调用拼写和模型路由：

- `/star-auto`（`/skill:star-auto` 的简写）`<目标> [stop=<停止线>] [involve=<档位>]` 是本命令。
- 当共享文件写作 `/star-<name> <argument>` 时，拼写为 `/skill:star-<name> <argument>`。

本命令启动的每次运行，均按规约 §10.8 解析它的档位和模式例外，再取该档位键的 `kimi` 条目；没有则取不带标签的备选。解析出的值非空、当前 `Agent` 或 `AgentSwarm` schema 提供 `model` 时，只有已配置的 secondary-model pool 接受该别名，才派一个子代理在该别名上完整运行所选 skill；未标记和 `†` skill 都同样处理。交办必须自包含：Kimi 副本的 skill 路径并要求完整读取、原始调用、解析出的 `tier=<名称>` 与 `involve=<档位>`、本次调用带有时的 `auto=unattended`，以及由 `STAR_LANG` 或对话解析出的语言。它继承共享流程的一切确认、STOP line、沙箱与审批边界；模型路由不额外授权任何操作。绝不传递父会话的模型解析命令；受托者记录自己会话的实际模型。

档位值为空、没有可选 pool、没有 `model` 字段、pool 被强制选定、别名不可用，或被拒的派发确认尚未开始工作时，保留原路由：未标记的 skill 通过 Skill 工具启动并遵循当前项目可用的 Kimi 副本；名册中标 `†` 的 skill 按共享文件要求派出子代理。键已设但无法路由时说明一个原因，不要在本次运行修改用户的 Kimi 配置。

如果 `.agents/commands/star-auto.md` 缺失，应报告当前项目不包含 STAR 自动推进流程，不要根据插件包猜测。
