# 工作流宿主适配说明

**语言：** [English](harness-adapters.md) | 简体中文

本文件保留 STAR 各宿主的调用写法与模型路由实现，对应[通用规约](research-workflow-conventions.zh-CN.md) §10（技能名册与路由）。技能范围、授权、档位归属、迁移条件和溯源要求仍由通用规约定义；本文件只说明各宿主如何应用这些要求。选择调用方式或派发参数前，读取当前宿主对应的条目，并以当前接口实际支持的能力为准。

## 调用写法与配置标签

十五个 skill，在 Claude Code、Cursor、Pi 与 Qwen Code 中写作 `/star-<name>`，在 Codex 中写作 `$star-<name>`，在 Kimi Code 与 DSH 中写作 `/skill:star-<name>`。

| 宿主 | `STAR_HARNESSES` 与模型条目的标签 |
| --- | --- |
| Claude Code | `claude` |
| Codex | `codex` |
| Cursor | `cursor` |
| DSH | `dsh` |
| Kimi Code | `kimi` |
| Pi | `pi` |
| Qwen Code | `qwen` |

模型名保留宿主原有写法，例如 `pi:anthropic/claude-fable-5`、`claude:fable`、`claude:claude-opus-5[1m]`。标签选择、无标签回落与 `@<深度>` 解析遵循通用规约 §10.8（模型与深度路由）。别名比较的一个例子是 `opus` 对应 `claude-opus-5[1m]`：比较时不计上下文窗口后缀，产物中的模型 id 仍按运行时原值记录。

## 模型与思考深度

### Claude Code

Claude Code 从 `bash execs/configure.sh` 写入的 `effort:` frontmatter 取得深度，写入处有两类：各档的清单，以及名为 `star-plan`、`star-exec`、`star-read` 的三个受托者定义——经某份清单发起的运行按该清单所属档位的深度推理，以某个受托者身份派出的子代理按该受托者的深度推理，所以在这里「逐次派发指定深度」就是指定派发成哪个受托者；因此 Claude Code 配置的深度本身也是路由差异，即使档位模型是当前模型的别名也会派发，而以普通子代理类型派出的受托者仍继承派发运行的深度。

### Codex

Codex 无需写静态文件：只要当前 `spawn_agent` 接口与所选模型接受该后缀，每次按档位派发都把它显式传给 `reasoning_effort`；因此 Codex 配置的深度本身就是路由差异，即使档位模型是当前模型的别名也会派发，运行中途换档也能同时更换模型与深度。

直接调用 `star-plan-coach` 或 `star-idea-storm` 时，运行保留在主线程并沿用其 effort；`star-auto` 可以用配置的 PLAN effort 启动它们，并把问题递回。这保留通用规约 §10.8（运行迁移条件）对教练式技能的例外。

### Cursor

Cursor 只认它模型目录里列出的扁平 id，一个深度一个 id——`cursor-grok-4.6-xhigh`、`claude-opus-5-high`——带参数的 `id[effort=<深度>]` 会被拒绝，只以带深度后缀形式存在的基础 id 单独写也解析不了。因此 `bash execs/configure.sh` 把 `.env` 的 `@<深度>` 以 `-<深度>` 接在模型名后，再把这个扁平 id 不加引号写进该档具名代理的 `model:`——Cursor 的加载器会把引号算进模型名。派成 `star-plan`、`star-exec` 或 `star-read`，好让盖章生效。`Task` 也能按次传 `model`，但没有单独的深度参数；传入的 `model` 会盖过文件。本会话 `Task` 的 `model` 可选列表含该盖章 id 时就传它；否则在该列表里找同族且已带所需深度的 slug——`cursor-grok-4.6-xhigh-fast` 这类速度变体也算——找到就传。不要发明 slug，不要把 `@<深度>` 或方括号参数拼进去，也不要传深度不对的同族变体。列表里都没有时，省略 `model`，以免盖过文件盖章，并一次说明按次 slug 不可用。列表里的盖章 id 或变体本身仍是路由差异，即使档位模型是当前模型的别名也会派发；无法应用的深度不得声称已生效。

### Qwen Code

Qwen 的具名代理只取模型名、不取后缀。

### Kimi Code

`--kimi-pool` 要求 `.env` 配置的项目 Python 提供 `tomllib`（Python 3.11+）。它在写入前解析并校验完整修改；不支持的表布局会保持配置不变。

Kimi Code 同样没有逐派发的深度参数：其 `Agent` / `AgentSwarm` 的 `model` 只接受已配置 secondary-model 池中的别名，所以配置的 `@<深度>` 以池中把该模型绑在该深度的别名派发——约定名 `<模型>-<深度>`，即用户在 `~/.kimi-code/config.toml` 注册并列入池的、带该 `default_effort` 的 `[models]` 变体——手工注册一次，或用 `bash execs/configure.sh --kimi-pool` 注册；skill 运行本身绝不写这个文件——因此配置的 Kimi 深度即使档位模型与当前模型相同也构成路由差异；池中没有绑该深度的条目时只传模型，并一次说明深度未能生效；段级的 `[secondary_model].default_effort` 会压过每个变体的绑定。

### DSH 与 Pi

读取各自的技能清单与当前委派接口，只应用实际暴露的模型和深度控制；本说明不为它们补设深度参数。

## 模型来源与写后校验

运行时事件、钩子路径、模型 id 恢复命令及写后校验命令均见 [model_id_spec.zh-CN.md](model_id_spec.zh-CN.md)（逐宿主模型来源说明）。该文件已保留系统提示的来源、会话记录的解析与回落顺序，以及写后校验的具体调用；通用规约 §8（产物与来源记录）保留所有产出方共同遵守的要求。
