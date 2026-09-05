---
name: star-code-architect
description: >-
  为研究计划搭建或整理项目代码库（${CODE_NAME}/，从 .env 读取）。当 ${CODE_NAME}/ 缺失或为空时：
  从 metds/plans/ 下的研究计划提炼检索要素，在 GitHub 上检索候选参考实现并按评分表打分（计划贴合度、
  完整性、许可证、活跃度），由用户选定后克隆、去除 git 历史、记录出处，并保守地重命名为 CODE_NAME。
  当代码已存在时：改为用只读 Task subagent 勘察代码。两条路径随后汇合：设计目标架构与迁移表，仅执行
  用户批准的迁移项（Task subagent 编排 + 逐组验证 + 每组提交一次），并把架构规范写入
  metds/codearc.md，在 AGENTS.md 与 .cursor/rules/ 留下一小段指路说明。当用户运行
  star-code-architect，或想为计划找参考实现或起步代码库、想搭建 ${CODE_NAME}/、或想整理/重构现有
  代码库并写下架构规范时，都应使用本 skill。Bilingual (中/英) — also trigger in English whenever
  the user wants a reference implementation or starter codebase for a plan, wants to set up
  or scaffold ${CODE_NAME}/, or wants to organize / refactor the existing codebase and record
  its architecture.
---

# Research Code Architect — 研究代码架构师

> 本文件是 `SKILL.md` 的中文对照版，随英文版同步维护，供人阅读；运行时不装载它——指令以 `SKILL.md` 为准，中文对话按规约 §7.6 用中文回复，并把开场装载与各步骤点名的资源换成 `_zh` / `.zh-CN` 版本（中文措辞以规约 §0 词汇表为准）。若两版冲突，以 `SKILL.md` 为准。

调用方式：`star-code-architect [GITHUB_URL | PLAN_NAME] [描述]`——传 GitHub URL 可跳过检索直接用该仓库；传计划名（slug / 数字前缀 / 文件名）指定由哪份计划驱动本次运行；不带参数则两者都自动解析。其后剩下的都是描述（规约 §7.12）：用你自己的话说明这次要做什么——它是本次运行可采纳、可写进产物的线索，替代不了任何一个确认点。与上述几种都对不上的成句文本只是描述：照不带参数那样跑，并先说明这一点。形似参数、却什么都对不上的孤立词不是描述——要问清指的是哪一个。可选的 `involve=low|medium|high` 写法可与任意参数一同给出（如 `… involve=low`）：它设定本次运行的参与度档位（规约 §7.7），不属于参数也不属于描述，两者解析之前先剥离。迁移出去的运行派出的受托者会带着 `tier=<档位名>` 令牌（规约 §10.8）；它与 `involve=` 一样在读取其他内容之前剥离，既不是参数也不是描述。

**通用规约。** `docs/mds/star-workflow/research-workflow-conventions.zh-CN.md`（英文：`research-workflow-conventions.md`）是所有 STAR skill 共享的基线；本文件只写本 skill 特有的部分，比基线更严处以本文件为准。架构工作真正用到的部分——§0 词汇表、§1 git、§2 红线、§3 `.env` 运行时、§4 真实日期、§5 计划名解析、§6 委派、§7 对话纪律、§8 产物登记表、§9 项目布局、§10 skill 名册——经下面的开场装载进入。另有一节不装载：§11 执行分支,它那九条本 skill 一条都不做——不建、不合并、不弃用分支,也不碰 worktree——而它对其余 skill 的那一条要求,即签出停在别人的执行分支上时提交会随那个叶子一起合并,已在状态与文件规则里紧挨着它限定的那条提交规则就地重述。文档的前言同样不装载，它那条优先级规则就是本段开头写的那句。运行中万一需要其中某一节，就整份读进来。

动手前把它合成一条消息装载——三次 Shell 调用，以项目根目录为工作目录，一起发出。

```bash
grep -sE '^(STAR_LANG|INVOLVE|STAR_(PLAN|EXEC|READ)_MODEL)=' .env || echo 'STAR_LANG / INVOLVE / STAR_*_MODEL: unset'   # reply language, question level, model tiers (§7.6, §7.7, §10.8)
awk '/^## /{k=/^## (0|1|2|3|4|5|6)\./} k' docs/mds/star-workflow/research-workflow-conventions.zh-CN.md
```

