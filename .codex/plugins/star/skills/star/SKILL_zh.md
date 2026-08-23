---
name: star
description: 将显式调用的 $star 请求准确路由到一个 STAR 研究工作流 skill。无请求参数时显示当前研究状态。已经选定具体 star-* skill 后不要再使用本路由器。
---

# 路由 STAR 请求

从当前项目根目录读取 `.agents/commands/star.md`，并将其作为权威路由名册。
当 `.env` 设置 `STAR_LANG=zh`，或该变量未设置且对话使用中文时，用户可见措辞使用 `.agents/commands/star.zh-CN.md`，但 skill 名称和路由决策仍以英文名册为准。

只为 Codex 调整调用拼写：

- `$star` 是本通用路由器。
- 当名册写作 `/star-<name> <argument>` 时，以 `$star-<name> <argument>` 调用选中的项目 skill。

不要在本路由器中复述已选 skill 的工作流。
对于未标记的 skill，加载并遵循当前项目可用的对应 `star-*` skill。
对于标有 `†` 的 skill，按名册要求请求确认，显示准确的 `$star-<name> <argument>` 调用，然后等待。

如果 `.agents/commands/star.md` 缺失，应报告当前项目不包含 STAR 路由名册，不要根据插件包猜测。
