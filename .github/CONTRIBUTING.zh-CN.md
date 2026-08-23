# 维护 STAR

本文面向修改 STAR 本身的人。**不**适用于基于 STAR 建立的项目——`.github/` 不在 `execs/update.sh` 的同步集合内，快速开始也会要求用户删除它。

## 问题的形态

十五个 skill 在 `.agents/skills/`、`.claude/skills/`、`.cursor/skills/`、`.dsh/skills/`、`.kimi-code/skills/`、`.pi/skills/` 和 `.qwen/skills/` 中各存在一套——每棵目录树 182 个 Markdown 文件，总计 1274 个，约占仓库的 92%。每棵树中的 125 个文件并非副本：中性目录树采用相同措辞，因此只在 `.agents/skills/` 下保存一份，其余位置都链接到它。另 57 个文件由 `.github/scripts/port.sh` 从 `.claude/skills/` 中唯一的手写版本生成，生成过程使用逐宿主替换表和 override 列表；后者保存每棵树真正采用自己措辞的全部片段。链接只能指向 `.agents/skills/`，所以若干目录树共享一种措辞而中性目录树不用它时，每棵树仍各保存一份。CI 会运行检查；直接编辑某棵目录树会使它不再符合生成结果。

`.agents/skills/` 不是任何工具的私有目录树。`AGENTS.md` 约定把 skill 放在这里，因此 Codex 把它作为唯一项目根目录扫描，Cursor 把它作为原生根目录扫描，Pi 和 DSH 也会在读取各自目录的同时读取它——任何遵循该约定的代理都能找到相同的十五个 skill。正因如此，只有这棵树不点名任何宿主工具；参见“哪些必须不同，哪些绝不能不同”。

所以修改一条共享规则的成本按文件数而不是按行数衡量。近期例子：

| 提交 | 文件数 | 改动 |
|---|---|---|
| `78fadc5` | 25 | 把控制旋钮标识统一为 `involve` |
| `1289ac4` | 26 | 公开 `involve=` token |
| `e9d6d28` | 34 | 在长问题序列中持续携带 QA 线程 |

**编辑七棵目录树前，先判断该规则是否更适合放进 `docs/mds/star-workflow/research-workflow-conventions.md`。**一致性检查 6 会证明每个 `SKILL.md` 都服从该文档，因此在那里声明的规则只需两个文件（英文和中文）就能触达十五个 skill。`877aaec` 就这样用 2 个文件而非 24 个文件修复了十二个 skill 的 `involve=` token。只要规则并非宿主特有，就优先采用这种方式。

## `.claude/skills/` 是基线

先在那里编辑，再向外移植。

原因不是其他目录树最像它——事实并非如此。把调用 token 和 `disable-model-invocation` 行标准化后，各目录树与它的距离大致相当：

157 个 Markdown 文件中有 61 个根本不是副本——没有目录树采用不同措辞，因此它们只在 `.agents/skills/` 下保存一份，其余位置都链接过去。在每棵树自行措辞的 96 个文件中：

| 目录树 | 与 `.claude` 字节完全相同 |
|---|---|
| `.agents` | 43 / 96 |
| `.cursor` | 51 / 96 |
| `.dsh` | 52 / 96 |
| `.kimi-code` | 56 / 96 |
| `.pi` | 48 / 96 |
| `.qwen` | 52 / 96 |

原因在于可度量的完整性：**对于 157 个文件中的任何一个，`.claude` 的标题数都不会少于其他目录树。**目录树在结构上不同时，`.claude` 是超集。从最长版本开始移植意味着删减适配，比重建已经丢掉的文本更安全——后者正是下文“检查捕捉不到什么”所述的故障模式。

## 哪些必须不同，哪些绝不能不同

六棵具名目录树各自点名本宿主的工具；共享根目录不点名任何工具，因为它不属于任何单一宿主。这是有意设计，也是最常被误判成漂移的地方。

| 目录树 | 工具 | 调用方式 | 门槛 | 委派 | 用户问题 |
|---|---|---|---|---|---|
| `.agents` | 任何读取 `AGENTS.md` 根目录的代理 | `star-*`，无前缀 | “你的计划工具” | “只读子代理”/“写入子代理” | “你的提问工具” |
| `.claude` | Claude Code | `/star-*` | `EnterPlanMode` / `ExitPlanMode` | `Agent`，`subagent_type: Explore` / `general-purpose` | `AskUserQuestion` |
| `.cursor` | Cursor | `/star-*` | `SwitchMode` → `plan` | `Task`，`subagent_type: explore`；写入委派不设类型 | `AskQuestion` |
| `.dsh` | DSH | `/skill:star-*` | 仅 `exit_plan_mode`——由人进入计划模式 | `subagent`，完全没有类型参数 | `ask_user_question` |
| `.kimi-code` | Kimi | `/skill:star-*` | `EnterPlanMode` / `ExitPlanMode` | `Agent`，`subagent_type: explore` / `coder` | `AskUserQuestion` |
| `.pi` | Pi | `/star-*` | `/star-plan` 是用户的开关，因此 skill 自行守门 | `star_subagent`，用 `agent:` 点名 `.pi/agents/` 条目 | `star_questionnaire` |
| `.qwen` | Qwen Code | `/star-*` | `enter_plan_mode` / `exit_plan_mode` | `agent`，`subagent_type: Explore` / `general-purpose` | `ask_user_question` |