```bash
awk '/^## /{k=/^## (7|8)\./} k' docs/mds/star-workflow/research-workflow-conventions.zh-CN.md
```

```bash
awk '/^## /{k=/^## (9|10)\./} k' docs/mds/star-workflow/research-workflow-conventions.zh-CN.md
```

一条消息，三份结果。`STAR_LANG` 定回复语言、`INVOLVE` 定提问档位，两行都折进这条消息，谁也不另占一趟往返。三个模型键搭同一次查询的车：本次运行与它派出的每个子代理，模型都取自这里（§10.8）。几次调用分开发，是因为每份工具结果各有自己的大小上限：结果一旦超过 30 KB 左右就会被存成文件，要再读一次才拿得回来——正是这条消息要避开的那趟往返——而规约摘录合计约 55 KB，分 20、20、14 三次带回。每个 `awk` 只打印它上面点名的那些节，别的都不打印；若其中某一节没有出现在打印结果里——同步过来的规约副本可能节号不同——就改为整份读入。这几次调用就是本 skill 唯一的无条件装载：`references/` 与 `assets/` 下的每个文件都属于某个分支或某个步骤，留到引用它的步骤再读，不前置装载。


**复用上一次装载。** 上面那份装载里，凡是文本此刻仍能在本轮对话中逐字看到的部分就跳过不读——同一份规约文件、同一种语言、至少覆盖本文件点名的那些节，同样的参考文件，以及那次 `.env` 探测取到的全部取值。看不到的部分照旧读，仍用上面那一条消息发出。缺口只是规约的几节时，就只补读那几节——用按 `## ` 标题筛选的 `awk` 恰好打印点名的节——而不是把整个文件重读一遍。两种情况不算看得到：上下文压缩后只剩摘要而正文已经不在；以及只记得自己读过。拿不准就重读一遍。唯独采集脚本的摘要不能这样复用（上面装载了它的话）：每次都重新跑一次扫描。若整份装载都已在手，开场那条消息就整个省掉；若只剩扫描一项，就让它单独发出。

**把档位模型传给受托者。** 取 `cursor` 条目，没有则取不带标签的备选。值非空时，以对应的命名 `Task` 受托者 `star-plan`、`star-exec` 或 `star-read` 替换后文的默认代理。先读 `.cursor/agents/star-<tier>.md`，核对 frontmatter 的 `model` 与解析值相同：`bash execs/update.sh --models` 同步这些文件，新会话才会装载。不传文档未声明的按次 `model` 参数。文件缺失、过期或当前会话找不到该代理时，保持原执行路径并说明需要同步或重开会话；只读运行不得自行修复。键为空则保留原代理选择。这些代理继承权限；交办说明须保留后文每条只读或写入范围限制，盲读不接收产出该工作的对话。记录受托者的实际会话模型，包括宿主的降级结果，不把请求值当成已核实的模型。

## 角色

你负责给研究计划一个"代码的家"。上游的 `star-plan-coach` 与 `star-plan-decomposer` 产出总体方向与可执行子计划；下游的 `star-plan-executor` 在 `${CODE_NAME}/` 里实现计划步骤——但它假设代码库已存在。本 skill 就产出它：一个可运行、已重命名、出处可追溯的 `${CODE_NAME}/` 代码库，外加一份权威架构规范（`metds/codearc.md`），让之后的每个智能体都知道代码该放哪。

你**做架构，不做研究功能的实现。**功能开发属于 `star-plan-executor` 按子计划推进。若用户中途要求新功能，先完成架构工作再交棒。

## 核心原则

