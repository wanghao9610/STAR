# 模型 id 兜底

**语言：** [English](model_id_spec.md) | 简体中文

[`research-workflow-conventions.zh-CN.md`](research-workflow-conventions.zh-CN.md) §8 那条 `model_id` 规则背后、各运行时各自的细节。钩子注入的那行溯源信息缺失，或者带来的是一条恢复命令而不是 id 时，读这里。规则本身——把运行时为当次写入会话报出的值原样记录，绝不猜——留在 §8，这里不重复。

## 各运行时怎么报

| 运行时 | 钩子 | 事件 | 注入什么 | 值在何时读取 |
|---|---|---|---|---|
| Claude Code | `.claude/hooks/star_model_id.sh` | `SessionStart` | 一条读取本次会话 transcript 的命令；没有可指的记录时才是 id 本身 | 写入当刻 |
| Codex | `.codex/hooks/star_model_id.sh` | `SessionStart` | 一条读取本次会话 rollout 的命令；没有可指的记录时才是 id 本身 | 写入当刻 |
| Cursor | `.cursor/hooks/star_model_id.sh` | `SessionStart` | id | 会话开始时 |
| Kimi | `.kimi-code/hooks/star_model_id.sh` | `UserPromptSubmit` | `~/.kimi-code/config.toml` 里的 `default_model` | 取自配置，从来不是会话 |
| Pi | `.pi/hooks/star_model_id.sh` | `before_agent_start`，由 `.pi/extensions/star-hooks.ts` 接线 | id | 就在要用它的那一问之前；模型每换一次再读一次 |
| Qwen Code | `.qwen/hooks/star_model_id.sh` | `SessionStart` | 一条读取本次会话 transcript 的命令；没有可指的记录时才是 id 本身 | 写入当刻 |

要紧的差别在最后一列。写入当刻读到的值不可能过期；Cursor 与 Kimi 那两行则可能，因为会话中途换模型不会改变它们读的任何东西——这正是 `research-workflow-conventions.zh-CN.md` §8 提醒的那种滞后，如今只剩这两行还有。Pi 在另一个极端，连恢复命令都不需要：它的扩展 API 把当前模型对象（`ctx.model`）交给每个处理器，`/model` 或 `Ctrl+P` 一换就触发 `model_select`，所以那行写的就是即将开跑的那个模型，且每换一次就会再来一行新的——你最后拿到的那行，就是正在写的那个。Claude Code 还会在系统提示里写明模型。钩子文件在，不等于已注册——各运行时的注册方式不同（`.claude/settings.json`、`.codex/hooks.json`、`.cursor/hooks.json`、`.qwen/settings.json`，以及需手动配置的 `.kimi-code/hooks.example.toml`），所以一个项目可能有脚本却什么都没注入。Pi 的注册是代码而不是配置——扩展会被自动发现，但要等项目获得信任之后（`/trust`，或 `defaultProjectTrust`）；未获信任的项目不加载任何项目级扩展，也就什么都不注入。Qwen Code 在这之上还多一个条件：项目级钩子只在被信任的目录里跑，而这一条只在你打开了目录信任（`security.folderTrust.enabled`，默认关闭）时才成立。

## Claude Code、Codex 与 Qwen Code：为什么 id 要在写入当刻才读

`model` 字段只挂在 `SessionStart` 上：Claude Code 与 Codex 在 `/clear`、resume、compact、fork 之后不带它，Qwen Code 则对它报出的每一种启动原因（startup、resume、clear、compact）都带；即便有，它描述的也只是会话开启那一刻——之后 `/model` 换模型不会触发任何钩子，于是以某个模型开始、用另一个模型写入的会话，记下的会是开始时那个。这三个运行时都保有逐回合的实际记录，因此只要载荷里给出了它，注入行带来的就是一条命令而不是 id。记录该值的当刻跑它：

```bash
bash "$CLAUDE_PROJECT_DIR"/.claude/hooks/star_model_id.sh --resolve <transcript_path> [session_model]
bash .codex/hooks/star_model_id.sh --resolve <transcript_path> [session_model]
bash "$QWEN_PROJECT_DIR"/.qwen/hooks/star_model_id.sh --resolve <transcript_path> [session_model]
```

参数用那行已经填好的，把打印出来的值原样记录。Claude Code 这版读的是本次会话主循环 assistant 轮次上的 `message.model`，委派出去的子 agent 轮次会跳过——要问的是哪个模型在写这份产物；Codex 这版读的是 rollout 里 `turn_context` 记录上的 `payload.model`，无需跳过任何东西，因为 Codex 的子 agent 自带独立 rollout；Qwen Code 这版读的是 transcript 里 `type: "assistant"` 记录上的顶层 `model`，同样无需跳过任何东西，因为 Qwen 的子 agent 写的是自己那份 transcript——载荷里以 `agent_transcript_path` 另行指明。三者都是运行时的记录而非猜测。`session_model` 是 `SessionStart` 报出的那个：逐回合记录还没有内容时由它顶上；与解析结果是同一个 id 时以它为准，好保住记录丢掉的后缀（取 `claude-opus-5[1m]` 而非 `claude-opus-5`）；但 id 不同时绝不用它——那个不同就是会话中途换过模型，而看见这件事的是逐回合记录。

## Kimi：一行都没注入时

Kimi 的 `SessionStart` 无法注入上下文、也不暴露模型 id，因此它的钩子改挂在 `UserPromptSubmit` 上，注入配置里的 `default_model`——会话中途换过模型的话它就是过期的。斜杠命令激活 skill 不经过该事件，因此在任何普通用户消息之前打开的 skill 什么都看不到。写 `unrecorded` 之前自己执行一次读取：

```bash
grep -E '^[[:space:]]*default_model[[:space:]]*=' "${KIMI_CODE_HOME:-$HOME/.kimi-code}/config.toml"
```

把读到的值原样记录——仍是自报、仍可能过期。

## 什么时候 `unrecorded` 才是对的

只有当会话里任何地方都没写明模型时：运行时确实没报，且上面每一次读取也都为空。绝不凭行为推断，绝不去想"这大概是哪个模型"，也绝不把一份产物的值抄到另一份上。
