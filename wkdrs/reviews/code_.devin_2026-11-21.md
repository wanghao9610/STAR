# 代码审查 — Devin 适配（2026-11-21）

<!-- mode: path
     target: .devin/
     model_id: unrecorded
     review_gate: blocked
     files_reviewed: 34
-->

## 1. 范围与证据

- `main`，HEAD `1f533f94`，包含工作区已有的 Antigravity 改动（涉及共用的更新脚本、JSON 辅助脚本、检查脚本和文档）。`.devin/` 无本地改动。本次未改源文件或配置。
- 范围为 `.devin/` 的 20 个文件，另读 14 个直接相关文件：`AGENTS.md`、`.env.example`、双语 README、工作流规约、两个共享命令 `.agents/commands/{star,star-auto}.md`、`.agents/scripts/json.sh`、审查有效性辅助脚本 `review_state.sh`、`execs/{update,configure}.sh`、`check_consistency.sh`、`check_model_routing.sh` 和 `test_hook_shell.sh`。共用文件按 Devin 入口、权限、派发和分发契约审查；不是整个仓库审查。无 `metds/codearc.md`，无所属研究计划。工作区无 `.env`；未运行 Python，审查未使用 Python。
- 一次独立只读检查覆盖以上 34 项，主审核对问题和 Devin CLI `3000.14.30821 (a09cd7f323ee)` 的本机文档。双语 README 和工作流规约仅审与 Devin 有关的段落。当前会话实际收到模型溯源和项目记忆的两条会话启动上下文；模型 ID 未提供。
- `devin skills list` 返回 8 个共享技能和 9 个仅用户调用的入口（两个路由入口、七个受限技能），未显示来自其他宿主的重复 STAR 技能。`devin doctor` 识别 `star-plan`、`star-exec`、`star-read`，3 项诊断通过、无警告；它不验证实际分配的模型。
- `bash -n` 检查 5 个 Devin 钩子及两个发布脚本，退出 0；Node `JSON.parse` 检查 `.devin/config.json` 和 `.devin/hooks.v1.json`，退出 0。`bash .github/scripts/check_consistency.sh`、`bash .github/scripts/tests/test_hook_shell.sh`（374 个用例、796 条断言）、`bash .github/scripts/check_model_routing.sh` 均退出 0。路由测试证明写入描述文件的值，不证明实际派发用到该值。
- `1f533f94` 记录同版本 CLI 的既往实测：编辑钩子可以回答权限确认，提交守卫的拦截优先于 shell 钩子的放行，关闭 Claude 配置导入也关闭其钩子。本次未重跑这组模型会话，也未把该结果当作 `/star-auto` 的端到端证据。

## 2. 结论

基础接入可用：CLI 发现命令、规则和三种具名派发描述，会话钩子生效，仓库检查通过。不算适配完备：旧下游配置的更新提示、权限级别解析和模型派发仍有缺口。0 个 blocker、4 个 major、2 个 minor。未涉及具体研究运行，不写 `REVIEW_STATE.md`。

## 3. 问题

### Major

- **F1** `execs/update.sh:295–331,1139–1157` — 下游正常更新会保留旧 `hooks.v1.json`，且可能不提醒。`633af051` 发布的 Devin 注册已有这些脚本文件名，但匹配器比当前版范围宽，提交守卫超时仍为 10 秒。`missing_hooks` 仅搜索部分文件名：它既不比较事件、匹配器与超时，也没检查 `star_bash_gate.sh` 的缺失。结果是脚本更新了，已有项目却可能继续用较宽的许可匹配范围，或没有 shell 自动放行。保留用户配置的承诺不变；按 JSON 结构核对 STAR 注册项并提示精确的手动合并项。依据：检查保留配置并提示接线缺失的更新契约，以及已收紧的 `.devin/hooks.v1.json:2–26`。
- **F2** `.devin/hooks/star_bash_gate.sh:42–46`、`.devin/hooks/star_involve_gate.sh:28–32` — 两个钩子用 `tr -cd '[:alpha:]'` 解析 `.env`，导致 `INVOLVE=low1` 这类非法值被解释为 `low`。这违反只在明确设置 `low` 时自动批准的约定。按 `.env` 支持的引号、空白和注释形式解析，然后精确比较；非法值不批准。待补正常值和误拼值的回归用例。依据：工作流规约 §7.7（参与级别）及钩子自身声明的默认行为。
- **F3** `.devin/rules/skill-roots.md:17–19`、`.devin/skills/star-auto/SKILL.md:16–18` — 本地只读收集和盲审使用 `subagent_explore`，但 Devin 的这个内建角色使用其默认子代理模型，不会读取 STAR 的描述文件。因而配置的 `STAR_READ_MODEL` 和盲审的 `STAR_PLAN_MODEL` 在这两类任务上不能兑现。继续保持只读约束；为本地只读任务提供受工具限制、可指定模型的角色，或明确声明采用宿主默认模型并把降级记入记录。依据：工作流规约 §10.8（按任务选档）；本机 `subagents.mdx:46–83,117–135`。
- **F4** `.devin/skills/star-auto/SKILL.md:16`、`execs/configure.sh:295–297,387–405` — `/star-auto` 依据当前 `.env` 选描述文件，却默认静态 `model:` 已同步。用户改 `.env` 而未运行 `configure.sh` 时，路径和角色名仍然有效，但可能继续使用旧模型；同步后未重载会话也不能据磁盘内容断言路由已更新。派发前检查描述文件存在且值与期望一致；不一致时提示离线同步并重开会话，无法确认已加载就标明降级，不把所请求模型当成实测模型。依据：工作流规约 §10.8（可用路由和模型记录）及 §13（Devin 静态角色）。

### Minor

- **F5** `.devin/hooks/star_commit_guard.sh:275–301` — 提交参数解析遇到消息选项便停止，合法的选项与路径排序可能让后置路径未进入 10 MB 检查；仅检查暂存区不能代替检查 Git 在显式路径提交时要记录的工作区内容。当前脚本已声明它不是完整的 shell 解析器，因此不将其当成宿主隔离边界；仍应覆盖正常的选项排序，遇到无法判定的命令不宣称已检查。依据：工作流规约 §1（Git 守卫检查显式提交路径）。未执行提交。
- **F6** `.github/scripts/check_model_routing.sh:584–655` — 模型写入测试覆盖 Devin，但下游安装集成用例在此处安装和验证的是 Cursor；一致性检查对 Devin 的安装与规则更多依靠文本断言。补一个离线 `--adopt --harnesses devin` 到更新的用例，验证全部 5 个钩子、9 个入口、3 个代理描述，验证已有旧版注册时给出提醒且不覆盖。依据：`AGENTS.md` §4（用行为证据验证共享接口）。

### 尚未证实

- 三个描述文件的 `model: inherit` 能通过 `devin doctor` 的加载检查，但本机文档没有说明该字面值运行时的实际语义；不得据此推断继承主会话的模型。没有实际运行一次 `/star-auto` 的代理派发、返回问题和恢复路径，也未验证带深度模型 ID 的实际选择。
- `apply_patch` 保持 Devin 的正常权限确认，`involve=low` 调用参数不改变只读 `.env` 的权限钩子；这是当前明确记录的宿主差异，不计为缺陷。会话和派发若没有可信的运行时模型 ID，记录 `unrecorded`，不从配置推测。

## 4. 计划符合度

非计划范围的审查。

## 5. 下一步

先处理 F1、F2（旧配置和权限级别），再处理 F3、F4（模型派发与同步），用一次 Devin 专用安装回归和一次只读目标的实际派发补齐证据。

## 6. 修复记录

未运行修复轮，未提交。