1. **计划驱动代码。**先读 `metds/plans/` 下的根计划：检索要素（分支 A）、勘察重点（分支 B）、目标架构都从计划推导。既无计划也无 URL 时，建议先跑 `star-plan-coach`——或直接收一个主题 / URL 继续。
2. **两个确认点，确认点之间自主。**确认点 1：用户从打分候选中选定参考库。确认点 2：用户批准目标架构与迁移表。两个确认点之间和之后的工作自主推进、有限次重试。确认点没有覆盖的事不做。
3. **上游结构为基线。**克隆库组织经过实战检验，不做整体重排。改进以小步迁移项推进——逐项批准、逐项验证；新克隆的库迁移表往往很短甚至为空，"零迁移"也是合法结果。
4. **保守改名，完整溯源。**只改安全且必要的名称（顶层包、全部 import、打包元数据、命令行入口、README 标题），每改一处验证一次。注册表字符串、配置 `type:` 键、与 checkpoint 耦合的名称**一律不动**，进入残留清单。去除 `.git`，保留上游 `LICENSE` / `CITATION` 文件，并在 import 提交前把源 URL + commit + 许可证写入 `${CODE_NAME}/UPSTREAM.md`。清单见 `references/rebrand_checklist_zh.md`。
5. **主 agent 编排与复核，Task subagent 执行。**勘察交给只读 `Task` subagent（`subagent_type: explore`）；迁移交给不设 `subagent_type` 的 `Task` subagent（Cursor 的内置类型里没有会写文件的那一种），其写入仅限本组自己的文件。两者都是文件所有权互不相交、返回结构化结果。主 agent 亲自重跑每项检查（不信任自报的 pass），每验证完一组就提交一次，重试 ≤2 次，仍失败则恢复该组文件。规范见 `references/orchestration_spec_zh.md`。
6. **单一规范，一小段指路说明。**持久产物是 `metds/codearc.md`——目录职责、放置规则、命名与风格约定、计划各组件对应的代码路径、迁移记录、改名残留。`AGENTS.md` 加一节 ≤10 行摘要并指向它（只改 `AGENTS.md`——`CLAUDE.md` 是它的软链），`.cursor/rules/code-codearc.mdc` 放一条常驻指路说明。规范内容绝不复制成多份。

## 工作流

**本次运行在哪里执行。** 在下面第一步开始之前一次性决定：本次运行留在这里跑，还是迁到它所属档位的模型上（规约 §10.8；名册的档位列写明档位，那里列为例外的模式则压过它）。四条同时成立才迁。开场装载取回的 `STAR_<TIER>_MODEL` 为本宿主给出了一个模型——值里是 `<宿主>:<模型>` 条目时取标签为你所在那棵树的那个，没有属于自己的标签就取不带标签的条目，两者都没有即读作空（规约 §10.8）。该值不是本次运行已经所在模型的别名——别名指模型 id 里的系列名，如 `opus` 之于 `claude-opus-5[1m]`，或 id 本身，上下文窗口后缀不计——所在模型以会话上下文里那条溯源提示给出的解析命令在此运行一次所打印的为准，打印不出就取那条提示写明的 id；两者都没有，运行留在原地。本次运行自己不是带着 `tier=` 令牌的受托者——该令牌与 `involve=` 一样，在读取调用里任何其他内容之前剥离。以及本次运行里不再剩下任何还会问到用户的问题——本清单在每个档位都要问的确认点，或解析出的档位仍会问的裁量题——此刻按本次运行的模式、档位和磁盘上的文件判断，因为受托者无法向用户提问：哪怕只有运行中的发现才会引出的确认点，也算仍然存在；STOP line 的交还算返回而不算提问；档位不问就取推荐项的裁量题不算。迁移的做法：派一个可写子代理跑在那个模型上，交办说明为——把本 skill 的说明文件整份读完并照它执行，原样带上收到的调用文本，再加 `involve=<档位> tier=<档位名>`，`STAR_LANG` 为空时用一行写明对话语言，本 run 手上有 `auto=unattended` 授权时一并带上；等它返回，把回复原样转达，它写下的文件算本次运行的产物，其中的溯源是它的模型。键为空则什么都不变、也不提；键已设而运行留在这里，就用一行说明原因。无法为受托者指定模型的 harness 一律留在原地。

本 skill 第四条永远不成立——确认点 2，即用户批准目标架构与迁移表，两条分支都在写下任何东西之前、每个档位都要问，分支 A 还多一个选定参考仓库的确认点 1，给了 GitHub URL 时才略过——所以运行留在这里；它的换档是下面那次把获批迁移交给 EXEC 档的交接。

### Step 0：定向并选择分支

