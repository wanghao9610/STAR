---
description: 朝给定目标自动推进 STAR 工作流，自行启动每个下一步 skill
argument-hint: "[目标] [stop=<停止线>] [involve=<档位>]"
---

读取 `.agents/commands/star-auto.md`，并按它处理此调用：[$@]

对于未标记的 skill，完整读取 `.pi/skills/` 下由 Pi 拥有的副本并遵循它。对于名册中标 † 的 skill，按共享文件所说，派一个子代理完整读取该 Pi 副本并遵循它。
