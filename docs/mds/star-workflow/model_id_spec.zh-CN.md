# 模型 id 兜底

**语言：** [English](model_id_spec.md) | 简体中文

[`research-workflow-conventions.zh-CN.md`](research-workflow-conventions.zh-CN.md) §8 那条 `model_id` 规则背后、各运行时各自的细节。钩子注入的那行溯源信息缺失，或者带来的是一条恢复命令而不是 id 时，读这里。规则本身——把运行时为当次写入会话报出的值原样记录，绝不猜——留在 §8，这里不重复。

## 各运行时怎么报

| 运行时 | 钩子 | 事件 | 注入什么 |
|---|---|---|---|
| Claude Code | `.claude/hooks/star_model_id.sh` | `SessionStart` | id；运行时没报时是一条恢复命令 |
| Codex | `.codex/hooks/star_model_id.sh` | `SessionStart` | id |
| Cursor | `.cursor/hooks/star_model_id.sh` | `SessionStart` | id |
| Kimi | `.kimi-code/hooks/star_model_id.sh` | `UserPromptSubmit` | `~/.kimi-code/config.toml` 里的 `default_model` |

Claude Code 还会在系统提示里写明模型。钩子文件在，不等于已注册——各运行时的注册方式不同（`.claude/settings.json`、`.codex/hooks.json`、`.cursor/hooks.json`，以及需手动配置的 `.kimi-code/hooks.example.toml`），所以一个项目可能有脚本却什么都没注入。

## Claude Code：会话不是全新开始时

`model` 字段只挂在 `SessionStart` 上，`/clear`、resume、compact、fork 之后就会缺失。此时注入行带来的是一条恢复命令而不是 id。写 `unrecorded` 之前先跑它：

```bash
bash "$CLAUDE_PROJECT_DIR"/.claude/hooks/star_model_id.sh --resolve <transcript_path>
```

路径用那行点出的那个，把打印出来的值原样记录。它读的是本次会话自己的 assistant 轮次上的 `message.model`，因此是运行时的记录而非猜测——只是可能丢掉 `SessionStart` 字段本会带上的上下文窗口后缀（`claude-opus-5[1m]` 会解析成 `claude-opus-5`）。

## Kimi：一行都没注入时

Kimi 的 `SessionStart` 无法注入上下文、也不暴露模型 id，因此它的钩子改挂在 `UserPromptSubmit` 上，注入配置里的 `default_model`——会话中途换过模型的话它就是过期的。斜杠命令激活 skill 不经过该事件，因此在任何普通用户消息之前打开的 skill 什么都看不到。写 `unrecorded` 之前自己执行一次读取：

```bash
grep -E '^[[:space:]]*default_model[[:space:]]*=' "${KIMI_CODE_HOME:-$HOME/.kimi-code}/config.toml"
```

把读到的值原样记录——仍是自报、仍可能过期。

## 什么时候 `unrecorded` 才是对的

只有当会话里任何地方都没写明模型时：运行时确实没报，且上面每一次读取也都为空。绝不凭行为推断，绝不去想"这大概是哪个模型"，也绝不把一份产物的值抄到另一份上。
