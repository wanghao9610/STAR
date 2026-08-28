---
name: star-auto
description: 朝显式调用的 /star-auto 请求给定的目标自动推进 STAR 工作流，凭该调用的授权自行启动每个下一步 skill。用户未敲 /star-auto 时不得使用。
disableModelInvocation: true
---

# 朝目标自动推进工作流

从当前项目根目录读取 `.agents/commands/star-auto.md`，并将其作为权威流程。
当 `.env` 设置 `STAR_LANG=zh`，或该变量未设置且对话使用中文时，用户可见措辞使用 `.agents/commands/star-auto.zh-CN.md`，但决策仍以英文文件为准。

只为 Kimi Code 调整调用拼写：

- `/star-auto`（`/skill:star-auto` 的简写）`<目标> [stop=<停止线>] [involve=<档位>]` 是本命令。
- 当共享文件写作 `/star-<name> <argument>` 时，拼写为 `/skill:star-<name> <argument>`。

对于未标记的 skill，通过 Skill 工具启动并遵循当前项目可用的 Kimi 副本。对于名册中标 `†` 的 skill，按共享文件所说，派一个子代理完整读取该 Kimi 副本的 `SKILL.md` 并遵循它。

如果 `.agents/commands/star-auto.md` 缺失，应报告当前项目不包含 STAR 自动推进流程，不要根据插件包猜测。
