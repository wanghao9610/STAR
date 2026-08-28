---
description: 朝给定目标自动推进 STAR 工作流，自行启动每个下一步 skill
argument-hint: "[目标] [stop=<停止线>] [involve=<档位>]"
disable-model-invocation: true
---

读取 `.agents/commands/star-auto.md`，并按它处理此调用：[$ARGUMENTS]

对于未标记的 skill，通过 Skill 工具启动 Claude 拥有的副本，使其模型、推理强度和分叉设置生效。对于名册中标 † 的 skill，按共享文件所说，派一个子代理完整读取 `.claude/skills/` 下由 Claude 拥有的副本并遵循它。