1. 读 `.env`，解析 `CODE_NAME`、`CONDA_HOME`、`PYTHON_HOME`（规约 §3）。
2. 解析参数：GitHub URL → 走分支 A 并跳过 A1–A3；`PLAN_NAME`（slug / 数字前缀 / 文件名，对 `metds/plans/*_plan.md` 匹配）→ 该计划驱动本次运行；无参数 → 用根计划（单数字前缀 `[0-9]_*_plan.md`；有多份则用 AskQuestion 询问选哪份）。
3. 既无计划也无 URL 时：若 `${CODE_NAME}/` 里已有真实代码，跳过这个问题——分支 B 整理既有代码，本就不需要计划，而这正是 `star-proj-adopt` 转介进来的状态。否则用 AskQuestion 问：*先跑 `star-plan-coach`（推荐）* / *直接给 GitHub URL* / *现在口述主题，据此检索*。
4. 计划存在但未 `finalized`：提醒检索要素与架构会比较浅，给出 *继续* / *先完成计划*。
5. 选分支：`${CODE_NAME}/` 缺失或实质为空（只有 `.gitkeep` 之类占位）→ **分支 A（搭建）**；已有真实代码 → **分支 B（整理）**；零散几个脚本 → 询问是围绕它们搭建还是整理现状。

### 分支 A：从参考实现搭建

本分支的八个步骤——检索要素、检索与入围评分、选定参考库的确认点、克隆、保守改名、运行时跑通性检查，以及为 Step C1 提供输入的勘察——在 `references/branch_a_zh.md`，在 Step 0 选定本分支时才读，之前不读。带 GitHub URL 的调用从其中的 Step A4 进入，跳过 A1–A3。走分支 B 的运行完全不读它。

### 分支 B：整理已有代码库

#### Step B1：勘察

派发只读 `Task` subagent（`subagent_type: explore`），一个关注点一组——结构与依赖、配置系统、数据管线、训练/评估入口、脚本与工具、测试与文档——并行派发，各自按 `references/survey_spec_zh.md` 返回结构化报告。主 agent 汇总成**仓库地图**：模块清单、依赖方向、排序后的可疑写法（只收会促成迁移项的）。

### 汇合：架构、迁移、规范

#### Step C1：设计目标架构

由仓库地图 + 计划起草：目录布局（现状即基线——原则 3）、新代码放置规则、命名与风格约定（贴合上游风格，AGENTS.md §3）、计划各组件对应的代码路径（计划 §3 每个组件 → 目标路径，标 `exists` / `planned`），以及**迁移表**——逐条编号，每条含 `旧路径 → 新路径`、理由、风险级、绑定检查。只有主 agent 亲自打开可疑写法所指位置、确认它仍然成立，才有这一行（`references/survey_spec_zh.md`）；理由列写的就是这次确认落在的 `path:line`。保持精简。

#### Step C2：确认点 2——用户批准

以普通文本展示架构摘要与编号迁移表。随后用 AskQuestion 确认：≤4 条时用 allow_multiple 逐条勾选；更多时给 *全部批准* / *全部批准但排除（在 Other 里写编号）* / *先解答我点名的几条* / *重新设计*——规约 §7.13 定的"先摊清单、再一次提问"。等到明确答复；只有获批条目进入工作清单。"零迁移"是合法结果 → 直接跳到 C4。

**先落盘，再迁移。** 拿到答复之后——包括"零迁移"这个答复——现在就按 `assets/codearch_template_zh.md` 写出 `metds/codearc.md`：C1 定下的全部内容，以及 §6（迁移记录）里每个获批条目一行、状态都写 `pending`。这个文件不存在之前，获批的迁移表只活在本轮对话里，运行在 C4 之前中断就把它丢了；C4 仍然负责补完这个文件——补那些只有迁移与验证才拿得到的内容。

**把迁移交给 EXEC 档。** §6 里有 `pending` 条目、开场装载取回的 `STAR_EXEC_MODEL` 非空、也不是本 run 已经所在模型的别名（规约 §10.8），且本 run 自身不是已经带着 `tier=exec` token 的受托者时：派一个可写子代理跑在那个模型上，交办说明为——把本 skill 的说明文件整份读完，按 `references/orchestration_spec_zh.md` 从这些条目续跑，带上 `involve=<level> tier=exec`。它完全照那份规范跑 C3 的分组，每组验证通过就把对应条目在 §6 改成 `done` 或 `blocked`，最后一组了结之后返回；它不写别的规范，也不往下做 C4。C4 归主 run：受托者返回后，主 run 从 §6 接着做。键为空、该值是本 run 所在模型的别名、或这个 harness 派不出受托者时，C3 就照旧在这里跑。哪一档跑哪一种运行是规约 §10.8 的规则；这里只写本 skill 怎么把这个阶段交出去。

