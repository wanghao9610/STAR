---
description: 朝给定目标自动推进 STAR 工作流，自行启动每个下一步 skill
---

读取 `.agents/commands/star-auto.md`，并按它处理此调用：[{{args}}]

对于未标记的 skill，完整读取 `.qwen/skills/` 下由 Qwen 拥有的副本并遵循它。对于名册中标 † 的 skill，按共享文件所说，派一个子代理完整读取该 Qwen 副本并遵循它。
