---
description: 将请求路由到正确的 STAR skill，或汇报下一步动作
argument-hint: "[你希望完成的工作]"
disable-model-invocation: true
---

读取 `.agents/commands/star.md`，并把其中的路由规则应用于此请求：[$ARGUMENTS]

对于未标记的 skill，通过 Skill 工具启动 Claude 拥有的副本，使其模型、推理强度和分叉设置生效。空请求选择不带参数的 `star-flow-status`。