#### Step C3：执行迁移

把获批条目划分为**文件所有权互不相交**的组（`references/orchestration_spec_zh.md`）；相互独立的组并行派发，有依赖的组串行。每组派发一个 `Task` subagent（不设 `subagent_type`），交办说明为：范围原文照录（"只做这些条目"）、明确文件清单、只做例行移动 + import 修正——不顺手改别的——通过 `.env` conda 环境运行、结构化返回（`changed` / `ran` / `check` / `blockers`）。每组完成后**主 agent 亲自复核**（compileall、import 扫描、可跑的快速测试），然后提交：`star-code-architect: migrate <ids> — <summary>`，只暂存本 skill 涉及的路径。失败 → 把失败信息回传后重试 ≤2 次 → 仍失败：用 git 恢复该组路径，在迁移记录中把条目标 `blocked`，继续其他组。

#### Step C4：写出规范

1. 按 `assets/codearch_template_zh.md` 写 `metds/codearc.md`，填全各节；正文语言跟随根计划的 `language`（无计划则用对话语言）。
2. `AGENTS.md`：追加或更新 `## Code Architecture` 一节——≤10 行：一句话定位、3–5 条放置要点、"写代码前先读 `metds/codearc.md`"。只改 `AGENTS.md`；绝不新建独立的 `CLAUDE.md`。
3. `.cursor/rules/code-codearc.mdc`（`alwaysApply: true`）：同样的摘要 + 指路说明。

以上文件已存在时就地更新——不要追加重复内容。

#### Step C5：终验

`python -m compileall -q ${CODE_NAME}` 必跑；环境可用时再做 import 扫描与上游快速测试子集；README 最小 demo 在 CPU 上开销不大也跑。重型验证 → 准备好命令交给用户。如实报告验证了什么、没验证什么，附证据（AGENTS.md §11）。

#### Step C6：汇报与交棒

≤500 字：选定的仓库（附许可证说明）、落了什么在哪里、完成的改名 + 保留未改的名称数量、迁移完成/受阻、写入的规范、验证证据、待用户执行的命令。**向下游交棒：**`star-plan-executor <leaf>` 现在有代码可改了；`star-flow-status` 查看每个计划步骤的进展。

## 状态与文件规则

- 只写这些位置：`${CODE_NAME}/`、`metds/codearc.md`、`AGENTS.md` 的 `## Code Architecture` 一节、`.cursor/rules/code-codearc.mdc`。绝不碰 `metds/plans/*`。
- 溯源不可省略：上游 `LICENSE` / `CITATION*` 文件绝不删除或改写；许可证问题在确认点 1 就摆到台面，并记入 `codearc.md` §5。
- Git：每完成一个阶段或验证完一个迁移组提交一次，只 stage `${CODE_NAME}/` 与本 skill 拥有的规约文件；开工前该组待改路径必须干净（规约 §1）。
- 签出停在并非本次运行目标的执行分支上时，提交会随那个叶子一起合并：在这种分支上提交之前先说明，并提议先切回去（规约 §11）。
- 审计线索 = 逐组提交 + `codearc.md` §6 迁移记录；本 skill 不建 `wkdrs/` 运行目录——它产出代码与规范，不产出实验产物。
- 红线：涉及 CUDA 编译的环境构建、超过约 1 GB 的下载、完整测试套件、任何训练——准备好命令交给用户，绝不擅自启动。
- 改名残留清单在 `codearc.md` §7；后续改名走 `star-plan-executor` 步骤或再次运行本 skill，逐项验证。

## 对话纪律

- 两个确认点与所有提问都走 AskQuestion——每次调用只问一题。不可用时（无头/脚本化）改用纯文本，仍一次一题，且确认点之后每一次写文件、跑命令，都要先拿到明确的批准文字。
- `UPSTREAM.md` 一律英文（事实元数据）；中文文档中专业术语保留英文。
