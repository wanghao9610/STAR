---
type: insight
scope: global
language: zh
verified: 2026-08-13
model_id: claude-opus-5[1m]
source: conversation
---

七个宿主里只有四个能从项目文件里读斜杠命令：Claude Code 读 `.claude/commands/*.md`（`$ARGUMENTS` 取参数），Cursor 读 `.cursor/commands/*.md`（无参数占位符，frontmatter 也无文档），Qwen Code 读 `.qwen/commands/*.md`（`{{args}}` 取参数，可选 `description` 字段，TOML 格式已废弃），Pi 读 `.pi/prompts/*.md`（`$@` 取参数）。Kimi Code、DeepSeek Harness、Codex 没有这个机制。

**Why:** 三家各有各的原因，形状还不一样。Kimi 的配置树下只有 agents、config、credentials、local、logs、mcp、skills、statusline、themes、tui 十个目录，没有 commands/prompts，命令来自内置源码和插件注册；它自带的导入技能还明写「不迁移 Claude 自定义命令（`.claude/commands/**`），不在范围内」。DSH 的命令是插件用 TypeScript 写的 `CommandDefinition`，官方文档写明它「直接对指定 agent 执行，不产生模型消息」，结果是「直接的 UI 输出，不是工具结果也不是会话事件」——所以就算写插件，DSH 的命令也**无法向模型投一段提示词**，做不成提示词模板。Codex 二进制里只有 `.codex/config` 和 `.codex/skills` 两个路径，唯一的 `custom_prompt` 字样是 `/review` 的自定义评审输入框。

**How to apply:** 要给某棵树加提示词型命令（比如分流用的 `/star`）时，先按上面这张表判断有没有位置，别去查文档撞运气——Cursor 的命令文档只讲了目录和 Markdown，参数和 frontmatter 都没写，所以那份要么不用参数占位符，要么先实测。给那三棵树补入口只有一条路：加一个当分流器用的技能，靠各家自己的技能调用进入（Kimi/DSH 是 `/skill:star`，Codex 是 `$star`）——代价是 CI 强制七棵树技能集合一致，十六个技能要铺满七棵树，README 和文档里「十五个技能」的说法也要跟着改。依据是 2026-08-13 本机安装的版本（kimi、codex 本地包，Cursor 1.6 更新日志，Qwen Code 官方文档，DSH 仓库 `docs/subsystems/commands.md`），宿主升级后值得重查。
