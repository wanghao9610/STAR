# `/star-auto` — 朝给定目标自动推进工作流

读取 `.agents/commands/star-auto.md`，并按它处理用户在本消息中紧邻 `/star-auto` 输入的内容。

对于未标记的 skill，完整读取 `.cursor/skills/` 下由 Cursor 拥有的副本并遵循它。对于名册中标 † 的 skill，按共享文件所说，派一个子代理完整读取该 Cursor 副本并遵循它。