如果不确定某个差异究竟是适配还是漂移，可用实际分布做合理性检查：提问工具按名称分布——`AskUserQuestion` 在 `.claude` 和 `.kimi-code` 中各出现 32 个文件，`AskQuestion` 在 `.cursor` 中出现 32 个，`ask_user_question` 在 `.qwen` 中出现 32 个；`SwitchMode` 在 `.cursor` 的 2 个文件中出现，其他地方为 0；子代理工具 `Agent` 在 `.claude` 和 `.kimi-code` 中各出现 28 个文件，`Task` 在 `.cursor` 的 28 个文件中出现，`agent` 在 `.qwen` 相同的 28 个文件中出现（其中两个 `exec_plan` 模板把裸词用作角色而非工具，所以普通 grep 会得到 30）。四者都带 `subagent_type`。终端工具 `Bash` 在 `.claude` 和 `.kimi-code` 中各出现 30 个文件，`Shell` 在 `.cursor` 的 30 个文件中出现，`run_shell_command` 在 `.qwen` 的 30 个文件中出现；文件读取器 `Read` 在 `.claude`、`.cursor` 和 `.kimi-code` 中各出现 28 个文件，`read_file` 在 `.qwen` 的 28 个文件中出现。某个词只集中在真正拥有该词的宿主目录树中时，几乎总是正确的。

**`.agents` 在上述各行中的出现次数都是零**，由检查 23 保持这一点：其禁用列表是其余目录树的并集——包含每种宿主的文件读取器、终端、提问工具和计划工具，也包括 Codex 自身的工具。在这棵树中，装载写成“读取文件”，终端调用把 `shell` 当作普通英语词而非名称；它仍保留带标记的后备方案，用 shell 调用 `cat` 文件并接受结果被写到磁盘，因为到达这里的宿主可能没有读文件工具：Codex 只有这个项目根目录，而且没有独立读文件工具。

