---
description: 将请求路由到正确的 STAR skill，或汇报下一步动作
---

读取 `.agents/commands/star.md`，并把其中的路由规则应用于此请求：[{{args}}]

对于未标记的 skill，完整读取 `.qwen/skills/` 下由 Qwen 拥有的副本并遵循它。空请求选择不带参数的 `star-flow-status`。