六棵具名目录树中的每个名称都依据各自宿主的工具列表检查，而不是依据其他目录树的写法：Anthropic 的 Agent Skills 文档、Cursor 的工具界面、[Kimi Code CLI 内置工具参考](https://moonshotai.github.io/kimi-code/en/reference/tools.html)，以及 Qwen Code 自身源码和捆绑 skill。Codex 的列表来自 `openai/codex` 的工具处理器（`codex-rs/core/src/tools/`），注册名称是 `shell_command`、`apply_patch`、`update_plan`、`request_user_input` 和 `spawn_agent`——这是修改 `.codex/` 时仍要核对的列表，也是 `.agents` 仍使用 Codex 措辞时的核对依据。曾有一棵树需要纠正：`.cursor` 继承了 Claude 的 `Bash`。`.kimi-code` 不需纠正——Kimi Code CLI 的文件工具就是 `Read`、`Write`、`Edit`、`Grep`、`Glob` 和 `ReadMediaFile`，终端就是 `Bash`，与 Claude 公布的名称相同——它需要的委派也成立：`Agent` 工具接受 `subagent_type`，内置值为 `coder`（默认）、`explore` 和 `plan`；其问题参数用 `multi_select`，而 Claude 写 `multiSelect`。

**Qwen Code 为每个工具公开两个名称，但 manifest 中只能使用其中一个。**模型调用的标识符是 snake_case：`run_shell_command`、`read_file`、`grep_search`、`edit`、`write_file`、`glob`；界面旁边显示的标签则是 `Shell`、`ReadFile`、`Grep`、`Edit`、`WriteFile`。Qwen Code 自带的 skill 只写标识符；`ReadFile` 和 `Bash` 在其中都出现零次。因此本目录树写标识符，检查 23 会禁止标签，而不是把标签视为第二种正确拼法——manifest 中出现标签表示移植只完成了一半。这不只是编辑问题：提交守卫的 `PreToolUse` 匹配器是 `run_shell_command`；若写成 `Shell`，它会静默地什么也匹配不到。其他机制遵循同一原则——计划模式用 `enter_plan_mode` / `exit_plan_mode`，委派用带 `subagent_type`（`Explore`、`general-purpose`、`fork`）的 `agent` 工具，结构化提问用 `ask_user_question`；它的参数是 `multiSelect`，与 Claude Code 相同，与 Kimi 的 `multi_select` 相反。

Qwen Code 接受四个 STAR 钩子：在 `SessionStart` 上运行模型 ID 来源记录和项目记忆，在 `PreToolUse` 上运行提交守卫和参与程度门。它因此成为继 Claude 和 Codex 后第三个携带参与程度门的宿主，因为其 `PreToolUse` 可以回答 `permissionDecision: "allow"`。注册位于项目自身的 `.qwen/settings.json` 并自动装载，不像 Kimi 那样需要全局安装——但那里的命令钩子 `timeout` 以毫秒计，而其他宿主都以秒计。

`.cursor` 曾经是没有出处可引的目录树，现在不再如此。其说明页面仍描述能力而非标识符——“Read files”“Run shell commands”，以及标题为 [Terminal](https://cursor.com/docs/agent/tools/terminal) 的页面——所以 `Read` 和 `Shell` 最初只是本仓库选用的描述性名称，并非从列表读取的名称。现在有两个配置界面公开这些名称：[hooks](https://cursor.com/docs/hooks) 把 `preToolUse` 的匹配值列为“`Shell`、`Read`、`Write`、`Grep`、`Delete`、`Task`，以及格式为 `MCP:<tool_name>` 的 MCP 工具”；[permissions](https://cursor.com/docs/cli/reference/permissions) 列出 `Shell(...)`、`Read(...)`、`Write(...)`、`WebFetch(...)`、`Mcp(...)`。**原来的猜测恰好与已公开名称完全一致**，因此两者保持不变——如今是因为有引用，不是因为重新猜只会换一种猜法。社区报告的 `read_file` / `run_terminal_cmd` 不属于这两个界面；SDK 自身的小写联合类型（`"read"`、`"shell"`、`"task"` 等）是第三套命名空间，也不是这些文件使用的命名空间。那里公开的是 [Subagents](https://cursor.com/docs/subagents) 中的 `Task` 工具；`subagent_type` 没有公开，仅出现在社区 bug 报告中。注意词义所在：在 Cursor 的词汇中，`Bash` 是一个子代理名称，不是终端名称。

Cursor 公开三个内置子代理：`explore`、`bash` 和 `browser`，所以这棵树只能点名 `explore`，实际也只点名了它。十处文件写入派发曾使用当前文档没有列出的 `generalPurpose`；三个内置代理都不是它所代表的写入迁移器，因此这些位置如今完全不设类型，并说明允许写什么——派发简报本来已经给出这项信息。另一种方案是点名自定义子代理：Cursor 从 `.cursor/agents/*.md` 装载它们，也为兼容读取 `.claude/agents/` 和 `.codex/agents/`，名称冲突时 `.cursor/` 获胜。frontmatter 中的 `name` 是 `Task` 工具提示使用的标识符，`readonly: true` 会禁止文件编辑和改变状态的 shell 命令。这会让只读规则成为机制而非指令，但代价是要在六棵目录树维护一个产物，并增加 Cursor 也会读取的 `.claude/agents/` 目录。该方案保留为可能性，但目前不用。

`.agents` 按委派者所做之事命名，因为这棵树不能点名调用：收集用**只读子代理**，实现用**写入子代理**。是否派发的判断在各处相同——规约 §6.1 的“有界、独立、实质有益”测试——因此共享根目录说明测试条件，具体调用留给读取它的宿主。Codex 自己通过 `spawn_agent` 调用，并用 `agent_type: explorer` 或 `worker`；内置 `default` 类型在这里无用，因为 STAR 的委派总属于上述两类角色之一。

**术语出现在错误的目录树中才是真缺陷。**两个真实案例：25 个 `.cursor` 资源模板曾告诉用户“Claude Code 在会话开始时注入它”（`e149ae0`）；`.kimi-code` 在 36 处把 `CLAUDE.md` 写成项目规则文档，而其他目录树写 `AGENTS.md`（`6f37f77`）。

**移植最容易漏掉的名称，恰恰是审阅者不会多看一眼的名称。**`Bash` 和 `Read` 在 `.cursor`、`.kimi-code`、`.agents` 存在期间长期原样沿用，因为像普通英文词的工具名不像 Claude 词汇——而 `AskUserQuestion` 明显得多。在 `.cursor` 和 `.agents` 中，它们确实是看起来那样的缺陷。`.agents` 还点名过 `ask_user_question`，比未适配的名称更糟：它具有宿主形态、全小写且看似合理，仿佛有人核对过。实际并没有——Codex 称它为 `request_user_input`，这也是该目录树按 Codex 编写时一直使用的名称。移植目录树时，应逐个依据该宿主公开的工具列表检查工具名，而不是依据名称有多熟悉或多可信。`.agents` 没有可核对的列表，因为那里根本不应出现任何工具名。

**因怀疑而未经核对地改名，是同一缺陷的反面。**`.kimi-code` 原本使用 `Bash` 和 `Read`，因为 Kimi Code CLI 就这样称呼它们。v0.1.8 把它们误判为未适配的 Claude 词汇，在 30 个文件中改成 Kimi 从未拥有的 `Shell` 和 `ReadFile`；随后又在本文和变更日志中声称新名称已对照 Kimi 自身列表核查，因此连续十一版都无人质疑。v0.1.17 起，矛盾已经清晰可见：`.kimi-code/hooks.example.toml` 把提交守卫注册为 `PreToolUse` 匹配 `Bash`，而旁边每个 manifest 都已停止使用这个名称；没有人把两者放在一起读。改名和继承名称承担同样的证明责任：引用宿主公开列表；如果名称只能靠引用确认，就把它固定下来。检查 23 如今固定六棵树的文件读取器、终端和 `subagent_type` 值，两个方向都不再依赖记忆。

**宿主后来新增的能力，是随时间老化的同类缺陷。**宿主缺少某种机制时移植的目录树，会在该机制出现后长期保留替代方案，而任何检查都看不出来——措辞内部一致，变化发生在平台。`.cursor` 曾在 `.claude` 的 132 个 `AskUserQuestion` 位置全部保留纯文本替代，并在 4 个文件中直言“Cursor 没有结构化提问工具”，但这已不再属实。移植后备方案时，要说明它替代的是哪项能力，让后来者知道需要重新检查什么。

其他一切——规则、阈值、步骤语义、各自可写范围、量规——绝不能不同。

## `.pi` 是自行提供机制的目录树

Pi 的内置工具是 `read`、`bash`、`edit`、`write`、`grep`、`find`、`ls`——全小写，本目录树也这样书写。更重要的是它自己的文档明确说明**有意不提供**什么：子代理、计划模式、权限弹窗、MCP、待办事项、后台 bash。其中三项是其他五棵目录树依赖的机制。`.pi` 没有用文字替代，而是从 **Pi 自己的 `examples/extensions`**（MIT）引入并放在 `.pi/extensions/` 下：

| 机制 | 其他目录树 | `.pi` |
|---|---|---|
| 结构化提问 | `AskUserQuestion` / `AskQuestion` / `request_user_input` / `ask_user_question` | `star_questionnaire`——每次调用一个问题，2–4 个选项并标记推荐项。无界面运行时返回 `UI not available`，这表示停止，而不是改用纯文本继续提问。 |
| 计划审批 | `EnterPlanMode` / `ExitPlanMode` / `SwitchMode` / `update_plan` | `/star-plan` 存在，但它是**用户**的开关：扩展只注册命令和标志，不注册工具。因此执行器的步骤 3 仍是它自行约束的模式——明确说出步骤 4 获批前不写入也不运行，并据此自我约束。 |
| 委派 | `Agent` / `Task` / `spawn_agent` / `agent` | `star_subagent`，派发到 `.pi/agents/` 名册：`star-collector`（只读，§6.4）、`star-implementer`（按简报执行一个步骤，§6.5）、`star-auditor`（盲审式二次阅读，§6.7）。其范围参数默认是 `project`，因此能访问该名册；上游默认访问用户自己的名册。 |

**两种分隔符不是疏忽。**`star_subagent` 和 `star_questionnaire` 是工具名；七棵目录树中的多词工具名一律使用 snake_case 或 camelCase——如 `ask_user_question`、`spawn_agent`、`update_plan`、`AskUserQuestion`——Pi 自己示例中的多词工具也一样（`structured_output`、`reload_runtime`、`tool_search`）。`star-collector`、`/star-plan` 和 `star-code-architect` 是人会输入或文件会使用的名称，始终用 kebab-case。强行统一会让一边成为仓库中唯一的例外。

编辑前应了解五个后果：

- **全部能力都受项目信任控制。**项目未受信任时 `.pi/extensions/` 不装载，这些工具都不存在。点名其中一个工具的 skill 会退回到 STAR 在宿主缺少它时的做法——规约 §6.1 的本地补位，以及问题的纯文本形式。该后备方案只在 `.pi/APPEND_SYSTEM.md` 说明一次，不在每个点名工具的 skill 中重复。
- **所有引入的名称都带前缀，这不是装饰。**两个扩展若声明同名工具、标志或命令，Pi 会**拒绝启动**——`exit 1`，根本没有会话。这些示例也常被安装在用户级目录，因此仓库中没有前缀的副本会让所有已安装同类示例的用户无法启动 Pi。前缀还覆盖状态与 widget 槽、会话条目和注入的上下文标记：没有前缀的标记会让用户级副本静默过滤本副本的消息。`.pi/settings.json` 无法消除冲突——其 `extensions` 数组只能添加路径。
- **参与程度门仍然不存在。**该钩子用于在编辑文件前回答权限提示。引入的确认只覆盖 `rm -rf`、`sudo` 和 `chmod 777`——危险 bash，不是编辑——所以仍没有可回答的提示。`.pi/extensions/star-hooks/` 只有三个脚本而非四个，`execs/update.sh` 的 `missing_hooks()` 也没有 Pi 行。
- **注册逻辑就是代码，脚本与它放在一起。**`.pi/extensions/star-hooks/index.ts` 扮演其他地方 `.claude/settings.json` 的角色；项目受信任后 Pi 会自行发现它。它属于 `HOOK_FILES` 而非 `HOOK_CONFIGS`：不承载项目设置，因此更新时会替换而不是保留。提交守卫是形态真正不同的唯一钩子——在 stdout 打印原因并以非零状态拒绝，扩展再把两者转换为 Pi 的 `{ block: true, reason }`。
- **Pi 也会发现 `.agents/skills/`**，名称冲突时保留先找到的副本。`.pi/APPEND_SYSTEM.md` 会纠正这一点——它是 Pi 的常开通道，作用与 Cursor 的 `.cursor/rules/skill-roots.mdc` 相同。只运行 Pi 的项目可以删除 `.agents/`。

Pi 自带一个子代理*示例*扩展（`examples/extensions/subagent/`）和一个计划模式示例。两者都不是内置能力，STAR 也不安装它们；即使项目自行添加，`.pi` 目录树仍能正确解读，因为 §6.1 的本地补位是最低保障，而不是禁令。

## `.agents` 是明确声明的变体

`.agents` 是真正的适配，不是副本：其执行器有 7 个步骤，其他目录树有 9 个。它在 8 个文件中的标题结构与 `.claude` 不同——`star-plan-executor` 下四个（manifest 与 `agent_dispatch_spec.md`，各有中英文），`star-code-architect` 下四个（`orchestration_spec.md` 和 `survey_spec.md`，同样各有中英文）——而这些差异并非简单遗漏，而是结构重组。`stop_line_rules.md` 曾是第九和第十个，直到该目录树停止点名宿主：原标题是“**Codex** 运行什么”，现在改为“代理运行什么”，与 `.claude` 相同，因此两个文件的标题逐项一致。

所以它**不参与结构检查**，该豁免是一个已知漏洞，见下文。

## Skill frontmatter 不随正文移植

`.claude/skills/*/SKILL.md` 带有 `argument-hint` 和 `allowed-tools`。**其他五棵目录树中只有 `.qwen` 携带 `argument-hint`；没有任何一棵携带 `allowed-tools`，也不应携带。**每个键都按所属宿主自身界面检查，而不是看它在那里似乎是否合理——与上文工具名采用相同纪律。

| 目录树 | `argument-hint` | `allowed-tools` | 工具预审批实际所在位置 |
|---|---|---|---|
| `.claude` | 支持 | 支持 | skill 内，只覆盖调用它的当前回合 |
| `.cursor` | 不是字段 | 不是字段 | `.cursor/cli.json` 的 `permissions.allow`，整个会话 |
| `.kimi-code` | 不是字段 | 不是字段 | `~/.kimi-code/config.toml` 的 `[[permission.rules]]`，用户级 |
| `.qwen` | 支持且已携带 | 读取为 `allowedTools`，有意不移植 | `.qwen/settings.json` 的 `permissions.allow`，项目级 |
| `.agents` | 仅出现在编写说明中 | 仅出现在编写说明中 | 没有逐 skill 位置——有意移除 |
| `.pi` | 不是 skill 字段（是提示模板字段） | 可读取，实验性，有意不移植 | 没有——Pi 无权限系统；引入的确认只覆盖三种 bash 模式，不覆盖编辑 |

**Cursor 的 frontmatter 表只允许五个键**——`name`、`description`、`paths`、`disable-model-invocation`、`metadata`（另有旧的 `globs`，以及只在 [CLI 变更日志](https://cursor.com/docs/cli/changelog)记录的 `user-invocable`）。[skill 参考](https://cursor.com/docs/skills)中完全没有上述两个键。其权限 token 又是另一套词汇——[`permissions`](https://cursor.com/docs/cli/reference/permissions) 中的 `Shell(...)`、`Read(...)`、`Write(...)`、`WebFetch(...)`、`Mcp(...)`——所以即便上游规范示例 `allowed-tools: Bash(git:*)` 也点名了 Cursor 不具备的工具。

**Kimi 会保留并忽略未知键**，所以移植过来的 `allowed-tools:` 块不会报错，而是静默无效——这是最糟的故障模式。其解析器在发送正文前去掉 frontmatter（`parser.ts`），因此运行时不读取的键也不会到达模型。它自己的 `arguments` 字段不是提示：它为正文中的 `$NAME` 占位符声明位置替换，不会出现在 `/` 菜单项中（`tui/commands/skills.ts` 只发送 `name`、`aliases`、`description`），而我们的正文没有占位符，因此毫无收益。正文已有的 `Invocation:` 行才真正到达模型。

**Codex 有意移除了逐 skill 权限。**其逐 skill manifest——承载显示名、默认提示以及使 skill 仅限斜杠调用的 `allow_implicit_invocation` 标志——在 2026 年初约六周内接受过 `permissions:` 块（`5b6911cb`），随后又移除（`0bb152b0`、`b3e069e8`）；回归测试 `shell_zsh_fork_skill_scripts_ignore_declared_permissions` 如今明确断言已声明的 skill 权限“不应把脚本执行范围扩到当前回合沙箱之外”。两个键在发布二进制中仅残留于内置 skill-creator 的编写指南——`argument-hint` 一处，`allowed-tools` 两处，运行时路径中一处也没有。更糟的是 Codex 市场验证器把允许属性固定为 `{"name", "description", "license", "allowed-tools", "metadata"}`，其他属性会以“Unexpected key(s) in SKILL.md frontmatter”拒绝，因此在那里加入 `argument-hint` 既不会在运行时生效，又会导致发布验证失败。

**该 manifest 只属于 Codex，所以保存在 `.codex/` 下。**十五个文件位于 `.codex/skills/<skill>/agents/openai.yaml`，而 `.agents/skills/<skill>/agents/openai.yaml` 是指向它们的相对符号链接。链接不能省：Codex 只从某个 skill 自身目录内部读取 manifest，而 `.agents/skills` 是它扫描的唯一项目根目录，所以不存在可把文件移去的 `.codex/skills` 发现机制。检查也围绕这种拆分编写：检查 4 从 `.codex/skills/` 读取十五个 manifest，检查 3 和 7 则排除 `agents/`——既不把它计入清单基线，也不扫描 token，因为 `default_prompt` 本来就有意使用 Codex 自己的 `$star-*` 语法。`--harnesses codex` 会同时选择 `.agents` 和 `.codex`，而 `execs/update.sh` 复制链接所指向的内容，所以安装后的项目得到真实文件，不会留下指向未安装目录的链接。

**Qwen Code 同时读取两个键，但只移植其中一个。**其 skill frontmatter 接受 `name`、`description`、`argument-hint`、`when_to_use`、`priority`、`paths`、`user-invocable`、`disable-model-invocation`、`allowedTools`、`model`、`hooks` 和 `key`；本目录树只携带四个——`name`、`description`、`argument-hint`、`disable-model-invocation`。`allowedTools`（camelCase，不同于 Claude 的 `allowed-tools`）被有意省略，因为它语义相反：它是叠加式、会话范围的自动审批授权，从不缩小模型可见工具。把 Claude 的块带过来会在原本用于限制能力的位置授予自动审批。本目录树的预审批改放在项目级 `.qwen/settings.json` 的 `permissions.allow` 中，与六条 `scan.sh` 命令一起发布。

**其他五棵目录树中，skill 所需的任何预审批都属于项目级或用户级配置修改，而非 skill 修改**——且范围总比仅持续一个回合的 Claude 版本更宽。不要在未说明的情况下把回合级授权移植成常开配置。

若要在不猜测的情况下重新核对：`codex debug prompt-input` 会把 Codex 对模型可见的输入渲染为 JSON，下文的截断测量也采用该方式。

## Description 长度限制

**六棵目录树中，`SKILL.md` frontmatter 的 description 都以 1024 个字符为上限。**这不是逐宿主预算：[agentskills.io `SKILL.md` 规范](https://agentskills.io/specification)、Anthropic Agent Skills 文档和 Kimi CLI 文档都规定 `description` 长度为 1–1024。只限制 `SKILL.md`——它是平台注册并显示 description 的 manifest；`SKILL_zh.md` 作为资源装载，可以超过 1300 个字符。

本文曾长期把它记作仅适用于 `.kimi-code` 的 1050 **字节**预算，因为只有那棵树被人压缩过，数值也是从现有数据（最大 1041）逆向猜出的，不是从规范读取。这个猜测足够接近，以至于掩盖了检查 12 后来修复的两个度量错误：awk 的 `length()` 计算字节，而 description 含 `§`、`—` 和 `→`，所以字节数可比字符数多 8；`description: >-` 还把折叠块标志 `>-` 留在被测文本中，令每个折叠文件虚增 3。`1024 + 3 + 多字节余量 ≈ 1047`，正是 1050 长期通过的原因。

**宿主可能远早于规范上限就截断，而仓库无法检测。**在三个 `.agents` description 仍长达 2108、1665 和 1559 字符时，Cursor 都在第 1536 个字符处从词中间截断（`star-metd-summarize`、`star-refs-reviewer`、`star-expt-analyst`；如今三者都在上限内），所以长 description 的尾部会静默地无法进入代理用于匹配的列表。两个数字都重要：1024 是规范许可值，约 1500 是 description 在实践中开始丢失结尾的位置。

**Codex 的截断比两个数字都严格得多，而且可以度量。**`codex debug prompt-input` 会显示模型可见输入；每个 skill——包括 Codex 自带 skill——在那里都只有一行 `name: <description 前约 100 个字符> (file: <path>)`，从词中间截断且没有省略号。十五个 `.agents` description 长 504–947 字符，因此**模型只能看到约 10%，而十五个中没有任何一个能让“Use when the user invokes `star-*`, or wants …”触发子句到达模型。**该子句是 description 获得主动调用的全部机制，对 Codex 而言却是死文本。skill 被调用后仍会装载完整 `SKILL.md`，所以损失的是发现而非执行——但发现正是 description 的用途。

**十五个 `.agents` description 如今针对该窗口编写**：每个都以用户语言写成的触发子句开头，并在前约 90 个字符内结束，机制、路由和保证随后再写。应按发现问题的原方法复查——运行 `codex debug prompt-input` 并阅读 `- <name>: …` 行——因为**这里没有任何检查能看到它**。编辑时遵循两条规则：窗口从 description 的*开头*计量，所以在前面添加任何内容都会把触发信息推出窗口；为了腾出空间，仍不能删掉关于 skill 不会做什么的保证（见上文），只能把它后移。这是唯一一棵让 description 顺序承载功能而非风格的目录树。中文对照版有意不改：`SKILL_zh.md` 不是已注册 manifest，Codex 从不装载它，因此无需针对截断窗口编写。

压缩会静默丢失内容，这才是真实成本。英文 description 中曾丢掉两处子句，后来恢复：`star-code-release` 的“准备发布但绝不发布”，以及 `star-expt-analyst` 的只读保证和 `watch` 模式。两者本可容纳在上限内——对应 description 当时分别为 890 和 593 个字符——所以删除没有换来任何收益。中文 description 一直保留这些子句，才使英文缺口显现。**为满足长度限制而缩短 description 时：删细节，绝不能删关于 skill 不会做什么的保证。**检查 12 约束长度，没有检查能替你做这项判断。

## 检查能够捕捉什么

`.github/workflows/consistency.yml` 会在 push 和 PR 时运行 `.github/scripts/check_consistency.sh`：

1. 六个根目录拥有相同的 skill 目录集合。
2. Frontmatter 的 `name:` 与目录名一致。
3. 各目录树中逐 skill 文件清单一致（`.agents` 下指向 Codex manifest 的 `agents/` 链接除外）。
4. 六棵树中的仅限斜杠调用守卫与规约 §10 名册双向一致；共享的 `.agents/commands/star.md` 路由和两份中文版本都列出完全相同的 skill 与 † 集合。
5. 每个 `.md` 都有对应的 `_zh.md` 文件。
6. 每个 `SKILL.md` 都引用规约文档。
7. 调用 token 适合所在目录树——`.agents` 完全没有前缀；`.claude`、`.cursor`、`.pi`、`.qwen` 使用 `/star-*`；`.dsh` 和 `.kimi-code` 使用 `/skill:star-*`；每个宿主的 `/star` 入口都保持为 `.agents/commands/star.md` 的薄包装。
8. 工作流文档以中英文对照形式发布。
9. `.cursor/rules/agent-instructions.mdc` 与 `AGENTS.md` 正文逐字节一致。
10. 两类会话钩子——模型 ID 来源记录与项目记忆——在六种宿主中均存在、可执行且已在各自注册文件中登记。
11. **`.claude`、`.cursor`、`.kimi-code`、`.pi`、`.qwen` 的标题结构一致**——每棵树 1236 个标题；比较前去掉英文和中文圆括号中的内容（`(...)` 与 `（...）`）以及行内代码，因此标题中的宿主词汇可以不同。目前完全一致，没有例外列表。
12. **每棵树的 `SKILL.md` description 都不超过规范的 1024 字符**——按字符计数并排除折叠块标志。见上文；宿主早于规范值截断的情况无法在这里检查。
13. **六棵树的 skill 辅助脚本逐字节一致且可执行。**脚本不点名宿主，因此无需适配；副本漂移属于 bug，不是变体。
14. **`.agents` manifest 与 `.claude` 拥有相同的 `##` 节集合**——比较集合而非顺序，因为检查 11 豁免 `.agents`，而内容曾经通过该漏洞丢失。
15. **共享脚本能通过语法解析，且其逐字节匹配的字符串仍有生产者。**检查 13 只比较六个副本，因此同时把同一个错误带入六棵树——这正是常见编辑方式——仍会通过。此检查对每个副本运行 `bash -n`，并维护扫描器匹配字符串与必须写出这些字符串的模板之间的登记表。`【待定】` 正是该检查存在的原因：`star-plan-decomposer` 曾把它写入每个中文子计划，而 `scan.sh` 只计数 `[TBD]`，导致“太粗，无法执行”的规则从 `ab4246c` 到 `9c25079` 在中文项目中静默失效，CI 始终为绿。
16. **`AGENTS.md` 章节编号引用仍指向其声称的章节。**16a 固定标题映射，因此章节重新编号或改名会在其他地方察觉前先让此处失败。16b 重新检查带标签的引用——如 `§8 layout`、`布局符合度（§8）`——是否仍符合实时映射。它防范的漂移曾发布两次：布局与运行时移到 §8 和 §9 后，`star-code-reviewer` 与 `star-expt-analyst` 仍引用 §5 和 §6，CI 仍为绿，因为此前从未有检查查看引用。
17. **规约文档的编号结构被固定，中英文工作流文档保持逐行对齐。**Skill 会引用到该文件的子节级别——§7.7 出现 280 次，§6.3 出现 50 次——所以在章节中间插入一项会让之后每个引用重新指向其他内容。标题被固定；有被引用项目的章节（§1、§3、§4、§5、§6、§7）项目数被固定，且两种语言都计数，因为同一个 §n 在不同语言中含义不同也是同一个 bug。逐行对齐规则也通过行数相等强制执行。
18. **Skill 指南和两个 README 与其描述的 skill 保持连接。**指南约 69% 的内容改述十五个 `SKILL.md`，后者权威且变化更频繁。该检查在四个文档间约束脚本可见的连接：每个相对链接目标都存在（包括指南逐节的“完整定义”链接）；每个 `conventions §n.m` 引用都落到现存章节和项目；每个页内锚点仍匹配一个标题。Skill 覆盖有两种形态——指南必须且只能为每个 skill 提供一个编号章节，README 只需点名每个 skill，因为那里使用表格行。没有检查判断章节*说了什么*。
19. **每棵树的开场装载形态保持不变。**每个文件只有一行 `.env` 查询；Bash 块中不允许 `cat` 整份规约（只有 `.agents` 标记为“accept that the result is written out”/“接受结果被存成文件”的后备句可例外）；运行时从不装载 `SKILL_zh.md`；全部九十对文件中有意统一的两段——语言段落与 `SKILL_zh.md` 开头的引用块——仍完全相同，因此部分重改会显现。检查固定查询行和这两个开头的原文；集中重写时必须在同一提交更新检查。
20. **只装载部分规约的 skill 会准确说明范围，并保持在大小上限内。**两个 skill（`star-expt-digest`、`star-refs-reviewer`）用 `awk` 截取实际操作的章节，而不是读取整个文件。对每个文件，检查确保：截取结果恰好包含正则点名的章节，因此上游重编号会失败；读取本语言的规约文件；大小不超过 `LOAD_EXCERPT_MAX`（28000 字节），这是唯一可发现超限的位置，因为 `execs/update.sh` 会把整份规约复制到下游项目，文件只能在这里增长；正文装载列表等于正则集合，不装载列表等于其补集；正文引用的大小与选择器产出相同。若 skill 引用不再装载的章节，必须在 `RESTATED_REGISTRY` 中登记，并按目录树和语言双向检查，因此未登记引用和孤立登记都会失败。固定字符串包括选择器形态，以及正文中分隔两份列表的短语（“stay out”“不装载”）。有意保留的缺口：`star-flow-status` 也只装载部分规约，但它使用 `sed` 范围并对 §7 做项目级筛选，章节级解析器无法验证。
21. **每个 manifest 的开场装载块内都带有复用早前装载的段落，且每种语言内部统一。**这段话允许同一对话中的第二个 skill 跳过仍能逐字看到的装载内容，让多 skill 会话只支付一次装载成本，而不是 N 次。上文检查无法发现三种丢失方式：从一棵树删除，因为检查 1–3 只比较文件集合不比较内容；只在一棵树重写，导致六棵树对可跳过内容意见不一；移到第一个 `##` 标题之后，使它不再属于读者做装载决定时看到的开场块。该段也不能含裸 `§n`——检查 20d 会把同一块中的每个 `§n` 当成 skill 装载哪些章节的声明。
22. **委派调用保持宿主原生，共享根目录不点名任何调用。**`.agents` 完全不得包含委派工具或类型键——`spawn_agent`、`star_subagent`、`Agent`、`Task`、`agent_type:`、`subagent_type:`——因为那里按委派者所做的工作命名。反方向上，Codex 的 `spawn_agent` 和 `agent_type:` 不得出现在 `.claude`、`.cursor`、`.kimi-code` 或 `.qwen` 中。
23. **每棵树只点名本宿主的文件读取器、终端、提问工具和子代理类型，`.agents` 则一个也不点名。**Pi 的名称为小写（`read`、`bash`），且不得出现任何 `subagent_type`。Claude Code 与 Kimi Code 公开 `Read` 和 `Bash`；Cursor 的终端是 `Shell`；Qwen Code 使用 snake_case 标识符 `read_file` 和 `run_shell_command`，其显示标签 `ReadFile` 与 `Shell` 同 Claude 名称一起被禁止。共享根目录的禁用列表是上述列表的并集：包含每种宿主的文件读取器、终端、提问工具和计划工具，也包括 Codex 自身。`subagent_type` 值按目录树固定——Claude 为 `Explore` / `general-purpose`，Cursor 只有 `explore`，Kimi 为 `explore` / `coder`，Qwen Code 为 `Explore` / `general-purpose` / `fork`；`.agents` 不得点名任何类型键，这部分由检查 22 负责。该检查存在是因为未适配名称的反向错误真的发布过：`.kimi-code` 从正确的 `Read` 和 `Bash` 改到 Kimi 从未有过的名称，而所有检查都通过。`.cursor` 的两个名称最初只是本仓库的描述性选择，如今已有出处——Cursor 的 hooks 和 CLI 权限页面公开 `Shell` 与 `Read`——因此六棵树都固定在供应商列表上，而不是猜测上。

## 检查捕捉不到什么

请诚实面对这份列表；真正的漂移就发生在这里。

- **正文语义。**没有检查比较章节正文。把一条规则从“绝不发布”改成“可以发布”仍会通过所有检查。
- **`.agents` 结构**，因为上文的豁免。这里曾丢失过内容：15 个 `SKILL.md` 中有 7 个缺少 `## Dialogue Discipline`，同时丢掉 `star-refs-reviewer` 的诚实规则和执行器的非交互后备方案（已在 `042ece5` 恢复）。当时没有检查能发现，下一次仍然没有。
- **中英文含义漂移。**检查 5 能证明对照文件存在，却无法证明含义相同。检查 11 如今能证明两者章节结构相同，但这只是底线，不是保证。
- **`docs/htmls/`。**落地页未与 README 或工作流指南比较，并且曾与两者都发生漂移。
- **缩短后的 description 是否仍保留重要内容。**检查 12 强制长度上限，却无法判断为达标而删掉的内容是否可有可无——见 description 长度一节。宿主对上限内 description 的截断同样无法发现。
- **Skill 指南是否仍正确描述 skill。**检查 18 证明每个 skill 有对应章节且链接可解析。如果重写 skill 工作流而让指南的“做什么”列表继续描述旧版本，所有检查仍为绿。
- **裸 `§n` 引用。**大多数 `AGENTS.md` 引用都是裸引用——`(AGENTS.md §3)` 没说明 §3 的内容，因此检查 16b 无法验证。只有 16a 兜底：它让重编号变得显眼，却不能证明引用正确。
- **没人登记的新 grep 字符串。**检查 15 依赖手写登记表：如果给扫描器新增逐字节匹配却不加登记行，下一位重写生产者的人会再次静默破坏它。教脚本匹配新字符串时，要在同一提交中登记。
- **固定的工具名是否仍属于该宿主。**检查 23 根据本文表格固定六棵树的工具词汇，而表格的可靠性取决于背后的列表。六棵树如今都能追溯到供应商公开列表，但检查只能证明某名称自上次查看后没有漂移，不能证明当时查看就正确——`generalPurpose` 在 Cursor 内置子代理变化后仍留在那棵树中；若早一天写检查，只会把错误固定住。Cursor 案例也有正面变化：其标识符从未公开变为已公开，这里同样不会自动发现，因此复查既可能失去引用，也可能新增引用。

## 提交前

- 运行 `bash .github/scripts/check_consistency.sh`。失败时返回非零状态，运行很快。
- 修改 `AGENTS.md` 时必须在同一提交修改 `.cursor/rules/agent-instructions.mdc`——检查 9 直接比较两者正文。
- 修改规约文档的编号章节时不要重编号。仅 §7.7 在仓库中就有 305 处引用。检查 17 固定章节标题和项目数；向 §1、§3、§4、§5、§6 或 §7 添加项目会使检查失败，直到重新审计每个 `§n.m` 引用。
- `AGENTS.md` 同理：章节重编号意味着重新审计 skill 目录树中的每个 `§n` 引用，并更新检查脚本中的 `AGENTS_SECTIONS`。两项都完成前检查 16 会失败。
- 保持中英文工作流指南逐行对齐。它们当前每行都对应，使跨语言 diff 可读；一旦失去对齐，检查 17 会失败。
